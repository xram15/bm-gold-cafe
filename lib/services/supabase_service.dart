import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/book_model.dart';
import '../data/models/page_model.dart';
import '../data/models/category_model.dart';
import '../data/models/product_model.dart';
import '../data/menus/bm_menu.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  // ===========================================================================
  // 🔑 IDENTIFIANTS SUPABASE CAFFE-BM
  // ===========================================================================
  static const String supabaseUrl = 'https://kntybigswxfmitrumskw.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_Iua3ckvxQQVEJZob97yXSw_jQdhmpw-';

  bool _isConfigured = false;
  bool get isConfigured => _isConfigured;
  StreamSubscription<List<Map<String, dynamic>>>? _menuSubscription;
  Timer? _menuRefreshTimer;

  // Notifier pour mettre à jour le livre en direct partout dans l'application
  final ValueNotifier<Book> currentBookNotifier = ValueNotifier<Book>(bmMenu);

  Book get currentBook => currentBookNotifier.value;

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  // 100% RÉEL : L'utilisateur est connecté UNIQUEMENT si Supabase a une session active
  bool get isAuthenticated => _client?.auth.currentSession != null;
  bool get isAdminLoggedIn => isAuthenticated;

  Future<void> signInAdmin(String email, String password) => signInWithEmail(email, password);
  Future<void> signOutAdmin() => signOut();

  String? get currentAdminEmail => _client?.auth.currentUser?.email;

  static const String _kLocalMenuStorageKey = 'bm_gold_saved_menu_v1';

  /// Initialisation Supabase
  Future<void> init() async {
    // 1. Charger immédiatement le menu sauvegardé localement pour un rendu instantané
    await loadMenuFromLocalStorage();

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: supabaseAnonKey,
      );
      _isConfigured = true;
      debugPrint('[Supabase] Initialisé avec succès sur $supabaseUrl');

      // Charger le menu dynamique
      await fetchMenu();
      await fetchPagePhotos();

      // Écouter les changements en temps réel
      _subscribeToRealtimeChanges();
    } catch (e) {
      debugPrint('[Supabase] Erreur initialisation: $e');
      _isConfigured = false;
    }
  }

  // ===========================================================================
  // 🔐 AUTHENTIFICATION 100% RÉELLE SUPABASE (SANS AUCUNE SIMULATION)
  // ===========================================================================

  /// Connexion 100% réelle avec Supabase Auth
  Future<void> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (_client == null || !_isConfigured) {
      throw Exception('Impossible de contacter le serveur Supabase. Vérifiez votre connexion.');
    }

    try {
      final res = await _client!.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPassword,
      );

      if (res.session == null) {
        throw Exception('Identifiants incorrects ou utilisateur non autorisé dans la base de données.');
      }
    } on AuthException catch (e) {
      debugPrint('[Supabase Auth Error] ${e.message}');
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw Exception('Email ou mot de passe incorrect. Vérifiez les identifiants créés dans Supabase.');
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
        throw Exception('Email non confirmé dans Supabase. Cochez "Auto Confirm User" dans le Dashboard.');
      }
      throw Exception(e.message);
    } catch (e) {
      debugPrint('[Supabase Auth Error] $e');
      rethrow;
    }
  }

  /// Connexion avec Google OAuth réelle via Supabase
  Future<void> signInWithGoogle() async {
    if (_client == null || !_isConfigured) {
      throw Exception('Supabase n\'est pas disponible.');
    }
    await _client!.auth.signInWithOAuth(OAuthProvider.google);
  }

  /// Déconnexion réelle
  Future<void> signOut() async {
    if (_client != null) {
      try {
        await _client!.auth.signOut();
      } catch (e) {
        debugPrint('[Supabase SignOut] $e');
      }
    }
  }

  // ===========================================================================
  // 👥 GESTION DES ADMINISTRATEURS (MOT DE PASSE, CRÉATION, SUPPRESSION)
  // ===========================================================================

  /// 🔑 Changer son propre mot de passe
  Future<void> changePassword(String newPassword) async {
    if (_client == null || !_isConfigured) {
      throw Exception('Supabase n\'est pas initialisé.');
    }
    try {
      await _client!.auth.updateUser(UserAttributes(password: newPassword.trim()));
      debugPrint('[Supabase] Mot de passe mis à jour avec succès.');
    } catch (e) {
      debugPrint('[Supabase] Erreur mise à jour mot de passe: $e');
      rethrow;
    }
  }

  /// ➕ Ajouter un nouvel administrateur
  Future<void> createAdminUser({required String email, required String password}) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    if (_client == null || !_isConfigured) {
      throw Exception('Supabase n\'est pas disponible.');
    }

    try {
      await _client!.auth.signUp(
        email: cleanEmail,
        password: cleanPassword,
      );

      try {
        await _client!.from('admins').insert({
          'email': cleanEmail,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      debugPrint('[Supabase] Nouvel admin $cleanEmail créé avec succès.');
    } catch (e) {
      debugPrint('[Supabase] Erreur création admin: $e');
      rethrow;
    }
  }

  /// 🗑️ Supprimer / révoquer un administrateur
  Future<void> deleteAdminUser(String email) async {
    if (_client == null || !_isConfigured) return;
    try {
      await _client!.from('admins').delete().eq('email', email.trim());
      debugPrint('[Supabase] Admin $email retiré.');
    } catch (e) {
      debugPrint('[Supabase] Erreur suppression admin: $e');
    }
  }

  /// Récupérer la liste des administrateurs
  Future<List<String>> fetchAdmins() async {
    final List<String> admins = [];
    final current = currentAdminEmail;
    if (current != null && current.isNotEmpty) {
      admins.add(current);
    }

    if (_client != null && _isConfigured) {
      try {
        final res = await _client!.from('admins').select('email').order('created_at', ascending: true);
        for (final row in res as List<dynamic>) {
          final em = (row['email'] as String?)?.trim();
          if (em != null && em.isNotEmpty && !admins.contains(em)) {
            admins.add(em);
          }
        }
      } catch (_) {}
    }

    return admins;
  }

  // ===========================================================================
  // 📖 GESTION PAR PAGE (PRODUITS & PRIX)
  // ===========================================================================

  /// ➕ Ajouter un produit à une PAGE PRÉCISE
  Future<void> addProductToPage({
    required int pageIndex,
    required String name,
    required String price,
    String? description,
    String? imagePath,
    String? section,
  }) async {
    if (pageIndex < 0 || pageIndex >= currentBook.pages.length) return;

    final targetPage = currentBook.pages[pageIndex];
    final categoryTitle = targetPage.category?.title ?? 'PAGE ${pageIndex + 1}';
    final localId = 'prod_${DateTime.now().millisecondsSinceEpoch}';

    final newProduct = Product(
      id: localId,
      name: name.trim(),
      price: price.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      imagePath: imagePath?.trim().isEmpty == true ? null : imagePath?.trim(),
      section: section?.trim().isEmpty == true ? null : section?.trim(),
    );

    // 1. Mise à jour instantanée de la page exacte
    final List<Product> updatedProducts = List.from(targetPage.category?.products ?? <Product>[])..add(newProduct);
    final updatedPage = targetPage.copyWith(
      category: MenuCategory(title: categoryTitle, products: updatedProducts),
    );

    final List<BookPage> updatedPages = List.from(currentBook.pages);
    updatedPages[pageIndex] = updatedPage;
    _updateBook(updatedPages);

    // 2. Synchronisation Supabase si connecté
    if (_isConfigured && _client != null) {
      try {
        await _client!.from('products').insert({
          'category_name': categoryTitle,
          'name': newProduct.name,
          'price': newProduct.price,
          'description': newProduct.toJson()['description'],
          'image_path': newProduct.imagePath,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint('[Supabase] Erreur addProduct (sauvegardé en mémoire): $e');
      }
    }
  }

  /// ✏️ Modifier un produit sur une PAGE PRÉCISE
  Future<void> updateProductOnPage({
    required int pageIndex,
    required String productId,
    required String name,
    required String price,
    String? description,
    String? imagePath,
    String? section,
  }) async {
    if (pageIndex < 0 || pageIndex >= currentBook.pages.length) return;

    final targetPage = currentBook.pages[pageIndex];
    final categoryTitle = targetPage.category?.title ?? 'PAGE ${pageIndex + 1}';

    final updatedProduct = Product(
      id: productId,
      name: name.trim(),
      price: price.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      imagePath: imagePath?.trim().isEmpty == true ? null : imagePath?.trim(),
      section: section?.trim().isEmpty == true ? null : section?.trim(),
    );

    final List<Product> updatedProducts = [];
    for (final p in targetPage.category?.products ?? <Product>[]) {
      if (p.id == productId || p.name == productId || p.name == name) {
        updatedProducts.add(updatedProduct);
      } else {
        updatedProducts.add(p);
      }
    }

    final updatedPage = targetPage.copyWith(
      category: MenuCategory(title: categoryTitle, products: updatedProducts),
    );

    final List<BookPage> updatedPages = List.from(currentBook.pages);
    updatedPages[pageIndex] = updatedPage;
    _updateBook(updatedPages);

    // Synchronisation Supabase
    if (_isConfigured && _client != null) {
      try {
        await _client!.from('products').update({
          'name': updatedProduct.name,
          'price': updatedProduct.price,
          'description': updatedProduct.toJson()['description'],
          'image_path': updatedProduct.imagePath,
          'updated_at': DateTime.now().toIso8601String(),
        }).or('id.eq.$productId,name.eq.$productId');
      } catch (e) {
        debugPrint('[Supabase] Erreur updateProduct: $e');
      }
    }
  }

  /// 🗑️ Supprimer un produit d'une PAGE PRÉCISE
  Future<void> deleteProductFromPage({
    required int pageIndex,
    required String productId,
  }) async {
    if (pageIndex < 0 || pageIndex >= currentBook.pages.length) return;

    final targetPage = currentBook.pages[pageIndex];
    final categoryTitle = targetPage.category?.title ?? 'PAGE ${pageIndex + 1}';

    final List<Product> updatedProducts = (targetPage.category?.products ?? <Product>[])
        .where((p) => p.id != productId && p.name != productId)
        .toList();

    final updatedPage = targetPage.copyWith(
      category: MenuCategory(title: categoryTitle, products: updatedProducts),
    );

    final List<BookPage> updatedPages = List.from(currentBook.pages);
    updatedPages[pageIndex] = updatedPage;
    _updateBook(updatedPages);

    // Synchronisation Supabase
    if (_isConfigured && _client != null) {
      try {
        await _client!.from('products').delete().or('id.eq.$productId,name.eq.$productId');
      } catch (e) {
        debugPrint('[Supabase] Erreur deleteProduct: $e');
      }
    }
  }

  /// 💰 Changement rapide de prix
  Future<void> updateProductPrice({
    required String productId,
    required String newPrice,
  }) async {
    final List<BookPage> updatedPages = [];

    for (final page in currentBook.pages) {
      final List<Product> updatedProducts = [];
      for (final prod in page.category?.products ?? <Product>[]) {
        if (prod.id == productId || prod.name == productId) {
          updatedProducts.add(prod.copyWith(price: newPrice.trim()));
        } else {
          updatedProducts.add(prod);
        }
      }
      updatedPages.add(page.copyWith(
        category: MenuCategory(title: page.category?.title ?? '', products: updatedProducts),
      ));
    }

    _updateBook(updatedPages);

    if (_isConfigured && _client != null) {
      try {
        await _client!.from('products').update({
          'price': newPrice.trim(),
          'updated_at': DateTime.now().toIso8601String(),
        }).or('id.eq.$productId,name.eq.$productId');
      } catch (e) {
        debugPrint('[Supabase] Erreur updateProductPrice: $e');
      }
    }
  }

  // ===========================================================================
  // 🖼️ GESTION PAR PAGE (PHOTOS DU LIVRE)
  // ===========================================================================

  /// Modifier les photos d'une page spécifique
  Future<void> updatePagePhotos(
    int pageIndex, {
    String? cornerPhotoPath,
    String? largeBottomPhotoPath,
    String? largeBottomPhotoTitle,
    String? firstAlternatingPhotoPath,
    String? firstAlternatingPhotoTitle,
    String? secondAlternatingPhotoPath,
    String? secondAlternatingPhotoTitle,
    String? secondBottomPhotoPath,
    String? secondBottomPhotoTitle,
    List<BottomPhoto>? bottomPhotos,
  }) async {
    if (pageIndex < 0 || pageIndex >= currentBook.pages.length) return;

    final targetPage = currentBook.pages[pageIndex];
    final updatedPage = targetPage.copyWith(
      cornerPhotoPath: cornerPhotoPath ?? targetPage.cornerPhotoPath,
      largeBottomPhotoPath: largeBottomPhotoPath ?? targetPage.largeBottomPhotoPath,
      largeBottomPhotoTitle: largeBottomPhotoTitle ?? targetPage.largeBottomPhotoTitle,
      firstAlternatingPhotoPath: firstAlternatingPhotoPath ?? targetPage.firstAlternatingPhotoPath,
      firstAlternatingPhotoTitle: firstAlternatingPhotoTitle ?? targetPage.firstAlternatingPhotoTitle,
      secondAlternatingPhotoPath: secondAlternatingPhotoPath ?? targetPage.secondAlternatingPhotoPath,
      secondAlternatingPhotoTitle: secondAlternatingPhotoTitle ?? targetPage.secondAlternatingPhotoTitle,
      secondBottomPhotoPath: secondBottomPhotoPath ?? targetPage.secondBottomPhotoPath,
      secondBottomPhotoTitle: secondBottomPhotoTitle ?? targetPage.secondBottomPhotoTitle,
      bottomPhotos: bottomPhotos ?? targetPage.bottomPhotos,
    );

    final List<BookPage> updatedPages = List.from(currentBook.pages);
    updatedPages[pageIndex] = updatedPage;
    _updateBook(updatedPages);

    // Sauvegarde locale instantanée
    saveMenuToLocalStorage();

    // Synchronisation Cloud immédiate pour les photos de cette page
    _syncPagePhotosToCloud(pageIndex, updatedPage);
  }

  /// Synchroniser la configuration des photos d'une page sur Supabase (visible par tous les appareils)
  Future<void> _syncPagePhotosToCloud(int pageIndex, BookPage page) async {
    if (!_isConfigured || _client == null) return;
    try {
      final configPayload = {
        'corner_photo': page.cornerPhotoPath,
        'large_bottom_photo': page.largeBottomPhotoPath,
        'large_bottom_title': page.largeBottomPhotoTitle,
        'second_bottom_photo': page.secondBottomPhotoPath,
        'second_bottom_title': page.secondBottomPhotoTitle,
        'first_alternating_photo': page.firstAlternatingPhotoPath,
        'first_alternating_title': page.firstAlternatingPhotoTitle,
        'second_alternating_photo': page.secondAlternatingPhotoPath,
        'second_alternating_title': page.secondAlternatingPhotoTitle,
      };

      final payload = {
        'category_name': '__PAGE_PHOTOS__',
        'name': 'page_$pageIndex',
        'price': '0',
        'description': jsonEncode(configPayload),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final existing = await _client!
          .from('products')
          .select('id')
          .eq('category_name', '__PAGE_PHOTOS__')
          .eq('name', 'page_$pageIndex')
          .maybeSingle();

      if (existing != null) {
        await _client!.from('products').update(payload).eq('id', existing['id']);
      } else {
        await _client!.from('products').insert(payload);
      }
      debugPrint('[Supabase] Photos de la page $pageIndex synchronisées dans le cloud');
    } catch (e) {
      debugPrint('[Supabase] Erreur synchronisation photos page $pageIndex: $e');
    }
  }

  /// Charger les photos des pages enregistrées dans le cloud Supabase
  Future<void> fetchPagePhotos() async {
    if (!_isConfigured || _client == null) return;
    try {
      final response = await _client!
          .from('products')
          .select('name, description')
          .eq('category_name', '__PAGE_PHOTOS__');

      final List<dynamic> rows = response as List<dynamic>;
      if (rows.isEmpty) return;

      final List<BookPage> updatedPages = List.from(currentBook.pages);
      bool hasChanges = false;

      for (final row in rows) {
        final name = row['name'] as String? ?? '';
        final desc = row['description'] as String? ?? '';
        if (!name.startsWith('page_') || desc.isEmpty) continue;

        final pageIdx = int.tryParse(name.replaceFirst('page_', ''));
        if (pageIdx == null || pageIdx < 0 || pageIdx >= updatedPages.length) continue;

        try {
          final Map<String, dynamic> data = jsonDecode(desc) as Map<String, dynamic>;
          final currentPage = updatedPages[pageIdx];

          updatedPages[pageIdx] = currentPage.copyWith(
            cornerPhotoPath: data['corner_photo'] as String? ?? currentPage.cornerPhotoPath,
            largeBottomPhotoPath: data['large_bottom_photo'] as String? ?? currentPage.largeBottomPhotoPath,
            largeBottomPhotoTitle: data['large_bottom_title'] as String? ?? currentPage.largeBottomPhotoTitle,
            secondBottomPhotoPath: data['second_bottom_photo'] as String? ?? currentPage.secondBottomPhotoPath,
            secondBottomPhotoTitle: data['second_bottom_title'] as String? ?? currentPage.secondBottomPhotoTitle,
            firstAlternatingPhotoPath: data['first_alternating_photo'] as String? ?? currentPage.firstAlternatingPhotoPath,
            firstAlternatingPhotoTitle: data['first_alternating_title'] as String? ?? currentPage.firstAlternatingPhotoTitle,
            secondAlternatingPhotoPath: data['second_alternating_photo'] as String? ?? currentPage.secondAlternatingPhotoPath,
            secondAlternatingPhotoTitle: data['second_alternating_title'] as String? ?? currentPage.secondAlternatingPhotoTitle,
          );
          hasChanges = true;
        } catch (_) {}
      }

      if (hasChanges) {
        _updateBook(updatedPages);
        // Met également à jour le cache local avec les photos venues du Cloud
        await saveMenuToLocalStorage();
        debugPrint('[Supabase] Photos du livre synchronisées depuis le cloud (${rows.length} pages configurées).');
      }
    } catch (e) {
      debugPrint('[Supabase] Erreur fetchPagePhotos: $e');
    }
  }

  // ===========================================================================
  // 🔄 RECHARGEMENT & SYNCHRONISATION
  // ===========================================================================

  Future<void> fetchMenu() async {
    if (!_isConfigured || _client == null) return;

    try {
      final response = await _client!
          .from('products')
          .select('id, name, price, description, image_path, category_name')
          .order('id', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      if (data.isEmpty) return;

      final Map<String, List<Product>> grouped = {};
      for (final item in data) {
        final cat = (item['category_name'] as String?)?.trim().toUpperCase() ?? 'AUTRE';
        grouped.putIfAbsent(cat, () => []).add(Product.fromJson(item as Map<String, dynamic>));
      }

      final List<BookPage> updatedPages = [];
      for (final page in currentBook.pages) {
        final String catTitle = (page.category?.title ?? '').trim().toUpperCase();
        final dynamicProducts = grouped[catTitle];

        if (dynamicProducts != null && dynamicProducts.isNotEmpty) {
          updatedPages.add(page.copyWith(
            category: MenuCategory(title: page.category?.title ?? '', products: dynamicProducts),
          ));
        } else {
          updatedPages.add(page);
        }
      }

      _updateBook(updatedPages);
      debugPrint('[Supabase] Synchronisation terminée : ${data.length} produits.');
    } catch (e) {
      debugPrint('[Supabase] fetchMenu fallback : $e');
    }
  }

  void _subscribeToRealtimeChanges() {
    if (!_isConfigured || _client == null || _menuSubscription != null || _menuRefreshTimer != null) return;

    try {
      _menuSubscription = _client!
          .from('products')
          .stream(primaryKey: ['id'])
      _menuSubscription = _client!
          .from('products')
          .stream(primaryKey: ['id'])
          .listen(
            (_) {
              fetchMenu();
              fetchPagePhotos();
            },
            onError: (Object error) {
              debugPrint('[Menu] Mises à jour en direct indisponibles; actualisation périodique activée.');
              unawaited(_menuSubscription?.cancel());
              _menuSubscription = null;
              _startMenuPolling();
            },
            onDone: _startMenuPolling,
          );
    } catch (e) {
      debugPrint('[Menu] Mises à jour en direct indisponibles; actualisation périodique activée.');
      _startMenuPolling();
    }
  }

  void _startMenuPolling() {
    _menuRefreshTimer ??= Timer.periodic(const Duration(seconds: 30), (_) {
      unawaited(fetchMenu());
    });
  }

  void _updateBook(List<BookPage> pages) {
    currentBookNotifier.value = Book(
      id: currentBook.id,
      title: currentBook.title,
      iconEmoji: currentBook.iconEmoji,
      color: currentBook.color,
      imagePath: currentBook.imagePath,
      pages: pages,
    );
    // Sauvegarde locale instantanée à chaque ajout / modification
    saveMenuToLocalStorage();
  }

  /// 💾 Sauvegarder l'état actuel de toutes les pages et produits en stockage local
  Future<void> saveMenuToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> pagesData = [];
      for (final page in currentBook.pages) {
        final productsJson = page.category?.products.map((p) => p.toJson()).toList() ?? [];
        pagesData.add({
          'category_title': page.category?.title ?? '',
          'products': productsJson,
          'corner_photo': page.cornerPhotoPath,
          'large_bottom_photo': page.largeBottomPhotoPath,
          'large_bottom_title': page.largeBottomPhotoTitle,
          'second_bottom_photo': page.secondBottomPhotoPath,
          'second_bottom_title': page.secondBottomPhotoTitle,
          'first_alternating_photo': page.firstAlternatingPhotoPath,
          'first_alternating_title': page.firstAlternatingPhotoTitle,
          'second_alternating_photo': page.secondAlternatingPhotoPath,
          'second_alternating_title': page.secondAlternatingPhotoTitle,
          'bottom_photos': page.bottomPhotos?.map((bp) => {
            'title': bp.title,
            'price': bp.price,
            'imagePath': bp.imagePath,
          }).toList(),
        });
      }
      final jsonString = jsonEncode(pagesData);
      await prefs.setString(_kLocalMenuStorageKey, jsonString);
      debugPrint('[LocalStorage] Menu sauvegardé en cache local');
    } catch (e) {
      debugPrint('[LocalStorage] Erreur lors de la sauvegarde locale: $e');
    }
  }

  /// 📂 Charger le menu sauvegardé localement
  Future<void> loadMenuFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_kLocalMenuStorageKey);
      if (jsonString == null || jsonString.isEmpty) return;

      final dynamic decoded = jsonDecode(jsonString);
      if (decoded is! List) return;

      final List<BookPage> updatedPages = [];
      for (int i = 0; i < bmMenu.pages.length; i++) {
        final defaultPage = bmMenu.pages[i];
        if (i < decoded.length) {
          final pageData = decoded[i] as Map<String, dynamic>;
          final rawProducts = pageData['products'] as List<dynamic>? ?? [];
          final products = rawProducts.map((p) => Product.fromJson(Map<String, dynamic>.from(p as Map))).toList();

          final rawBottomPhotos = pageData['bottom_photos'] as List<dynamic>?;
          List<BottomPhoto>? bottomPhotos;
          if (rawBottomPhotos != null) {
            bottomPhotos = rawBottomPhotos.map((bp) => BottomPhoto(
              title: bp['title'] as String? ?? '',
              price: bp['price'] as String?,
              imagePath: bp['imagePath'] as String? ?? '',
            )).toList();
          }

          updatedPages.add(defaultPage.copyWith(
            category: MenuCategory(
              title: (pageData['category_title'] as String?) ?? defaultPage.category?.title ?? '',
              products: products,
            ),
            cornerPhotoPath: pageData['corner_photo'] as String? ?? defaultPage.cornerPhotoPath,
            largeBottomPhotoPath: pageData['large_bottom_photo'] as String? ?? defaultPage.largeBottomPhotoPath,
            largeBottomPhotoTitle: pageData['large_bottom_title'] as String? ?? defaultPage.largeBottomPhotoTitle,
            secondBottomPhotoPath: pageData['second_bottom_photo'] as String? ?? defaultPage.secondBottomPhotoPath,
            secondBottomPhotoTitle: pageData['second_bottom_title'] as String? ?? defaultPage.secondBottomPhotoTitle,
            firstAlternatingPhotoPath: pageData['first_alternating_photo'] as String? ?? defaultPage.firstAlternatingPhotoPath,
            firstAlternatingPhotoTitle: pageData['first_alternating_title'] as String? ?? defaultPage.firstAlternatingPhotoTitle,
            secondAlternatingPhotoPath: pageData['second_alternating_photo'] as String? ?? defaultPage.secondAlternatingPhotoPath,
            secondAlternatingPhotoTitle: pageData['second_alternating_title'] as String? ?? defaultPage.secondAlternatingPhotoTitle,
            bottomPhotos: bottomPhotos ?? defaultPage.bottomPhotos,
          ));
        } else {
          updatedPages.add(defaultPage);
        }
      }
      currentBookNotifier.value = Book(
        id: currentBook.id,
        title: currentBook.title,
        iconEmoji: currentBook.iconEmoji,
        color: currentBook.color,
        imagePath: currentBook.imagePath,
        pages: updatedPages,
      );
      debugPrint('[LocalStorage] Menu chargé avec succès depuis le stockage local');
    } catch (e) {
      debugPrint('[LocalStorage] Erreur chargement local: $e');
    }
  }

  /// ☁️ Sauvegarde globale : Enregistre localement ET pousse les produits vers Supabase
  Future<bool> saveMenuToCloudAndStorage() async {
    // 1. Sauvegarde locale persistante garantie
    await saveMenuToLocalStorage();

    // 2. Synchronisation Supabase
    if (_isConfigured && _client != null) {
      try {
        for (final page in currentBook.pages) {
          final catTitle = page.category?.title ?? '';
          for (final prod in page.category?.products ?? <Product>[]) {
            final payload = {
              'category_name': catTitle,
              'name': prod.name,
              'price': prod.price,
              'description': prod.toJson()['description'],
              'image_path': prod.imagePath,
              'updated_at': DateTime.now().toIso8601String(),
            };
            try {
              await _client!.from('products').upsert(payload, onConflict: 'category_name,name');
            } catch (inner) {
              // Si la contrainte d'unicité n'est pas encore créée, update ou insert direct
              debugPrint('[Supabase] Tentative fallback: $inner');
              try {
                final existing = await _client!
                    .from('products')
                    .select('id')
                    .eq('category_name', catTitle)
                    .eq('name', prod.name)
                    .maybeSingle();

                if (existing != null) {
                  await _client!.from('products').update(payload).eq('id', existing['id']);
                } else {
                  await _client!.from('products').insert(payload);
                }
              } catch (e2) {
                debugPrint('[Supabase] Erreur fallback insert/update: $e2');
              }
            }
          }
        }
        // 3. Sauvegarder également toutes les configurations photos de toutes les pages dans le cloud
        for (int i = 0; i < currentBook.pages.length; i++) {
          await _syncPagePhotosToCloud(i, currentBook.pages[i]);
        }

        return true;
      } catch (e) {
        debugPrint('[Supabase] Erreur synchronisation cloud: $e');
        return false;
      }
    }
    return false;
  }
}
