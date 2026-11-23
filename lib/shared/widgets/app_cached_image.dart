import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class _MemoryImageCache {
  static final Map<String, Uint8List> _cache = {};

  static Uint8List? getBytes(String imagePath) {
    if (_cache.containsKey(imagePath)) return _cache[imagePath];
    try {
      final commaIdx = imagePath.indexOf(',');
      final base64Str = commaIdx != -1 ? imagePath.substring(commaIdx + 1) : imagePath;
      final bytes = base64Decode(base64Str);
      _cache[imagePath] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }
}

class AppCachedImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;

  const AppCachedImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final Widget fallback = placeholder ??
        Container(
          color: AppColors.surfaceDark,
          child: const Center(
            child: Icon(Icons.restaurant_rounded, color: AppColors.gold, size: 24),
          ),
        );

    // Support des images importées depuis le téléphone en data:image base64 avec mise en cache mémoire RAM
    if (imagePath.startsWith('data:image')) {
      final bytes = _MemoryImageCache.getBytes(imagePath);
      if (bytes != null) {
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          cacheWidth: width == null ? null : (width! * 2).round(),
          cacheHeight: height == null ? null : (height! * 2).round(),
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => fallback,
        );
      }
      return fallback;
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width == null ? null : (width! * 2).round(),
        cacheHeight: height == null ? null : (height! * 2).round(),
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.surfaceDark,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            ),
          );
        },
      );
    }

    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: width == null ? null : (width! * 2).round(),
      cacheHeight: height == null ? null : (height! * 2).round(),
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
