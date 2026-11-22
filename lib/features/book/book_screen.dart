import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
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
  final GlobalKey<VerticalBookFlipViewState> _flipKey = GlobalKey<VerticalBookFlipViewState>();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    const Color darkColor = Color(0xFF1A1A1D);
    const Color goldAccent = Color(0xFF8B642C);
    const Color goldBright = AppColors.gold;

    return ValueListenableBuilder<Book>(
      valueListenable: SupabaseService.instance.currentBookNotifier,
      builder: (context, activeBook, _) {
        final currentBook = SupabaseService.instance.isConfigured ? activeBook : widget.book;
        final int totalPages = currentBook.pages.length;

        return Scaffold(
          // ── Fond clair, chic et lumineux pour faire ressortir le livre ──────
          backgroundColor: const Color(0xFFF6F4EF),
          body: SafeArea(
            child: Column(
              children: [
                // ── Barre supérieure élégante sur fond clair ──────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
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
                      const Spacer(),
                      Column(
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
                      const Spacer(),
                      // Indicateur de page (Page X / Y)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC59B4B).withValues(alpha: 0.45),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Page ${_currentPage + 1} / $totalPages',
                          style: const TextStyle(
                            color: darkColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Zone centrale : Menu vertical maximisé avec tournage de page ─
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
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

                      // Flèche flottante retour (Page précédente) - Positionnée en bas pour ne pas cacher le contenu
                      if (_currentPage > 0)
                        Positioned(
                          left: 8,
                          bottom: 20,
                          child: _FloatingNavBtn(
                            icon: Icons.chevron_left_rounded,
                            onTap: () {
                              _flipKey.currentState?.flipBackward();
                            },
                            iconColor: darkColor,
                            tooltip: 'Page précédente',
                          ),
                        ),

                      // Flèche flottante avant (Page suivante) - Positionnée en bas pour ne JAMAIS cacher les prix
                      if (_currentPage < totalPages - 1)
                        Positioned(
                          right: 8,
                          bottom: 20,
                          child: _FloatingNavBtn(
                            icon: Icons.chevron_right_rounded,
                            onTap: () {
                              _flipKey.currentState?.flipForward();
                            },
                            iconColor: darkColor,
                            tooltip: 'Page suivante',
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Indicateurs à points dorés agrandis au swipe ─────────────
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0, top: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(totalPages, (index) {
                      final bool isCurrent = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrent ? 32 : 10,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isCurrent ? goldBright : const Color(0xFFC59B4B).withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isCurrent
                              ? [
                                  BoxShadow(
                                    color: goldBright.withValues(alpha: 0.55),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
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
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.92),
            border: Border.all(
              color: const Color(0xFFC59B4B).withValues(alpha: 0.6),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
      ),
    );
  }
}
