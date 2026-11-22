import 'dart:math';
import 'package:flutter/material.dart';
import '../../../data/models/book_model.dart';
import 'vertical_book_page.dart';
import 'page_curl_effect.dart';

class VerticalBookFlipView extends StatefulWidget {
  final Book book;
  final Function(int page)? onPageChanged;

  const VerticalBookFlipView({
    super.key,
    required this.book,
    this.onPageChanged,
  });

  @override
  VerticalBookFlipViewState createState() => VerticalBookFlipViewState();
}

class VerticalBookFlipViewState extends State<VerticalBookFlipView>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  int _currentPage = 0;
  bool _isFlipping = false;
  bool _isForward = true;

  // Suivi du geste tactile pour pliage interactif au doigt
  double _dragStartX = 0;
  double _dragProgress = 0; // 0..1
  bool _isDragging = false;

  int get pageCount => widget.book.pages.length;
  int get currentPage => _currentPage;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          if (_isForward) {
            _currentPage = (_currentPage + 1).clamp(0, pageCount - 1);
          } else {
            _currentPage = (_currentPage - 1).clamp(0, pageCount - 1);
          }
          _isFlipping = false;
          _isDragging = false;
          _dragProgress = 0;
          _controller.reset();
        });
        widget.onPageChanged?.call(_currentPage);
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isFlipping = false;
          _isDragging = false;
          _dragProgress = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flipForward() {
    if (_isFlipping || _currentPage >= pageCount - 1) return;
    setState(() {
      _isFlipping = true;
      _isForward = true;
      _dragProgress = 0;
    });
    _controller.forward(from: 0.0);
  }

  void flipBackward() {
    if (_isFlipping || _currentPage <= 0) return;
    setState(() {
      _isFlipping = true;
      _isForward = false;
      _dragProgress = 0;
    });
    _controller.forward(from: 0.0);
  }

  void _onDragStart(DragStartDetails details) {
    if (_isFlipping) return;
    _dragStartX = details.localPosition.dx;
    _isDragging = true;
    _dragProgress = 0;
  }

  void _onDragUpdate(DragUpdateDetails details, double bookWidth) {
    if (!_isDragging || _isFlipping) return;
    final delta = details.localPosition.dx - _dragStartX;

    if (delta < -5) {
      _isForward = true;
      if (_currentPage >= pageCount - 1) return;
      setState(() {
        _dragProgress = (-delta / (bookWidth * 0.88)).clamp(0.0, 0.96);
      });
    } else if (delta > 5) {
      _isForward = false;
      if (_currentPage <= 0) return;
      setState(() {
        _dragProgress = (delta / (bookWidth * 0.88)).clamp(0.0, 0.96);
      });
    }
  }

  void _onDragEnd(DragEndDetails details, double bookWidth) {
    if (!_isDragging) return;
    final velocity = details.primaryVelocity ?? 0;

    final bool shouldCommit =
        _dragProgress > 0.28 ||
        (_isForward && velocity < -200) ||
        (!_isForward && velocity > 200);

    if (shouldCommit && _dragProgress > 0.04) {
      setState(() {
        _isFlipping = true;
        _isDragging = false;
      });
      _controller.forward(from: _dragProgress);
    } else {
      setState(() {
        _isDragging = false;
        _dragProgress = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight;

        const double baseRatio = 1.48;
        final double targetRatio = maxW > 0
            ? min(baseRatio * 1.21, max(baseRatio, maxH / maxW))
            : baseRatio;
        final double bookWidth = max(0.0, min(maxW, maxH / targetRatio));
        final double bookHeight = bookWidth * targetRatio;

        return Center(
          child: SizedBox(
            width: bookWidth,
            height: bookHeight,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: (d) => _onDragUpdate(d, bookWidth),
              onHorizontalDragEnd: (d) => _onDragEnd(d, bookWidth),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  double turnProgress;
                  if (_isDragging) {
                    turnProgress = _dragProgress;
                  } else if (_isFlipping) {
                    turnProgress = _animation.value;
                  } else {
                    turnProgress = 0.0;
                  }

                  return _build3DCurlFlip(
                    bookWidth,
                    bookHeight,
                    turnProgress,
                    targetRatio,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // ── MOTEUR DE PLIAGE & ENROULEMENT DE PAGE (VERS L'EXTÉRIEUR, LA PAGE SE PLIE) ──
  // ===========================================================================
  Widget _build3DCurlFlip(
    double width,
    double height,
    double progress,
    double pageRatio,
  ) {
    final bool isAnimating = (_isFlipping || _isDragging) && progress > 0.001;

    // Si aucune animation, on affiche la page actuelle normalement à plat
    if (!isAnimating) {
      return _buildPageWidget(_currentPage, pageRatio);
    }

    final int targetPageIndex = _isForward
        ? (_currentPage + 1).clamp(0, pageCount - 1)
        : (_currentPage - 1).clamp(0, pageCount - 1);

    final bool isLight = widget.book.color.computeLuminance() > 0.5;
    final Color goldBorder = isLight
        ? const Color(0xFFB3894C)
        : const Color(0xFFCCA16C);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── 1. LA PAGE DE DESSOUS RÉVÉLÉE ───────────────────────────────────
        // Dévoilée au fur et à mesure que la feuille se soulève et se plie
        Positioned.fill(child: _buildPageWidget(targetPageIndex, pageRatio)),

        // ── 2. LA PAGE COURANTE DÉCOUPÉE LE LONG DU PLI COURBE ──────────────
        // La partie non encore pliée reste visible à gauche
        Positioned.fill(
          child: ClipPath(
            clipper: PageCurlClipper(
              turnProgress: progress,
              isForward: _isForward,
            ),
            child: _buildPageWidget(_currentPage, pageRatio),
          ),
        ),

        // ── 3. LA FEUILLE QUI SE PLIE VERS L'EXTÉRIEUR (COURBURE CYLINDRIQUE 3D) ─
        // Effet de rouleau de papier, crête de brillance lumineuse et ombre portée
        Positioned.fill(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(
                3,
                2,
                -0.0008,
              ) // Perspective 3D orientée vers l'EXTÉRIEUR (vers les yeux)
              ..scaleByDouble(
                1.0 + 0.035 * sin(progress * pi),
                1.0 + 0.035 * sin(progress * pi),
                1.0,
                1.0,
              ), // S'élève vers l'avant au sommet du tournage
            child: CustomPaint(
              painter: PageCurlPainter(
                turnProgress: progress,
                isForward: _isForward,
                pageColor: widget.book.color,
                goldColor: goldBorder,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPageWidget(int index, double pageRatio) {
    return FittedBox(
      fit: BoxFit.fill,
      child: SizedBox(
        width: 390,
        height: 390 * pageRatio,
        child: VerticalBookPage(
          book: widget.book,
          pageIndex: index,
          totalPages: pageCount,
        ),
      ),
    );
  }
}
