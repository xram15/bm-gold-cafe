import 'package:flutter/material.dart';
import 'page_model.dart';

class Book {
  final String id;
  final String title;
  final String iconEmoji;
  final Color color;
  final List<BookPage> pages;
  final String? imagePath; // chemin vers l'image de couverture dans assets

  const Book({
    required this.id,
    required this.title,
    required this.iconEmoji,
    required this.color,
    required this.pages,
    this.imagePath,
  });
}
