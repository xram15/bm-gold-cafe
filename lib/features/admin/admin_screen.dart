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
import '../../shared/widgets/app_cached_image.dart';
import '../book/book_screen.dart';
import 'reservations_screen.dart';

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
        if (_selectedPageIndex >= book.pages.length) _selectedPageIndex = 0;
        final page = book.pages[_selectedPageIndex];
        final title = page.category?.title ?? 'PAGE ${_selectedPageIndex + 1}';
        return Container(
          color: const Color(0xFFF2F3F8),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(children: [
                _buildTopHeader(),
                _buildZoneSelector(),
                _buildPageTabs(book.pages),
                Expanded(child: _currentZoneIndex == 0 ? _buildProductsZone(page, title) : _buildPhotosZone(page, title)),
                _buildBottomNavigation(),
              ]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 0),
      child: Row(children: [
        const Icon(Icons.workspace_premium, size: 32, color: Color(0xFFC89A3B)),
        const SizedBox(width: 9),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BM GOLD', style: TextStyle(fontFamily: 'Svetze', fontSize: 19, color: Color(0xFF171717))),
          Text('L’ÉTHIQUE DU CAFÉ', style: TextStyle(fontSize: 7, letterSpacing: 1.2, color: Color(0xFF555967))),
        ])),
        IconButton(
          tooltip: 'Enregistrer',
          color: const Color(0xFF171717),
          onPressed: _isSaving ? null : _handleManualSave,
          icon: _isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF171717))) : const Icon(Icons.save_outlined, size: 22, color: Color(0xFF171717)),
        ),
        PopupMenuButton<String>(
          tooltip: 'Compte administrateur',
          color: const Color(0xFF171717),
          icon: const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE4E5E9), child: Icon(Icons.person, size: 18, color: Color(0xFF171717))),
          onSelected: (value) async {
            if (value == 'admin') _showAdminManagementDialog();
            if (value == 'preview') {
              Navigator.push(context, MaterialPageRoute(builder: (_) => BookScreen(book: _service.currentBook)));
            }
            if (value == 'logout') {
              await _service.signOut();
              if (mounted) setState(() {});
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'preview', child: Text('Aperçu du menu')),
            PopupMenuItem(value: 'admin', child: Text('Administration')),
            PopupMenuItem(value: 'logout', child: Text('Déconnexion')),
          ],
        ),
      ]),
    );
  }

  Widget _buildZoneSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .65), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _zoneTab(0, Icons.restaurant_menu, 'Produits & Prix'),
        _zoneTab(1, Icons.image_outlined, 'Photos du livre'),
      ]),
    );
  }

  Widget _zoneTab(int index, IconData icon, String label) {
    final selected = _currentZoneIndex == index;
    return Expanded(child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: () => setState(() => _currentZoneIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(color: selected ? const Color(0xFF222222) : Colors.transparent, borderRadius: BorderRadius.circular(9)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: selected ? Colors.white : const Color(0xFF373B45)),
          const SizedBox(width: 7),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : const Color(0xFF252833)))),
        ]),
      ),
    ));
  }

  Widget _buildPageTabs(List<BookPage> pages) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: pages.length,
        itemBuilder: (context, index) {
          final selected = _selectedPageIndex == index;
          final title = pages[index].category?.title ?? 'PAGE ${index + 1}';
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: ChoiceChip(
              visualDensity: VisualDensity.compact,
              label: Text('Page ${index + 1} : $title', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF252833))),
              selected: selected,
              checkmarkColor: const Color(0xFF8A641D),
              selectedColor: const Color(0xFFF9F1DE),
              backgroundColor: const Color(0xFFF8F9FC),
              side: BorderSide(color: selected ? const Color(0xFFC79A3D) : const Color(0xFFE5E7EB)),
              onSelected: (_) => setState(() => _selectedPageIndex = index),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductsZone(BookPage page, String title) {
    final products = page.category?.products ?? <Product>[];
    return Stack(children: [
      ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 80),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .6), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Page ${_selectedPageIndex + 1} · $title', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF181B25))),
              const SizedBox(height: 3),
              Text('${products.length} produit(s) · Affiché dans le livre', style: const TextStyle(fontSize: 10, color: Color(0xFF858A99))),
            ]),
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('Aucun produit sur cette page.', style: TextStyle(color: Colors.black54, fontSize: 12))))
          else
            ...products.map((product) => _buildProductCard(product)),
        ],
      ),
      Positioned(right: 20, bottom: 16, child: ElevatedButton.icon(
        onPressed: () => _showAddProductDialog(title),
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC79A3D), foregroundColor: Colors.white, elevation: 3, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: const StadiumBorder()),
        icon: const Icon(Icons.add, size: 19),
        label: const Text('Ajouter un produit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      )),
    ]);
  }

  Widget _buildProductCard(Product product) {
    final image = product.imagePath;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(12)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 88, height: 96, child: image == null || image.isEmpty
              ? const ColoredBox(color: Color(0xFFECEEF1), child: Icon(Icons.restaurant_menu, color: Color(0xFF9A9DA5)))
              : image.startsWith('http') ? Image.network(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined))
              : Image.asset(image, fit: BoxFit.cover, errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF20232D))),
          if (product.description != null && product.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(product.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF777D8D))),
          ],
          const SizedBox(height: 8),
          InkWell(onTap: () => _showQuickPriceDialog(product), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFF8ECD0), borderRadius: BorderRadius.circular(8)),
            child: Text(product.price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF302B20))),
          )),
        ])),
        IconButton(
          tooltip: 'Modifier',
          onPressed: () => _showEditProductDialog(product),
          icon: const Icon(Icons.edit_outlined, size: 19, color: Color(0xFFAC7D24)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
        PopupMenuButton<String>(
          tooltip: 'Actions du produit', icon: const Icon(Icons.more_horiz, size: 20), padding: EdgeInsets.zero,
          onSelected: (action) { if (action == 'edit') _showEditProductDialog(product); if (action == 'delete') _showDeleteProductDialog(product); },
          itemBuilder: (context) => const [PopupMenuItem(value: 'edit', child: Text('Modifier')), PopupMenuItem(value: 'delete', child: Text('Supprimer'))],
        ),
      ]),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFFFAFAFC), borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      child: Row(children: [
        _navigationItem(Icons.home_outlined, 'Accueil', () => Navigator.pop(context)),
        _navigationItem(Icons.restaurant_menu, 'Menu', () {}, selected: true),
        _navigationItem(Icons.event_seat_outlined, 'Réservation', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationsScreen()))),
        _navigationItem(Icons.settings_outlined, 'Paramètres', _showAdminManagementDialog),
      ]),
    );
  }

  Widget _navigationItem(IconData icon, String label, VoidCallback onTap, {bool selected = false}) {
    return Expanded(child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(color: selected ? const Color(0xFFF8EED8) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 20, color: selected ? const Color(0xFFAC7D24) : const Color(0xFF656B79)),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: selected ? const Color(0xFF9C6E1E) : const Color(0xFF626775))),
        ]),
      ),
    ));
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
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.transparent),
          ),
          child: Row(
            children: [
              const Icon(Icons.photo_library_outlined, color: AppColors.gold, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Gestion des visuels de la Page ${_selectedPageIndex + 1}', style: const TextStyle(color: Color(0xFF20232C), fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 3),
                  const Text('Les modifications s\'appliquent immédiatement dans le livre.', style: TextStyle(color: Color(0xFF777D8D), fontSize: 10)),
                ]),
              ),
            ],
          ),
        ),

        // 1. Photo de coin ("Lune" en haut à droite)
        _buildPhotoSlotCard(
          title: 'Photo de coin',
          subtitle: 'Coin supérieur droit',
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
            title: '1ère Photo Alternée',
            subtitle: 'Milieu',
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
            title: '2ème Photo Alternée',
            subtitle: 'Bas',
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
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE6E8EC))),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(9),
          child: SizedBox(width: 100, height: 72, child: !hasImage
              ? const ColoredBox(color: Color(0xFFECEEF1), child: Icon(Icons.image_outlined, color: Colors.black38))
              : AppCachedImage(imagePath: imagePath, fit: BoxFit.cover, placeholder: const Icon(Icons.broken_image_outlined))),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E212B))),
          const SizedBox(height: 3),
          Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF777D8D))),
          const SizedBox(height: 5),
          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: hasImage ? const Color(0xFFE1F2DF) : const Color(0xFFEEEEEF), borderRadius: BorderRadius.circular(6)), child: Text(hasImage ? '✓ Active' : 'Non configurée', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: hasImage ? const Color(0xFF43814A) : Colors.black54))),
        ])),
        IconButton(onPressed: onEdit, tooltip: 'Modifier la photo', icon: const Icon(Icons.edit, size: 17), style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F1F3), foregroundColor: const Color(0xFF272B35))),
      ]),
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
