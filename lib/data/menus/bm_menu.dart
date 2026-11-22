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
      secondAlternatingPhotoPath: 'assets/petit_dejeuner/dish_croissant.jpg',
      category: MenuCategory(
        title: 'PETIT DÉJEUNER & BRUNCH',
        products: <Product>[],
      ),
    ),


    // -------------------------------------------------------------------------
    // PAGE 2 : THÉ & INFUSIONS
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.sectionsWithBackground,
      cornerPhotoPath: 'assets/restaurant/cafe.png',
      backgroundImagePath: 'assets/the-back.jpg',
      category: MenuCategory(
        title: 'THÉ & INFUSIONS',
        products: <Product>[],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 3 : CAFÉ & BOISSONS CHAUDES (MULTI-SECTIONS AVEC BACKGROUND)
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.sectionsWithBackground,
      cornerPhotoPath: 'assets/restaurant/cafe.png',
      backgroundImagePath: 'assets/coffee_bg.jpg',
      category: MenuCategory(
        title: 'CAFÉ & BOISSONS CHAUDES',
        products: <Product>[
          // Section 1 : CAFÉ
          Product(name: 'Express', price: '2.800', section: 'Café'),
          Product(name: 'Américain', price: '2.800', section: 'Café'),
          Product(name: 'Cappucin nescafé', price: '2.900', section: 'Café'),
          Product(name: 'Direct', price: '3.000', section: 'Café'),
          Product(name: 'Direct nescafé', price: '3.000', section: 'Café'),

          // Section 2 : CAFÉ SPÉCIAL
          Product(name: 'Express spéciale', price: '3.500', section: 'Café Spécial'),
          Product(name: 'Cappucin Spéciale', price: '3.800', section: 'Café Spécial'),
          Product(name: 'Direct spéciale', price: '4.000', section: 'Café Spécial'),
          Product(name: 'Américain spécial', price: '3.700', section: 'Café Spécial'),

          // Section 3 : EXPRESSO (LAVAZZA)
          Product(name: 'Express', price: '3.600', section: 'Expresso (LAVAZZA)'),
          Product(name: 'Cappucin', price: '4.000', section: 'Expresso (LAVAZZA)'),
          Product(name: 'Direct', price: '4.500', section: 'Expresso (LAVAZZA)'),

          // Section 4 : CHOCOLAT
          Product(name: 'Chocolat au lait', price: '2.900', section: 'Chocolat'),
          Product(name: 'Chocolat chaud', price: '4.500', section: 'Chocolat'),
          Product(name: 'Chocolat chaud chantilly', price: '5.300', section: 'Chocolat'),
        ],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 4 : JUS FRAIS
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.singleLargeBottom,
      cornerPhotoPath: 'assets/restaurant/cafe.png',
      backgroundImagePath: 'assets/jus-back.jpg',
      largeBottomPhotoPath: 'assets/restaurant/cat_boissons.png',
      category: MenuCategory(
        title: 'JUS FRAIS',
        products: <Product>[],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 5 : COCKTAILS & MOJITOS
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.spacedWithBackgroundTwoBottomPhotos,
      cornerPhotoPath: 'assets/restaurant/cafe.png',
      backgroundImagePath: 'assets/coctail-back.jpg',
      largeBottomPhotoPath: 'assets/restaurant/cat_boissons.png',
      secondBottomPhotoPath: 'assets/restaurant/cafe.png',
      category: MenuCategory(
        title: 'COCTAILS & MOJITOS',
        products: <Product>[],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 6 : CHICHA NORMALE
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.spacedWithBackgroundTwoBottomPhotos,
      cornerPhotoPath: 'assets/restaurant/cat_shisha.jfif',
      backgroundImagePath: 'assets/chicha-back.jpg',
      largeBottomPhotoPath: 'assets/restaurant/cat_shisha.jfif',
      secondBottomPhotoPath: 'assets/restaurant/cat_shisha.jfif',
      category: MenuCategory(
        title: 'CHICHA NORMALE',
        products: <Product>[],
      ),
    ),

    // -------------------------------------------------------------------------
    // PAGE 7 : CHICHA QUASAR & SPÉCIALE
    // -------------------------------------------------------------------------
    BookPage(
      style: PageStyle.spacedWithBackgroundTwoBottomPhotos,
      cornerPhotoPath: 'assets/restaurant/cat_shisha.jfif',
      backgroundImagePath: 'assets/quasar-back.jpg',
      largeBottomPhotoPath: 'assets/restaurant/cat_shisha.jfif',
      secondBottomPhotoPath: 'assets/restaurant/cat_shisha.jfif',
      category: MenuCategory(
        title: 'CHICHA QUASAR',
        products: <Product>[],
      ),
    ),
  ],
);
