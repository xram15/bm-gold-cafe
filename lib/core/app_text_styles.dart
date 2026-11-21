import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Police Svetze pour la marque BM GOLD
  static const TextStyle brandStyle = TextStyle(
    fontFamily: 'Svetze',
    color: AppColors.gold,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 5.0,
  );

  // Titres des catégories (Entrées, Pizzas, etc.) en Or impérial
  static TextStyle titleStyle = GoogleFonts.playfairDisplay(
    color: AppColors.gold,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.8,
  );

  // Nom des produits en Blanc pur éclatant pour une lisibilité parfaite
  static TextStyle itemNameStyle = GoogleFonts.montserrat(
    color: AppColors.textWhite,
    fontSize: 12.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  // Prix en Or étincelant
  static TextStyle priceStyle = GoogleFonts.montserrat(
    color: AppColors.gold,
    fontSize: 13,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.4,
  );

  // Descriptions fines en Blanc doux / nacré
  static TextStyle descriptionStyle = GoogleFonts.montserrat(
    color: AppColors.textMuted,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );
}
