import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/app_colors.dart';
import '../../../core/app_text_styles.dart';
import '../../../data/models/book_model.dart';
import '../../../data/models/page_model.dart';
import '../../../data/models/product_model.dart';
import '../../../shared/widgets/app_cached_image.dart';

class VerticalBookPage extends StatelessWidget {
  final Book book;
  final int pageIndex;
  final int totalPages;

  const VerticalBookPage({
    super.key,
    required this.book,
    required this.pageIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    final BookPage? pageData = pageIndex < book.pages.length ? book.pages[pageIndex] : null;

    // ── Thème Noir, Gold & Blanc Impérial BM GOLD ────────────────────────────
    const Color pageBg = AppColors.bookBackground;
    const Color goldBorder = AppColors.gold;
    const Color textColor = AppColors.textWhite;
    const Color titleColor = AppColors.gold;
    const Color priceColor = AppColors.gold;
    const Color descColor = AppColors.textMuted;

    final String categoryTitle = pageData?.category?.title ?? book.title;
    final List<Product> products = pageData?.category?.products ?? [];

    return Container(
      decoration: BoxDecoration(
        color: pageBg,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
          topLeft: Radius.circular(2),
          bottomLeft: Radius.circular(2),
        ),
        boxShadow: [
          // Ombre 3D du livre vertical sur le fond clair
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(4, 14),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(1, 4),
          ),
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        child: Stack(
          children: [
            // ── 1. Reliure en cuir noir sur le bord gauche ───────────────
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 22,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  border: Border(
                    right: BorderSide(
                      color: goldBorder.withValues(alpha: 0.45),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    8,
                    (i) => Container(
                      width: 3,
                      height: 8,
                      decoration: BoxDecoration(
                        color: goldBorder.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── 2. Double bordure dorée festonnée (style menu d'orfèvre) ─
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(left: 20),
                child: CustomPaint(
                  painter: VerticalPageBorderPainter(
                    borderColor: goldBorder,
                  ),
                ),
              ),
            ),

            // ── 3. Contenu principal unifié (titre, texte, photos) ───────
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 14, right: 18, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // En-tête : Titre de catégorie, marge à droite pour laisser place au grand médaillon lune
                  Padding(
                    padding: const EdgeInsets.only(right: 94, left: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryTitle,
                          style: AppTextStyles.titleStyle.copyWith(
                            color: titleColor,
                            fontSize: 16,
                            letterSpacing: 1.6,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // Petite ligne ornementale dorée sous le titre
                        Row(
                          children: [
                            Container(width: 26, height: 1, color: goldBorder.withValues(alpha: 0.75)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(Icons.star, size: 7, color: goldBorder.withValues(alpha: 0.85)),
                            ),
                            Container(width: 26, height: 1, color: goldBorder.withValues(alpha: 0.75)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── CORPS DE PAGE : Adapté selon le STYLE choisi (SANS SCROLL) ─
                  Expanded(
                    child: _buildPageBodyByStyle(
                      style: pageData?.style ?? _deduceStyle(pageData),
                      pageData: pageData,
                      products: products,
                      textColor: textColor,
                      priceColor: priceColor,
                      descColor: descColor,
                      goldBorder: goldBorder,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ── Pied de page : Signature BM GOLD et pagination ───────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Page ${pageIndex + 1} / $totalPages',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          color: goldBorder.withValues(alpha: 0.75),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Container(width: 20, height: 1, color: goldBorder.withValues(alpha: 0.6)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              'BM GOLD',
                              style: TextStyle(
                                fontFamily: 'Svetze',
                                color: goldBorder,
                                fontSize: 11,
                                letterSpacing: 2.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(width: 20, height: 1, color: goldBorder.withValues(alpha: 0.6)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── 4. Photo en haut à droite dans le coin "comme la lune" ────
            Positioned(
              top: 10,
              right: 10,
              child: _buildMoonCornerPhoto(
                pageData: pageData,
                goldBorder: goldBorder,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Déduit le style par défaut si non spécifié
  PageStyle _deduceStyle(BookPage? pageData) {
    if (pageData?.bottomPhotoStyle == BottomPhotoStyle.threeCircular ||
        (pageData?.bottomPhotos != null && pageData!.bottomPhotos!.isNotEmpty)) {
      return PageStyle.threeCircularBottom;
    }
    return PageStyle.singleLargeBottom;
  }

  // ===========================================================================
  // ── SÉLECTEUR DU STYLE DE LA PAGE (SANS SCROLL) ───────────────────────────
  // ===========================================================================
  Widget _buildPageBodyByStyle({
    required PageStyle style,
    required BookPage? pageData,
    required List<Product> products,
    required Color textColor,
    required Color priceColor,
    required Color descColor,
    required Color goldBorder,
  }) {
    switch (style) {
      // ── STYLE 1 : Produits + 3 photos circulaires en bas ───────────────────
      case PageStyle.threeCircularBottom:
        return Column(
          children: [
            Expanded(
              child: _buildStandardProductList(
                products: products,
                textColor: textColor,
                priceColor: priceColor,
                descColor: descColor,
                goldBorder: goldBorder,
              ),
            ),
            const SizedBox(height: 6),
            _buildBottomDishesRow(
              pageData: pageData,
              goldBorder: goldBorder,
              textColor: textColor,
              priceColor: priceColor,
            ),
          ],
        );

      // ── STYLE 2 : Produits + 1 grande photo panoramique en bas ─────────────
      case PageStyle.singleLargeBottom:
        return Column(
          children: [
            Expanded(
              child: _buildStandardProductList(
                products: products,
                textColor: textColor,
                priceColor: priceColor,
                descColor: descColor,
                goldBorder: goldBorder,
              ),
            ),
            const SizedBox(height: 6),
            _buildLargeBottomPhoto(
              imagePath: pageData?.largeBottomPhotoPath ?? _getDefaultLargeBottomPhoto(),
              photoTitle: pageData?.largeBottomPhotoTitle,
              goldBorder: goldBorder,
              height: 94,
            ),
          ],
        );

      // ── STYLE 3 : Alternance Produit 1 / Photo 1 / Produit 2 / Photo 2 ─────
      case PageStyle.alternatingPhotos:
        return _buildAlternatingLayout(
          pageData: pageData,
          products: products,
          textColor: textColor,
          priceColor: priceColor,
          descColor: descColor,
          goldBorder: goldBorder,
        );

      // ── STYLE 4 : Vignettes inline + 2 grandes photos en bas ───────────────
      case PageStyle.inlineThumbnailsTwoBottom:
        return Column(
          children: [
            Expanded(
              child: _buildInlineThumbnailsProductList(
                products: products,
                textColor: textColor,
                priceColor: priceColor,
                descColor: descColor,
                goldBorder: goldBorder,
              ),
            ),
            const SizedBox(height: 6),
            _buildTwoBottomPhotosRow(
              pageData: pageData,
              goldBorder: goldBorder,
            ),
          ],
        );
    }
  }

  // ── STYLE 1 & 2 : Liste standard des produits (sans scroll) ───────────────
  Widget _buildStandardProductList({
    required List<Product> products,
    required Color textColor,
    required Color priceColor,
    required Color descColor,
    required Color goldBorder,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: products.map((prod) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      prod.name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: textColor,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Points de séparation dorés
                  Text(
                    ' ......... ',
                    style: TextStyle(
                      color: goldBorder.withValues(alpha: 0.45),
                      fontSize: 9.5,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    prod.price,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: priceColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
              if (prod.description != null && prod.description!.isNotEmpty) ...[
                const SizedBox(height: 1.0),
                Text(
                  prod.description!,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: descColor,
                    fontSize: 9.2,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── STYLE 3 : Alternance directe Produit / Photo / Produit / Photo ─────────
  Widget _buildAlternatingLayout({
    required BookPage? pageData,
    required List<Product> products,
    required Color textColor,
    required Color priceColor,
    required Color descColor,
    required Color goldBorder,
  }) {
    final Product? prod1 = products.isNotEmpty ? products[0] : null;
    final Product? prod2 = products.length > 1 ? products[1] : null;

    final String photo1 = pageData?.firstAlternatingPhotoPath ??
        pageData?.largeBottomPhotoPath ??
        _getDefaultLargeBottomPhoto();
    final String? title1 = pageData?.firstAlternatingPhotoTitle;

    final String photo2 = pageData?.secondAlternatingPhotoPath ??
        pageData?.secondBottomPhotoPath ??
        _getDefaultCornerPhoto();
    final String? title2 = pageData?.secondAlternatingPhotoTitle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 1. Premier Produit
        if (prod1 != null)
          _buildSingleProductItem(
            prod: prod1,
            textColor: textColor,
            priceColor: priceColor,
            descColor: descColor,
            goldBorder: goldBorder,
          ),

        // 2. Première grande photo horizontale
        _buildLargeBottomPhoto(
          imagePath: photo1,
          photoTitle: title1,
          goldBorder: goldBorder,
          height: 80,
        ),

        // 3. Deuxième Produit
        if (prod2 != null)
          _buildSingleProductItem(
            prod: prod2,
            textColor: textColor,
            priceColor: priceColor,
            descColor: descColor,
            goldBorder: goldBorder,
          ),

        // 4. Deuxième grande photo horizontale
        _buildLargeBottomPhoto(
          imagePath: photo2,
          photoTitle: title2,
          goldBorder: goldBorder,
          height: 80,
        ),
      ],
    );
  }

  Widget _buildSingleProductItem({
    required Product prod,
    required Color textColor,
    required Color priceColor,
    required Color descColor,
    required Color goldBorder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                prod.name.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              ' ......... ',
              style: TextStyle(
                color: goldBorder.withValues(alpha: 0.45),
                fontSize: 9.5,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              prod.price,
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: priceColor,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        if (prod.description != null && prod.description!.isNotEmpty) ...[
          const SizedBox(height: 1),
          Text(
            prod.description!,
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: descColor,
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ── STYLE 4 : Produits avec vignettes photo intégrées ─────────────────────
  Widget _buildInlineThumbnailsProductList({
    required List<Product> products,
    required Color textColor,
    required Color priceColor,
    required Color descColor,
    required Color goldBorder,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: products.map((prod) {
        final bool hasThumb = prod.imagePath != null && prod.imagePath!.isNotEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nom du produit
                  Expanded(
                    child: Text(
                      prod.name.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: textColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Vignette photo miniature dorée intégrée si présente
                  if (hasThumb) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: goldBorder, width: 1.1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: AppCachedImage(
                          imagePath: prod.imagePath!,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: AppColors.surfaceDark,
                            child: const Icon(Icons.star, size: 12, color: AppColors.gold),
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 4),
                  // Points de séparation
                  Text(
                    ' .... ',
                    style: TextStyle(
                      color: goldBorder.withValues(alpha: 0.45),
                      fontSize: 9.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    prod.price,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: priceColor,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (prod.description != null && prod.description!.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  prod.description!,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: descColor,
                    fontSize: 8.8,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── STYLE 4 : 2 Grandes photos horizontales en bas côte à côte ─────────────
  Widget _buildTwoBottomPhotosRow({
    required BookPage? pageData,
    required Color goldBorder,
  }) {
    final String photo1 = pageData?.largeBottomPhotoPath ?? _getDefaultLargeBottomPhoto();
    final String? title1 = pageData?.largeBottomPhotoTitle;

    final String photo2 = pageData?.secondBottomPhotoPath ?? _getDefaultCornerPhoto();
    final String? title2 = pageData?.secondBottomPhotoTitle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ligne ornementale dorée
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 32, height: 0.8, color: goldBorder.withValues(alpha: 0.55)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.diamond_outlined, size: 6.5, color: goldBorder.withValues(alpha: 0.85)),
            ),
            Container(width: 32, height: 0.8, color: goldBorder.withValues(alpha: 0.55)),
          ],
        ),
        const SizedBox(height: 5),

        // Les 2 photos côte à côte
        Row(
          children: [
            Expanded(
              child: _buildPhotoCard(
                imagePath: photo1,
                title: title1,
                goldBorder: goldBorder,
                height: 86,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _buildPhotoCard(
                imagePath: photo2,
                title: title2,
                goldBorder: goldBorder,
                height: 86,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoCard({
    required String imagePath,
    required String? title,
    required Color goldBorder,
    required double height,
  }) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: goldBorder.withValues(alpha: 0.85), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AppCachedImage(
              imagePath: imagePath,
              fit: BoxFit.cover,
            ),
            if (title != null && title.isNotEmpty)
              Positioned(
                bottom: 4,
                left: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: goldBorder.withValues(alpha: 0.7), width: 0.6),
                  ),
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: goldBorder,
                      fontSize: 7.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Photo coin supérieur droit "comme la lune" ─────────────────────────────
  Widget _buildMoonCornerPhoto({
    required BookPage? pageData,
    required Color goldBorder,
  }) {
    final String imagePath = pageData?.cornerPhotoPath ?? _getDefaultCornerPhoto();

    return Stack(
      alignment: Alignment.center,
      children: [
        // Halo croissant de lune doré agrandi
        CustomPaint(
          size: const Size(96, 96),
          painter: MoonCrescentPainter(goldColor: goldBorder),
        ),

        // Médaillon photo circulaire (82x82px) avec bordure dorée royale
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: goldBorder, width: 2.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: goldBorder.withValues(alpha: 0.35),
                blurRadius: 12,
                spreadRadius: 1.2,
              ),
            ],
          ),
          child: ClipOval(
            child: AppCachedImage(
              imagePath: imagePath,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Capsule dorée "CHEF" sur le bord inférieur
        Positioned(
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.0),
            decoration: BoxDecoration(
              color: const Color(0xFF161619),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: goldBorder.withValues(alpha: 0.9), width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.star, size: 8, color: AppColors.gold),
                SizedBox(width: 2.5),
                Text(
                  'BM GOLD',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    color: AppColors.gold,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDefaultCornerPhoto() {
    return 'assets/restaurant/cafe.png';
  }

  // ── Grande photo panoramique avec double encadrement doré & titre ──────────
  Widget _buildLargeBottomPhoto({
    required String imagePath,
    required String? photoTitle,
    required Color goldBorder,
    double height = 94,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fine ligne ornementale dorée de séparation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 32, height: 0.8, color: goldBorder.withValues(alpha: 0.55)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.diamond_outlined, size: 6.5, color: goldBorder.withValues(alpha: 0.85)),
            ),
            Container(width: 32, height: 0.8, color: goldBorder.withValues(alpha: 0.55)),
          ],
        ),
        const SizedBox(height: 5),

        Container(
          width: double.infinity,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: goldBorder.withValues(alpha: 0.85), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: goldBorder.withValues(alpha: 0.2),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AppCachedImage(
                  imagePath: imagePath,
                  fit: BoxFit.cover,
                ),

                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                        stops: const [0.4, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: goldBorder.withValues(alpha: 0.4),
                        width: 0.6,
                      ),
                    ),
                  ),
                ),

                if (photoTitle != null && photoTitle.isNotEmpty)
                  Positioned(
                    bottom: 5,
                    left: 8,
                    right: 8,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF101014).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: goldBorder.withValues(alpha: 0.85),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          photoTitle.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            color: goldBorder,
                            fontSize: 8.2,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDefaultLargeBottomPhoto() {
    return 'assets/restaurant/banner_pizza.jpg';
  }

  // ── STYLE 1 : Rangée de 3 photos circulaires agrandies (66px) ─────────────
  Widget _buildBottomDishesRow({
    required BookPage? pageData,
    required Color goldBorder,
    required Color textColor,
    required Color priceColor,
  }) {
    final List<BottomPhoto> photos = pageData?.bottomPhotos ?? _getDefaultBottomPhotos();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fine ligne ornementale dorée de séparation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 32, height: 0.8, color: goldBorder.withValues(alpha: 0.55)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(Icons.diamond_outlined, size: 6.5, color: goldBorder.withValues(alpha: 0.85)),
            ),
            Container(width: 32, height: 0.8, color: goldBorder.withValues(alpha: 0.55)),
          ],
        ),
        const SizedBox(height: 5),

        // Les 3 médaillons photos agrandis à 66x66px
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: photos.map((item) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Médaillon photo circulaire avec bordure dorée renforcée
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: goldBorder, width: 1.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: goldBorder.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: AppCachedImage(
                      imagePath: item.imagePath,
                      width: 66,
                      height: 66,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Capsule dorée pour le nom
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: goldBorder.withValues(alpha: 0.7), width: 0.8),
                    color: const Color(0xFF18181C),
                  ),
                  child: Text(
                    item.title,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: textColor,
                      fontSize: 7.8,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (item.price != null && item.price!.isNotEmpty) ...[
                  const SizedBox(height: 1.5),
                  Text(
                    item.price!,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: priceColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<BottomPhoto> _getDefaultBottomPhotos() {
    return const [
      BottomPhoto(title: 'MECHOUIA', price: '16 DT', imagePath: 'assets/restaurant/mechouia.jpg'),
      BottomPhoto(title: 'CÉSAR ROYAL', price: '22 DT', imagePath: 'assets/restaurant/salade.jfif'),
      BottomPhoto(title: 'TUNISIENNE', price: '14 DT', imagePath: 'assets/restaurant/mechouia.jpg'),
    ];
  }
}

// Peintre pour l'arc croissant de lune doré autour du médaillon
class MoonCrescentPainter extends CustomPainter {
  final Color goldColor;

  MoonCrescentPainter({required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    final paint = Paint()
      ..color = goldColor.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi * 0.72,
      pi * 0.95,
      false,
      paint,
    );

    final glowPaint = Paint()
      ..color = goldColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 2),
      pi * 0.78,
      pi * 0.85,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Peintre pour la double bordure festonnée
class VerticalPageBorderPainter extends CustomPainter {
  final Color borderColor;

  VerticalPageBorderPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const double m1 = 8.0;
    final r1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(m1, m1, size.width - (m1 * 2), size.height - (m1 * 2)),
      const Radius.circular(4),
    );
    canvas.drawRRect(r1, paint);

    paint.strokeWidth = 0.8;
    paint.color = borderColor.withValues(alpha: 0.65);
    const double m2 = 12.0;
    final r2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(m2, m2, size.width - (m2 * 2), size.height - (m2 * 2)),
      const Radius.circular(3),
    );
    canvas.drawRRect(r2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
