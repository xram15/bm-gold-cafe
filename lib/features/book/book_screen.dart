import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../data/models/book_model.dart';
import '../../services/supabase_service.dart';
import 'widgets/vertical_book_flip_view.dart';

class BookScreen extends StatefulWidget {
  final Book book;
  const BookScreen({super.key, required this.book});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  final GlobalKey<VerticalBookFlipViewState> _flipKey =
      GlobalKey<VerticalBookFlipViewState>();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF1A1A1D);
    const Color goldAccent = Color(0xFF8B642C);

    return ValueListenableBuilder<Book>(
      valueListenable: SupabaseService.instance.currentBookNotifier,
      builder: (context, activeBook, _) {
        final currentBook = SupabaseService.instance.isConfigured
            ? activeBook
            : widget.book;
        final int totalPages = currentBook.pages.length;

        return Scaffold(
          // ── Fond clair, chic et lumineux pour faire ressortir le livre ──────
          backgroundColor: const Color(0xFFF6F4EF),
          body: SafeArea(
            child: Column(
              children: [
                // ── Barre supérieure élégante sur fond clair ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: darkColor,
                          size: 20,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Retour à l\'accueil',
                      ),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text(
                                'B M   G O L D',
                                style: TextStyle(
                                  fontFamily: 'Svetze',
                                  color: darkColor,
                                  fontSize: 22,
                                  letterSpacing: 4.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "L'ÉTHIQUE DU CAFÉ",
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontSize: 9.5,
                                  letterSpacing: 2.8,
                                  color: goldAccent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                // ── Zone centrale : Menu vertical maximisé avec tournage de page ─
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final frameWidth = math.min(
                        constraints.maxWidth,
                        constraints.maxHeight / 1.48 + 16,
                      );
                      final availableHeight = math.max(
                        0.0,
                        constraints.maxHeight - 4,
                      );
                      final availableWidth = math.max(0.0, frameWidth - 16);
                      final frameHeight = math.min(
                        constraints.maxHeight,
                        math.min(
                              availableHeight,
                              availableWidth * 1.48 * 1.21,
                            ) +
                            4,
                      );
                      return Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: frameWidth,
                          height: frameHeight,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 2.0,
                                ),
                                child: VerticalBookFlipView(
                                  key: _flipKey,
                                  book: currentBook,
                                  onPageChanged: (page) {
                                    setState(() {
                                      _currentPage = page;
                                    });
                                  },
                                ),
                              ),

                              // Flèche retour (Page précédente) - Au milieu vertical, calée tout à gauche
                              if (_currentPage > 0)
                                Positioned(
                                  left: 2,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: _FloatingNavBtn(
                                      icon: Icons.chevron_left_rounded,
                                      onTap: () {
                                        _flipKey.currentState?.flipBackward();
                                      },
                                      iconColor: darkColor,
                                      tooltip: 'Page précédente',
                                    ),
                                  ),
                                ),

                              // Flèche avant (Page suivante) - Au milieu vertical, calée tout à droite
                              if (_currentPage < totalPages - 1)
                                Positioned(
                                  right: 2,
                                  top: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: _FloatingNavBtn(
                                      icon: Icons.chevron_right_rounded,
                                      onTap: () {
                                        _flipKey.currentState?.flipForward();
                                      },
                                      iconColor: darkColor,
                                      tooltip: 'Page suivante',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Chiffre doré de la page active, centré sur fond sombre ──
                Container(
                  width: double.infinity,
                  color: darkColor,
                  padding: const EdgeInsets.only(top: 10.0, bottom: 22.0),
                  child: _currentPage + 1 <= 10
                      ? Image.asset(
                          'assets/numbers/num_${_currentPage + 1}.png',
                          width: 72,
                          height: 72,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        )
                      : Text(
                          '${_currentPage + 1}',
                          style: const TextStyle(
                            fontFamily: 'Svetze',
                            color: Color(0xFFD4AF37),
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FloatingNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final String tooltip;

  const _FloatingNavBtn({
    required this.icon,
    required this.onTap,
    required this.iconColor,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.95),
            border: Border.all(
              color: const Color(0xFFC59B4B).withValues(alpha: 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
      ),
    );
  }
}
