import 'category_model.dart';

/// ============================================================================
/// 📖 GUIDE DES 4 STYLES DE PAGES DU MENU
/// ============================================================================
/// Vous pouvez choisir parmi 4 styles différents pour chaque page :
///
/// 1. PageStyle.threeCircularBottom :
///    - Liste de produits en haut
///    - 3 médaillons photos circulaires en bas (avec noms et prix)
///
/// 2. PageStyle.singleLargeBottom :
///    - Liste de produits en haut
///    - 1 seule grande photo panoramique en bas (avec cartouche doré)
///
/// 3. PageStyle.alternatingPhotos :
///    - Alternance directe : Produit 1 -> Photo 1 -> Produit 2 -> Photo 2
///
/// 4. PageStyle.inlineThumbnailsTwoBottom :
///    - Produits avec petites vignettes photos intégrées à côté du prix
///    - 2 grandes photos au-dessous du texte
/// ============================================================================
enum PageStyle {
  /// STYLE 1 : 3 médaillons photos circulaires dorés en bas
  threeCircularBottom,

  /// STYLE 2 : 1 grande photo panoramique en bas
  singleLargeBottom,

  /// STYLE 3 : Alternance produit / photo horizontale / produit / 2ème photo horizontale
  alternatingPhotos,

  /// STYLE 4 : Produits avec vignettes photos (étoiles **) + 2 grandes photos en bas
  inlineThumbnailsTwoBottom,
}

enum BottomPhotoStyle {
  none,
  threeCircular,
  singleLarge,
}

enum PageLayoutType {
  textOnly,
  photoLeftProductsRight,
  productsLeftPhotoRight,
  photoAndText,
}

/// Modèle pour les médaillons circulaires en bas de page (Style 1)
class BottomPhoto {
  final String title;
  final String? price;
  final String imagePath;

  const BottomPhoto({
    required this.title,
    this.price,
    required this.imagePath,
  });
}

/// Modèle d'une page de menu
class BookPage {
  /// Le style choisi pour cette page (Style 1, Style 2, Style 3 ou Style 4)
  final PageStyle style;

  /// La catégorie contenant le titre de la page et la liste des produits
  final MenuCategory? category;

  /// 🌙 Photo dans le coin supérieur droit ("comme la lune")
  final String? cornerPhotoPath;

  // ── STYLE 1 : 3 photos circulaires en bas ──────────────────────────────────
  final List<BottomPhoto>? bottomPhotos;

  // ── STYLE 2 : 1 grande photo panoramique en bas ────────────────────────────
  final String? largeBottomPhotoPath;
  final String? largeBottomPhotoTitle;

  // ── STYLE 3 : Alternance Produit -> Photo 1 -> Produit -> Photo 2 ─────────
  final String? firstAlternatingPhotoPath;
  final String? firstAlternatingPhotoTitle;
  final String? secondAlternatingPhotoPath;
  final String? secondAlternatingPhotoTitle;

  // ── STYLE 4 : 2 grandes photos en bas (côte à côte ou en duo) ─────────────
  final String? secondBottomPhotoPath;
  final String? secondBottomPhotoTitle;

  // Champs de rétrocompatibilité
  final PageLayoutType layoutType;
  final BottomPhotoStyle bottomPhotoStyle;
  final String? mainPhotoPath;

  const BookPage({
    this.style = PageStyle.singleLargeBottom,
    this.category,
    this.cornerPhotoPath,
    this.bottomPhotos,
    this.largeBottomPhotoPath,
    this.largeBottomPhotoTitle,
    this.firstAlternatingPhotoPath,
    this.firstAlternatingPhotoTitle,
    this.secondAlternatingPhotoPath,
    this.secondAlternatingPhotoTitle,
    this.secondBottomPhotoPath,
    this.secondBottomPhotoTitle,
    this.layoutType = PageLayoutType.textOnly,
    this.bottomPhotoStyle = BottomPhotoStyle.singleLarge,
    this.mainPhotoPath,
  });

  BookPage copyWith({
    PageStyle? style,
    MenuCategory? category,
    String? cornerPhotoPath,
    List<BottomPhoto>? bottomPhotos,
    String? largeBottomPhotoPath,
    String? largeBottomPhotoTitle,
    String? firstAlternatingPhotoPath,
    String? firstAlternatingPhotoTitle,
    String? secondAlternatingPhotoPath,
    String? secondAlternatingPhotoTitle,
    String? secondBottomPhotoPath,
    String? secondBottomPhotoTitle,
    PageLayoutType? layoutType,
    BottomPhotoStyle? bottomPhotoStyle,
    String? mainPhotoPath,
  }) {
    return BookPage(
      style: style ?? this.style,
      category: category ?? this.category,
      cornerPhotoPath: cornerPhotoPath ?? this.cornerPhotoPath,
      bottomPhotos: bottomPhotos ?? this.bottomPhotos,
      largeBottomPhotoPath: largeBottomPhotoPath ?? this.largeBottomPhotoPath,
      largeBottomPhotoTitle: largeBottomPhotoTitle ?? this.largeBottomPhotoTitle,
      firstAlternatingPhotoPath: firstAlternatingPhotoPath ?? this.firstAlternatingPhotoPath,
      firstAlternatingPhotoTitle: firstAlternatingPhotoTitle ?? this.firstAlternatingPhotoTitle,
      secondAlternatingPhotoPath: secondAlternatingPhotoPath ?? this.secondAlternatingPhotoPath,
      secondAlternatingPhotoTitle: secondAlternatingPhotoTitle ?? this.secondAlternatingPhotoTitle,
      secondBottomPhotoPath: secondBottomPhotoPath ?? this.secondBottomPhotoPath,
      secondBottomPhotoTitle: secondBottomPhotoTitle ?? this.secondBottomPhotoTitle,
      layoutType: layoutType ?? this.layoutType,
      bottomPhotoStyle: bottomPhotoStyle ?? this.bottomPhotoStyle,
      mainPhotoPath: mainPhotoPath ?? this.mainPhotoPath,
    );
  }
}
