import 'package:flutter/material.dart';
import '../models/book_model.dart';
import '../models/page_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

// =============================================================================
// 👑 MENU UNIQUE BM GOLD - CAFÉ LOUNGE (THÈME NOIR, GOLD & BLANC)
// =============================================================================
// 📁 Couverture : assets/bm.png
// 🎨 Thème : Noir profond, Or étincelant & Blanc pur
// 📋 Les produits sont désormais gérés et saisis en direct depuis l'espace Admin.
// =============================================================================

const Book bmMenu = Book(
  id: 'bm',
  title: 'BM GOLD',
  iconEmoji: '👑',
  color: Color(0xFF141414), // Noir absolu & luxueux
  imagePath: 'assets/bm.png',
  pages: [
    // -------------------------------------------------------------------------
    // PAGE 1 : PETIT DÉJEUNER & BRUNCH GOURMET
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.alternatingPhotos,
      cornerPhotoPath: 'assets/petit_dejeuner/gourmet_breakfast.jpg',
      firstAlternatingPhotoPath: 'assets/petit_dejeuner/banner_breakfast.jpg',
      firstAlternatingPhotoTitle: 'LE GRAND BRUNCH ROYAL CONTINENTAL',
      secondAlternatingPhotoPath: 'assets/petit_dejeuner/dish_croissant.jpg',
      secondAlternatingPhotoTitle: 'CROISSANTS PUR BEURRE ARTISANAUX',
      category: MenuCategory(
        title: 'PETIT DÉJEUNER & BRUNCH',
        products: <Product>[],
      ),
    ),


    // -------------------------------------------------------------------------
    // PAGE 2 : Thé 
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.singleLargeBottom,
      cornerPhotoPath: 'assets/restaurant/cafe.png',
      largeBottomPhotoPath: 'assets/restaurant/cat_boissons.png',
      largeBottomPhotoTitle: "L'ÉTHIQUE DU THE",
      category: MenuCategory(
        title: 'Thé',
        products: <Product>[],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 3 : Café & Boissons Chaudes
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.singleLargeBottom,
      cornerPhotoPath: 'assets/restaurant/cafe.png',
      largeBottomPhotoPath: 'assets/restaurant/cat_boissons.png',
      largeBottomPhotoTitle: "L'ÉTHIQUE DU CAFÉ",
      category: MenuCategory(
        title: 'Café & Boissons Chaudes',
        products: <Product>[],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 4 : JUS 
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.singleLargeBottom,
      cornerPhotoPath: 'assets/restaurant/cafe.png',
      largeBottomPhotoPath: 'assets/restaurant/cat_boissons.png',
      largeBottomPhotoTitle: "L'ÉTHIQUE DU JUS FRAIS",
      category: MenuCategory(
        title: 'JUS FRAIS',
        products: <Product>[],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 4 : COCTAILS & MOJITOS
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.singleLargeBottom,
      cornerPhotoPath: 'assets/restaurant/cafe.png',
      largeBottomPhotoPath: 'assets/restaurant/cat_boissons.png',
      largeBottomPhotoTitle: "Coctails",
      category: MenuCategory(
        title: 'COCTAILS & MOJITOS',
        products: <Product>[],
      ),
    ),
    // -------------------------------------------------------------------------
    // PAGE 5 : PASTA & RISOTTO
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.singleLargeBottom,
      cornerPhotoPath: 'assets/restaurant/pasta.jfif',
      largeBottomPhotoPath: 'assets/restaurant/pasta.jfif',
      largeBottomPhotoTitle: 'PASTA FRESCA & RISOTTO NOBLE',
      category: MenuCategory(
        title: 'PASTA & RISOTTO',
        products: <Product>[],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 9 : CHICHA WOOKAH & ESPACE LOUNGE
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.singleLargeBottom,
      cornerPhotoPath: 'assets/restaurant/cat_shisha.jfif',
      largeBottomPhotoPath: 'assets/restaurant/cat_shisha.jfif',
      largeBottomPhotoTitle: 'EXPÉRIENCE CHICHA WOOKAH',
      category: MenuCategory(
        title: 'CHICHA & LOUNGE',
        products: <Product>[],
      ),
    ),
  ],
);
