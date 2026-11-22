import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../core/app_colors.dart';
import '../../data/models/book_model.dart';
import '../../services/supabase_service.dart';
import '../admin/admin_screen.dart';
import '../book/book_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  VideoPlayerController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkScannedTable());
  }

  // Scan QR d'une table : ?table=<uuid> → alerter si la table est réservée
  Future<void> _checkScannedTable() async {
    final tableId = Uri.base.queryParameters['table'];
    if (tableId == null || tableId.isEmpty) return;
    final status = await SupabaseService.instance.fetchTableStatus(tableId);
    if (!mounted || status == null || status['booked'] != true) return;
    _showReservedDialog(status);
  }

  void _showReservedDialog(Map<String, dynamic> status) {
    final guest = (status['guest_name'] as String?)?.trim();
    final when = DateTime.tryParse(status['booked_for'] as String? ?? '')?.toLocal();
    final capacity = (status['capacity'] as num?)?.toInt();
    final whenText = when == null
        ? null
        : '${when.day.toString().padLeft(2, '0')}/${when.month.toString().padLeft(2, '0')}/${when.year}'
            ' à ${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF17171A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFC59B4B), width: 1.2),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: Color(0xFFD4AF37), size: 42),
            const SizedBox(height: 12),
            const Text(
              'TABLE RÉSERVÉE',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Color(0xFFE5C158),
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              guest != null && guest.isNotEmpty
                  ? 'Réservée pour ${guest.toUpperCase()}'
                  : 'Cette table est actuellement réservée.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (whenText != null) ...[
              const SizedBox(height: 4),
              Text(
                whenText,
                style: const TextStyle(color: Color(0xFFB9A467), fontSize: 12),
              ),
            ],
            if (capacity != null) ...[
              const SizedBox(height: 4),
              Text(
                'Capacité : $capacity personne(s)',
                style: const TextStyle(color: Color(0xFF8B8F9A), fontSize: 11),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'Merci de vous rapprocher du personnel.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9A9DA5), fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'Voir le menu',
                  style: TextStyle(color: Color(0xFFE5C158), fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/video-back.mp4');
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.setVolume(0.0); // Muted pour autoplay
      await _videoController!.play();
      if (mounted) {
        setState(() {
          _videoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[VideoPlayer] Error loading video: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _openMenu(Book book) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: BookScreen(book: book),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Book>(
      valueListenable: SupabaseService.instance.currentBookNotifier,
      builder: (context, book, child) {
        // Fond clair et épuré pour la partie basse
        const Color lightBg = Color(0xFFF7F5F0);

        return Scaffold(
          backgroundColor: lightBg,
          body: Column(
            children: [
              // ===============================================================
              // 🎬 1. PARTIE HAUTE : VIDÉO 100% PURE (SANS AUCUN FILTRE SOMBRE)
              // ===============================================================
              Expanded(
                flex: 32,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // A. Découpe en arc de la vidéo (sans aucun filtre ni dégradé par-dessus)
                    ClipPath(
                      clipper: ArcBottomClipper(),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (_videoInitialized && _videoController != null)
                            FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _videoController!.value.size.width,
                                height: _videoController!.value.size.height,
                                child: VideoPlayer(_videoController!),
                              ),
                            )
                          else
                            Image.asset(
                              'assets/background.jfif',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(color: AppColors.appBackground),
                            ),
                        ],
                      ),
                    ),

                    // B. Liseré doré courbé en forme d'arc
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: ArcGoldenBorderPainter(),
                        ),
                      ),
                    ),

                    // C. Bouton discret d'accès gérant en haut à droite
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: IconButton(
                            icon: Icon(
                              Icons.lock_outline_rounded,
                              color: AppColors.gold.withValues(alpha: 0.4),
                              size: 20,
                            ),
                            tooltip: 'Espace Gérant',
                            onPressed: () => AdminScreen.open(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ===============================================================
              // 📖 2. PARTIE BASSE : TITRE VIP + LE LIVRE ET APPLIQUES + BOUTON
              // ===============================================================
              Expanded(
                flex: 68,
                child: Container(
                  color: lightBg,
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                  child: Column(
                    children: [
                      // ── TITRE "BIENVENUE À L'ESPACE VIP 4*" EN HAUT DU LIVRE ──
                      _buildVipHeader(),

                      const SizedBox(height: 2),

                      // ── LE LIVRE BM GOLD AGRANDI 1.3x + 2 APPLIQUES MURALE ──
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final double availWidth = constraints.maxWidth;
                            final double availHeight = constraints.maxHeight;

                            const double bookRatio = 0.58;

                            // 1.3x plus grand : utilise quasiment toute la hauteur disponible
                            double bookHeight = availHeight * 0.98;
                            double bookWidth = bookHeight * bookRatio;

                            // Appliques dorées latérales (hauteur ~65% du livre, ratio 220/1558)
                            double ornamentHeight = bookHeight * 0.65;
                            double ornamentWidth = ornamentHeight * (220.0 / 1558.0);
                            const double spacing = 10.0;

                            // Ajustement si la largeur totale dépasse l'écran
                            final double maxTotalWidth = availWidth * 0.96;
                            final double requiredTotalWidth = bookWidth + (ornamentWidth * 2) + (spacing * 2);

                            if (requiredTotalWidth > maxTotalWidth) {
                              final double scaleFactor = maxTotalWidth / requiredTotalWidth;
                              bookWidth *= scaleFactor;
                              bookHeight *= scaleFactor;
                              ornamentHeight = bookHeight * 0.65;
                              ornamentWidth = ornamentHeight * (220.0 / 1558.0);
                            }

                            return Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // ── APPLIQUE MURALE GAUCHE ────────────────
                                  _buildSideOrnament(
                                    height: ornamentHeight,
                                    width: ornamentWidth,
                                    isLeft: true,
                                  ),

                                  const SizedBox(width: spacing),

                                  // ── LE LIVRE BM GOLD AGRANDI (x1.3) ───────
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _openMenu(book),
                                    child: Container(
                                      width: bookWidth,
                                      height: bookHeight,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.30),
                                            blurRadius: 26,
                                            offset: const Offset(0, 14),
                                            spreadRadius: -2,
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          book.imagePath ?? 'assets/bm.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            color: AppColors.bookBackground,
                                            child: Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Text('👑', style: TextStyle(fontSize: 48)),
                                                  SizedBox(height: 12),
                                                  Text(
                                                    'BM GOLD',
                                                    style: TextStyle(
                                                      fontFamily: 'Svetze',
                                                      color: AppColors.gold,
                                                      fontSize: 22,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(width: spacing),

                                  // ── APPLIQUE MURALE DROITE ───────────────
                                  _buildSideOrnament(
                                    height: ornamentHeight,
                                    width: ornamentWidth,
                                    isLeft: false,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 6),

                      // ── BOUTON ROYAL "OUVRIR LE MENU" ─────────────────────
                      InkWell(
                        onTap: () => _openMenu(book),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 28),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFFE5C158),
                                Color(0xFFD4AF37),
                                Color(0xFFA67C46),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.8),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFA67C46).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_stories_rounded, color: Color(0xFF141414), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'OUVRIR LE MENU',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Color(0xFF141414),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.arrow_forward_rounded, color: Color(0xFF141414), size: 15),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Applique murale dorée latérale (design élégant et proportionné)
  Widget _buildSideOrnament({
    required double height,
    required double width,
    required bool isLeft,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.18),
            blurRadius: 16,
            spreadRadius: 1,
            offset: Offset(isLeft ? -2 : 2, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Image.asset(
        'assets/ornament_gold.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          'assets/WhatsApp Image 2026-11-21 at 18.19.44.jpeg',
          fit: BoxFit.contain,
          errorBuilder: (c, e, s) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  /// Titre royal "BIENVENUE À L'ESPACE VIP 4*" placé en haut du livre sur fond clair
  Widget _buildVipHeader() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "BIENVENUE À L'ESPACE",
          style: TextStyle(
            fontFamily: 'Montserrat',
            letterSpacing: 3.5,
            fontSize: 11,
            color: Color(0xFF7A5826), // Bronze doré prestigieux sur fond clair
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFC59B4B),
              Color(0xFF9E722C),
              Color(0xFF7A5826),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(bounds),
          child: const Text(
            'V I P',
            style: TextStyle(
              fontFamily: 'Svetze',
              fontSize: 24,
              letterSpacing: 5.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 2),
        // 4 étoiles dorées
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 20,
              height: 1.2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.transparent, Color(0xFFC59B4B)],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 5),
            ...List.generate(4, (index) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1.5),
                child: Icon(Icons.star, size: 10, color: Color(0xFFC59B4B)),
              );
            }),
            const SizedBox(width: 5),
            Container(
              width: 20,
              height: 1.2,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFC59B4B), Colors.transparent],
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// =============================================================================
// 🎨 DÉCOUPE EN FORME D'ARC & LIGNE DORÉE LUMINEUSE
// =============================================================================

class ArcBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const double arcDepth = 24.0;
    final path = Path();
    path.lineTo(0, size.height - arcDepth);
    // Courbe en arc doux plongeant vers le bas au centre
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - arcDepth,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class ArcGoldenBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double arcDepth = 24.0;
    final path = Path();
    path.moveTo(0, size.height - arcDepth);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - arcDepth,
    );

    // 1. Halo lumineux doré
    final glowPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path, glowPaint);

    // 2. Ligne dorée nette avec dégradé d'éclat
    final strokePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.transparent,
          Color(0xFFC59B4B),
          Color(0xFFFFF2A8),
          Color(0xFFD4AF37),
          Colors.transparent,
        ],
        stops: [0.0, 0.20, 0.50, 0.80, 1.0],
      ).createShader(Rect.fromLTWH(0, size.height - arcDepth - 2, size.width, arcDepth + 4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
