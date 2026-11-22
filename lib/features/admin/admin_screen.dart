import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_html/html.dart' as html;
import '../../core/app_colors.dart';
import '../../data/models/page_model.dart';
import '../../data/models/product_model.dart';
import '../../services/supabase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  static Future<void> open(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminScreen()),
    );
  }

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _service = SupabaseService.instance;

  // Authentification
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isAuthLoading = false;
  String? _authErrorMessage;
  bool _rememberMe = false;

  // Navigation dans le Dashboard
  int _currentZoneIndex = 0; // 0 = Produits & Prix, 1 = Photos du Livre
  int _selectedPageIndex = 0; // Index de la page active (0 à N-1)
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rem = prefs.getBool('bm_remember_me') ?? false;
      if (rem) {
        final savedEmail = prefs.getString('bm_saved_email');
        final savedPassword = prefs.getString('bm_saved_password');
        if (savedEmail != null && savedEmail.isNotEmpty) {
          setState(() {
            _rememberMe = true;
            _emailController.text = savedEmail;
            _passwordController.text = savedPassword ?? '';
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // ACTIONS D'AUTHENTIFICATION
  // ===========================================================================

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _authErrorMessage = 'Veuillez saisir votre email et mot de passe.');
      return;
    }

    setState(() {
      _isAuthLoading = true;
      _authErrorMessage = null;
    });

    try {
      await _service.signInWithEmail(email, password);

      // Sauvegarde des identifiants si "Rester connecté" est coché
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_rememberMe) {
          await prefs.setBool('bm_remember_me', true);
          await prefs.setString('bm_saved_email', email);
          await prefs.setString('bm_saved_password', password);
        } else {
          await prefs.setBool('bm_remember_me', false);
          await prefs.remove('bm_saved_email');
          await prefs.remove('bm_saved_password');
        }
      } catch (_) {}

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        setState(() {
          _authErrorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) setState(() => _isAuthLoading = false);
    }
  }

  Future<void> _handleManualSave() async {
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final cloudSuccess = await _service.saveMenuToCloudAndStorage();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                cloudSuccess ? Icons.cloud_done_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cloudSuccess
                      ? 'Menu enregistré et synchronisé dans le cloud !'
                      : 'Menu enregistré localement avec succès !',
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: cloudSuccess ? const Color(0xFF2E7D32) : const Color(0xFF1B5E20),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D10),
      body: _service.isAuthenticated
          ? SafeArea(child: _buildDashboardView())
          : _buildLoginView(),
    );
  }

  // ===========================================================================
  // 1. ÉCRAN DE CONNEXION SÉCURISÉ (EFFET GLASSERIE & FOND BACKGROUND.JFIF)
  // ===========================================================================

  Widget _buildLoginView() {
    return Stack(
      children: [
        // A. Image de fond pleine page
        Positioned.fill(
          child: Image.asset(
            'assets/background.jfif',
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(color: const Color(0xFF0D0D10)),
          ),
        ),

        // B. Filtre sombre et léger flou d'ambiance sur le fond
        Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.65),
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: const SizedBox.expand(),
          ),
        ),

        // C. Cadre de connexion Glassmorphism
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 390),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Emblème doré de sécurité (Pas de titre BM Gold Espace Gérant)
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.gold, width: 2),
                          gradient: const RadialGradient(
                            colors: [Color(0xFF2E2416), Color(0xFF141418)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withValues(alpha: 0.35),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          color: AppColors.gold,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Champ Email
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: AppColors.goldLight, fontSize: 13),
                          prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gold, size: 20),
                          filled: true,
                          fillColor: const Color(0xFF1D1D24).withValues(alpha: 0.7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Champ Mot de passe
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onSubmitted: (_) => _handleEmailAuth(),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Mot de passe',
                          labelStyle: const TextStyle(color: AppColors.goldLight, fontSize: 13),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.gold, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1D1D24).withValues(alpha: 0.7),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                          ),
                        ),
                      ),

                      if (_authErrorMessage != null) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _authErrorMessage!,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // Bouton Rester connecté
                      Row(
                        children: [
                          Theme(
                            data: ThemeData(unselectedWidgetColor: AppColors.goldLight),
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.gold,
                              checkColor: Colors.black,
                              onChanged: (val) => setState(() => _rememberMe = val ?? false),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: const Text(
                              'Rester connecté',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Bouton Se Connecter
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 4,
                          ),
                          onPressed: _isAuthLoading ? null : _handleEmailAuth,
                          child: _isAuthLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                              : const Text(
                                  'SE CONNECTER',
                                  style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white54, size: 16),
                        label: const Text(
                          'Retour au menu public',
                          style: TextStyle(color: Colors.white60, fontSize: 12.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 2. DASHBOARD PRINCIPAL AVEC LES 2 ZONES DÉDIÉES
  // ===========================================================================

  Widget _buildDashboardView() {
    return ValueListenableBuilder(
      valueListenable: _service.currentBookNotifier,
      builder: (context, book, child) {
        final int totalPages = book.pages.length;
        if (_selectedPageIndex >= totalPages) {
          _selectedPageIndex = 0;
        }

        final BookPage currentPage = book.pages[_selectedPageIndex];
        final String pageTitle = currentPage.category?.title ?? 'PAGE ${_selectedPageIndex + 1}';

        return Container(
          color: const Color(0xFF787569), // Fond #787569
          child: Column(
            children: [
              // BARRE SUPÉRIEURE NAVBAR #C9C5B1
              _buildTopHeader(),

              // SÉLECTEUR DE ZONE : [ 🍽️ PRODUITS & PRIX ] vs [ 🖼️ PHOTOS DU LIVRE ]
              _buildZoneSelector(),

              // SÉLECTEUR DE PAGE DU LIVRE (PAGE 1, PAGE 2, PAGE 3... SANS "TOUS")
              _buildPageTabs(book.pages),

              // CONTENU DE LA ZONE SÉLECTIONNÉE
              Expanded(
                child: _currentZoneIndex == 0
                    ? _buildProductsZone(currentPage, pageTitle)
                    : _buildPhotosZone(currentPage, pageTitle),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===========================================================================
  // COMPOSANTS DU DASHBOARD
  // ===========================================================================

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFFC9C5B1), // Navbar #C9C5B1
        border: Border(bottom: BorderSide(color: Color(0xFFB5B099))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Fermer',
          ),
          const Spacer(),

          // Bouton Enregistrer
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A2F), // Vert foncé luxueux
              foregroundColor: Colors.white,
              elevation: 1,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_rounded, size: 16, color: Colors.white),
            label: Text(
              _isSaving ? 'En cours...' : 'Enregistrer',
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: _isSaving ? null : _handleManualSave,
          ),
          const SizedBox(width: 8),

          // Bouton Admin en noir et texte en blanc
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.manage_accounts_rounded, size: 16, color: Colors.white),
            label: const Text(
              'Admin',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            onPressed: _showAdminManagementDialog,
          ),
          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87, size: 20),
            tooltip: 'Quitter',
            onPressed: () async {
              await _service.signOut();
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildZoneSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Onglet 1 : Produits & Prix
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentZoneIndex = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _currentZoneIndex == 0 ? AppColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.restaurant_menu_rounded,
                      size: 16,
                      color: _currentZoneIndex == 0 ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PRODUITS & PRIX',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _currentZoneIndex == 0 ? Colors.black : Colors.white70,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Onglet 2 : Photos du Livre
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _currentZoneIndex = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _currentZoneIndex == 1 ? AppColors.gold : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 16,
                      color: _currentZoneIndex == 1 ? Colors.black : Colors.white70,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'PHOTOS DU LIVRE',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: _currentZoneIndex == 1 ? Colors.black : Colors.white70,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageTabs(List<BookPage> pages) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedPageIndex == index;
          final catTitle = pages[index].category?.title ?? 'PAGE ${index + 1}';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                'Page ${index + 1} : $catTitle',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.black : Colors.white70,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.gold,
              backgroundColor: const Color(0xFF1B1B22),
              side: BorderSide(
                color: isSelected ? AppColors.gold : Colors.white12,
              ),
              onSelected: (_) => setState(() => _selectedPageIndex = index),
            ),
          );
        },
      ),
    );
  }

  // ===========================================================================
  // 3. ZONE 1 : GESTION DES PRODUITS DE LA PAGE SÉLECTIONNÉE
  // ===========================================================================

  Widget _buildProductsZone(BookPage currentPage, String pageTitle) {
    final List<Product> allProducts = currentPage.category?.products ?? <Product>[];

    return Column(
      children: [
        // Carte d'entête de la page active + Bouton Ajouter (SANS BARRE DE RECHERCHE)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Page ${_selectedPageIndex + 1} • $pageTitle',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: AppColors.goldLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${allProducts.length} produit(s) au menu',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),

              // Bouton Ajouter Produit
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 2,
                ),
                onPressed: () => _showAddProductDialog(pageTitle),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text(
                  'AJOUTER',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Liste des produits
        Expanded(
          child: allProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.restaurant_menu_rounded, color: Colors.white30, size: 48),
                      const SizedBox(height: 10),
                      Text(
                        'Aucun produit sur la Page ${_selectedPageIndex + 1}.',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
                        onPressed: () => _showAddProductDialog(pageTitle),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Ajouter le premier produit'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allProducts.length,
                  itemBuilder: (context, index) {
                    final prod = allProducts[index];
                    return _buildProductCard(prod);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProductCard(Product prod) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showEditProductDialog(prod),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Nom & Description (SANS CHAMP PHOTO)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                        ),
                      ),
                      if (prod.description != null && prod.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          prod.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Prix & Actions (sans débordement)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Prix cliquable
                    GestureDetector(
                      onTap: () => _showQuickPriceDialog(prod),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.gold, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              prod.price,
                              style: const TextStyle(
                                fontFamily: 'Montserrat',
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_rounded, color: AppColors.gold, size: 12),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      tooltip: 'Supprimer',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _showDeleteProductDialog(prod),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 4. ZONE 2 : GESTION DÉDIÉE DES PHOTOS DU LIVRE (PAR PAGE)
  // ===========================================================================

  Widget _buildPhotosZone(BookPage currentPage, String pageTitle) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      children: [
        // En-tête info
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.photo_library_outlined, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Gestion des visuels de la Page ${_selectedPageIndex + 1} ($pageTitle). Les modifications s\'appliquent immédiatement dans le livre.',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 11.5, height: 1.3),
                ),
              ),
            ],
          ),
        ),

        // 1. Photo de coin ("Lune" en haut à droite)
        _buildPhotoSlotCard(
          title: 'Photo de coin (Coin supérieur droit)',
          subtitle: 'Affichée en médaillon circulaire ou décoratif',
          imagePath: currentPage.cornerPhotoPath,
          onEdit: () => _showEditPhotoDialog(
            slotName: 'Photo de coin',
            initialPath: currentPage.cornerPhotoPath,
            onSave: (newPath, newTitle) {
              _service.updatePagePhotos(_selectedPageIndex, cornerPhotoPath: newPath);
              setState(() {});
            },
          ),
        ),

        // 2. Grande Photo Panoramique de bas de page (Style 2 & Style 4)
        if (currentPage.largeBottomPhotoPath != null || currentPage.style == PageStyle.singleLargeBottom)
          _buildPhotoSlotCard(
            title: 'Grande Photo Panoramique (Bas de page)',
            subtitle: currentPage.largeBottomPhotoTitle ?? 'Sans titre',
            imagePath: currentPage.largeBottomPhotoPath,
            onEdit: () => _showEditPhotoDialog(
              slotName: 'Grande Photo Panoramique',
              initialPath: currentPage.largeBottomPhotoPath,
              initialTitle: currentPage.largeBottomPhotoTitle,
              hasTitle: true,
              onSave: (newPath, newTitle) {
                _service.updatePagePhotos(
                  _selectedPageIndex,
                  largeBottomPhotoPath: newPath,
                  largeBottomPhotoTitle: newTitle,
                );
                setState(() {});
              },
            ),
          ),

        // 3. Deuxième Photo de bas de page (Style 4)
        if (currentPage.secondBottomPhotoPath != null)
          _buildPhotoSlotCard(
            title: 'Deuxième Photo de bas (Duo)',
            subtitle: currentPage.secondBottomPhotoTitle ?? 'Sans titre',
            imagePath: currentPage.secondBottomPhotoPath,
            onEdit: () => _showEditPhotoDialog(
              slotName: 'Deuxième Photo de bas',
              initialPath: currentPage.secondBottomPhotoPath,
              initialTitle: currentPage.secondBottomPhotoTitle,
              hasTitle: true,
              onSave: (newPath, newTitle) {
                _service.updatePagePhotos(
                  _selectedPageIndex,
                  secondBottomPhotoPath: newPath,
                  secondBottomPhotoTitle: newTitle,
                );
                setState(() {});
              },
            ),
          ),

        // 4. Photos alternées (Style 3)
        if (currentPage.firstAlternatingPhotoPath != null)
          _buildPhotoSlotCard(
            title: '1ère Photo Alternée (Milieu)',
            subtitle: currentPage.firstAlternatingPhotoTitle ?? 'Photo 1',
            imagePath: currentPage.firstAlternatingPhotoPath,
            onEdit: () => _showEditPhotoDialog(
              slotName: '1ère Photo Alternée',
              initialPath: currentPage.firstAlternatingPhotoPath,
              initialTitle: currentPage.firstAlternatingPhotoTitle,
              hasTitle: true,
              onSave: (newPath, newTitle) {
                _service.updatePagePhotos(
                  _selectedPageIndex,
                  firstAlternatingPhotoPath: newPath,
                  firstAlternatingPhotoTitle: newTitle,
                );
                setState(() {});
              },
            ),
          ),

        if (currentPage.secondAlternatingPhotoPath != null)
          _buildPhotoSlotCard(
            title: '2ème Photo Alternée (Bas)',
            subtitle: currentPage.secondAlternatingPhotoTitle ?? 'Photo 2',
            imagePath: currentPage.secondAlternatingPhotoPath,
            onEdit: () => _showEditPhotoDialog(
              slotName: '2ème Photo Alternée',
              initialPath: currentPage.secondAlternatingPhotoPath,
              initialTitle: currentPage.secondAlternatingPhotoTitle,
              hasTitle: true,
              onSave: (newPath, newTitle) {
                _service.updatePagePhotos(
                  _selectedPageIndex,
                  secondAlternatingPhotoPath: newPath,
                  secondAlternatingPhotoTitle: newTitle,
                );
                setState(() {});
              },
            ),
          ),

        // 5. Médaillons circulaires (Style 1)
        if (currentPage.bottomPhotos != null && currentPage.bottomPhotos!.isNotEmpty)
          ...currentPage.bottomPhotos!.asMap().entries.map((entry) {
            final idx = entry.key;
            final bp = entry.value;

            return _buildPhotoSlotCard(
              title: 'Médaillon circulaire ${idx + 1}',
              subtitle: '${bp.title} • ${bp.price ?? ""}',
              imagePath: bp.imagePath,
              onEdit: () => _showEditPhotoDialog(
                slotName: 'Médaillon ${idx + 1}',
                initialPath: bp.imagePath,
                initialTitle: bp.title,
                hasTitle: true,
                onSave: (newPath, newTitle) {
                  final updatedList = List<BottomPhoto>.from(currentPage.bottomPhotos!);
                  updatedList[idx] = BottomPhoto(
                    title: newTitle ?? bp.title,
                    price: bp.price,
                    imagePath: newPath,
                  );
                  _service.updatePagePhotos(_selectedPageIndex, bottomPhotos: updatedList);
                  setState(() {});
                },
              ),
            );
          }),
      ],
    );
  }

  Widget _buildPhotoSlotCard({
    required String title,
    required String subtitle,
    required String? imagePath,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181820),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          // Aperçu Image
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF22222C),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: imagePath != null && imagePath.isNotEmpty
                  ? (imagePath.startsWith('data:image')
                      ? Image.memory(
                          base64Decode(imagePath.substring(imagePath.indexOf(',') + 1)),
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, color: Colors.white38),
                        )
                      : (imagePath.startsWith('http')
                          ? Image.network(imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, color: Colors.white38))
                          : Image.asset(imagePath, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image_rounded, color: Colors.white38))))
                  : const Icon(Icons.image_not_supported_rounded, color: Colors.white24),
            ),
          ),
          const SizedBox(width: 14),

          // Titre & Sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 11),
                ),
                const SizedBox(height: 4),
                Text(
                  imagePath ?? 'Aucune photo configurée',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Bouton Modifier
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_rounded, size: 14),
            label: const Text('Changer', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. MODALES ET DIALOGUES (SANS OVERFLOW)
  // ===========================================================================

  void _showAddProductDialog(String categoryTitle) {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final sectionCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded, color: AppColors.gold, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ajouter à la Page ${_selectedPageIndex + 1}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catégorie de la page : $categoryTitle',
                  style: const TextStyle(color: AppColors.goldLight, fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 14),
                _buildField(nameCtrl, 'Nom du produit (ex: Iced Caramel BM)', Icons.title_rounded),
                const SizedBox(height: 12),
                _buildField(priceCtrl, 'Prix (ex: 8.5 DT)', Icons.monetization_on_outlined),
                const SizedBox(height: 12),
                _buildField(sectionCtrl, 'Sous-catégorie / Section (ex: Café Spécial, Chocolat...)', Icons.category_outlined),
                const SizedBox(height: 12),
                _buildField(descCtrl, 'Description (ingrédients, détails...)', Icons.description_outlined, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = priceCtrl.text.trim();
              final sec = sectionCtrl.text.trim();

              if (name.isEmpty || price.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Le nom et le prix sont requis.')),
                );
                return;
              }

              Navigator.pop(ctx);
              await _service.addProductToPage(
                pageIndex: _selectedPageIndex,
                name: name,
                price: price,
                description: descCtrl.text,
                section: sec.isNotEmpty ? sec : null,
              );
              setState(() {});
            },
            child: const Text('Valider et Ajouter', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Product prod) {
    final nameCtrl = TextEditingController(text: prod.name);
    final priceCtrl = TextEditingController(text: prod.price);
    final sectionCtrl = TextEditingController(text: prod.section ?? '');
    final descCtrl = TextEditingController(text: prod.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.edit_note_rounded, color: AppColors.gold, size: 22),
            SizedBox(width: 8),
            Text(
              'Modifier le produit',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(nameCtrl, 'Nom du produit', Icons.title_rounded),
                const SizedBox(height: 12),
                _buildField(priceCtrl, 'Prix (ex: 8.5 DT)', Icons.monetization_on_outlined),
                const SizedBox(height: 12),
                _buildField(sectionCtrl, 'Sous-catégorie / Section (ex: Café Spécial, Chocolat...)', Icons.category_outlined),
                const SizedBox(height: 12),
                _buildField(descCtrl, 'Description', Icons.description_outlined, maxLines: 2),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final price = priceCtrl.text.trim();
              final sec = sectionCtrl.text.trim();

              if (name.isEmpty || price.isEmpty) return;

              Navigator.pop(ctx);
              await _service.updateProductOnPage(
                pageIndex: _selectedPageIndex,
                productId: prod.id ?? prod.name,
                name: name,
                price: price,
                description: descCtrl.text,
                section: sec.isNotEmpty ? sec : null,
              );
              setState(() {});
            },
            child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteProductDialog(Product prod) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
            SizedBox(width: 8),
            Text(
              'Supprimer le produit',
              style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Supprimer définitivement "${prod.name}" de la Page ${_selectedPageIndex + 1} ?',
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await _service.deleteProductFromPage(
                pageIndex: _selectedPageIndex,
                productId: prod.id ?? prod.name,
              );
              setState(() {});
            },
            child: const Text('Supprimer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showQuickPriceDialog(Product prod) {
    final priceCtrl = TextEditingController(text: prod.price);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF181820),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.gold, width: 1.2),
        ),
        title: Text(
          'Changer le prix',
          style: const TextStyle(fontFamily: 'Montserrat', color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              prod.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              autofocus: true,
              style: const TextStyle(color: AppColors.gold, fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Nouveau prix (ex: 7.5 DT)',
                labelStyle: const TextStyle(color: AppColors.goldLight, fontSize: 12),
                filled: true,
                fillColor: const Color(0xFF22222C),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
            onPressed: () async {
              final newP = priceCtrl.text.trim();
              if (newP.isNotEmpty) {
                Navigator.pop(ctx);
                await _service.updateProductPrice(
                  productId: prod.id ?? prod.name,
                  newPrice: newP,
                );
                setState(() {});
              }
            },
            child: const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showEditPhotoDialog({
    required String slotName,
    required String? initialPath,
    String? initialTitle,
    bool hasTitle = false,
    required Function(String path, String? title) onSave,
  }) {
    String currentPath = initialPath ?? '';
    final titleCtrl = TextEditingController(text: initialTitle ?? '');
    bool isPicking = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF181820),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.gold, width: 1.2),
            ),
            title: Row(
              children: [
                const Icon(Icons.add_a_photo_rounded, color: AppColors.gold, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modifier $slotName',
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 360,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasTitle) ...[
                      _buildField(titleCtrl, 'Titre / Légende de la photo', Icons.title_rounded),
                      const SizedBox(height: 14),
                    ],

                    // Aperçu de la photo actuelle ou sélectionnée
                    Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFF101014),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6), width: 1.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: currentPath.isNotEmpty
                            ? (currentPath.startsWith('data:image')
                                ? Image.memory(
                                    base64Decode(currentPath.substring(currentPath.indexOf(',') + 1)),
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Center(
                                      child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 36),
                                    ),
                                  )
                                : Image.asset(
                                    currentPath,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Center(
                                      child: Icon(Icons.broken_image_rounded, color: Colors.white24, size: 36),
                                    ),
                                  ))
                            : const Center(
                                child: Text(
                                  'Aucune photo sélectionnée',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bouton unique pour importer une photo
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF242430),
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold, width: 1.1),
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: isPicking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                            )
                          : const Icon(Icons.photo_library_rounded, size: 20),
                      label: Text(
                        isPicking ? 'Chargement...' : 'Choisir une photo',
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      onPressed: isPicking
                          ? null
                          : () {
                              if (kIsWeb) {
                                // Sur le Web hébergé (Chrome, Safari, Android, iPhone) :
                                // L'appel à uploadInput.click() DOIT se faire de manière 100% synchrone
                                // lors du clic de l'utilisateur, sinon les navigateurs bloquent la boîte de dialogue.
                                setModalState(() => isPicking = true);
                                try {
                                  final html.FileUploadInputElement uploadInput =
                                      html.FileUploadInputElement()
                                        ..accept = 'image/*'
                                        ..multiple = false;

                                  uploadInput.onChange.listen((e) {
                                    final files = uploadInput.files;
                                    if (files != null && files.isNotEmpty) {
                                      final html.File file = files[0];
                                      final reader = html.FileReader();
                                      reader.readAsDataUrl(file);
                                      reader.onLoadEnd.listen((event) {
                                        final result = reader.result as String?;
                                        if (result != null && result.isNotEmpty) {
                                          setModalState(() {
                                            currentPath = result;
                                            isPicking = false;
                                          });
                                        } else {
                                          setModalState(() => isPicking = false);
                                        }
                                      });
                                    } else {
                                      setModalState(() => isPicking = false);
                                    }
                                  });

                                  // Déclenchement direct et instantané de l'explorateur du navigateur / galerie du smartphone
                                  uploadInput.click();
                                } catch (e) {
                                  debugPrint('[Web Upload Input] Erreur: $e');
                                  setModalState(() => isPicking = false);
                                }
                              } else {
                                // Sur mobile natif (iOS / Android natif)
                                () async {
                                  setModalState(() => isPicking = true);
                                  try {
                                    final picker = ImagePicker();
                                    final XFile? imgFile = await picker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: 1200,
                                      maxHeight: 1200,
                                      imageQuality: 85,
                                    );
                                    if (imgFile != null) {
                                      final bytes = await imgFile.readAsBytes();
                                      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
                                      setModalState(() {
                                        currentPath = base64String;
                                      });
                                    }
                                  } catch (e) {
                                    debugPrint('[Native ImagePicker] Erreur: $e');
                                  } finally {
                                    setModalState(() => isPicking = false);
                                  }
                                }();
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler', style: TextStyle(color: Colors.white60)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (currentPath.isNotEmpty) {
                    Navigator.pop(ctx);
                    onSave(currentPath, hasTitle ? titleCtrl.text.trim() : null);
                  }
                },
                child: const Text('Valider la photo', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAdminManagementDialog() {
    final newPasswordCtrl = TextEditingController();
    final newAdminEmailCtrl = TextEditingController();
    final newAdminPassCtrl = TextEditingController();

    int activeSection = 0; // 0 = Mon mot de passe, 1 = Ajouter admin, 2 = Liste admins
    List<String> adminList = [];
    bool isLoadingList = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isLoadingList) {
            _service.fetchAdmins().then((list) {
              if (ctx.mounted) {
                setModalState(() {
                  adminList = list;
                  isLoadingList = false;
                });
              }
            });
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF16161C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.gold, width: 1.2),
            ),
            title: Row(
              children: const [
                Icon(Icons.security_rounded, color: AppColors.gold, size: 22),
                SizedBox(width: 8),
                Text(
                  'Sécurité & Administrateurs',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sélecteur de sous-onglet
                    Row(
                      children: [
                        _buildSectionPill('Mot de passe', 0, activeSection, (s) => setModalState(() => activeSection = s)),
                        const SizedBox(width: 6),
                        _buildSectionPill('Ajouter admin', 1, activeSection, (s) => setModalState(() => activeSection = s)),
                        const SizedBox(width: 6),
                        _buildSectionPill('Équipe', 2, activeSection, (s) => setModalState(() => activeSection = s)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // SECTION 0 : CHANGER MOT DE PASSE
                    if (activeSection == 0) ...[
                      const Text(
                        'Changer votre mot de passe de connexion',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      _buildField(newPasswordCtrl, 'Nouveau mot de passe', Icons.lock_reset_rounded),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            final pass = newPasswordCtrl.text.trim();
                            if (pass.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Le mot de passe doit comporter au moins 6 caractères.')),
                              );
                              return;
                            }
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await _service.changePassword(pass);
                              if (ctx.mounted) Navigator.pop(ctx);
                              messenger.showSnackBar(
                                const SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text('Mot de passe mis à jour avec succès !'),
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(backgroundColor: Colors.red, content: Text('Erreur : $e')),
                              );
                            }
                          },
                          child: const Text('Enregistrer le mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    // SECTION 1 : AJOUTER UN AUTRE ADMIN
                    if (activeSection == 1) ...[
                      const Text(
                        'Créer un accès administrateur pour un collaborateur',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      _buildField(newAdminEmailCtrl, 'Email du nouvel admin', Icons.email_outlined),
                      const SizedBox(height: 10),
                      _buildField(newAdminPassCtrl, 'Mot de passe temporaire', Icons.lock_outline_rounded),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            final em = newAdminEmailCtrl.text.trim();
                            final pa = newAdminPassCtrl.text.trim();
                            if (em.isEmpty || pa.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Renseignez un email et un mot de passe d\'au moins 6 caractères.')),
                              );
                              return;
                            }
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await _service.createAdminUser(email: em, password: pa);
                              newAdminEmailCtrl.clear();
                              newAdminPassCtrl.clear();
                              final updated = await _service.fetchAdmins();
                              setModalState(() {
                                adminList = updated;
                                activeSection = 2; // Aller à la liste
                              });
                              messenger.showSnackBar(
                                SnackBar(backgroundColor: Colors.green, content: Text('Admin $em créé avec succès !')),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(backgroundColor: Colors.red, content: Text('Erreur : $e')),
                              );
                            }
                          },
                          child: const Text('Ajouter l\'administrateur', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],

                    // SECTION 2 : LISTE DES ADMINS & SUPPRESSION
                    if (activeSection == 2) ...[
                      const Text(
                        'Administrateurs ayant accès à la gestion du menu :',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      if (isLoadingList)
                        const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: AppColors.gold)))
                      else if (adminList.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text('Aucun administrateur secondaire.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                        )
                      else
                        ...adminList.map((adm) {
                          final isCurrent = adm.toLowerCase() == (_service.currentAdminEmail ?? '').toLowerCase();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF202028),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined, color: AppColors.gold, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    adm,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.gold.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text('Vous', style: TextStyle(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    tooltip: 'Révoquer l\'admin',
                                    onPressed: () async {
                                      await _service.deleteAdminUser(adm);
                                      final updated = await _service.fetchAdmins();
                                      setModalState(() => adminList = updated);
                                    },
                                  ),
                              ],
                            ),
                          );
                        }),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Fermer', style: TextStyle(color: Colors.white70)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionPill(String title, int index, int activeIndex, Function(int) onTap) {
    final isSelected = index == activeIndex;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : const Color(0xFF22222C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.gold : Colors.white12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.goldLight, fontSize: 11.5),
        prefixIcon: Icon(icon, color: AppColors.gold, size: 18),
        filled: true,
        fillColor: const Color(0xFF22222C),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.gold, width: 1.2)),
      ),
    );
  }
}
