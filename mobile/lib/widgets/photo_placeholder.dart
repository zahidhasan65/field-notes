import 'dart:io';

import 'package:flutter/material.dart';

class PhotoPlaceholder extends StatelessWidget {
  final int index;
  final double? width, height;
  final double radius;
  const PhotoPlaceholder(this.index, {super.key, this.width, this.height, this.radius = 12});

  @override
  Widget build(BuildContext context) {
    const tints = [
      [Color(0xFFB9D3F3), Color(0xFF8FB4E3)],
      [Color(0xFFD5E4C3), Color(0xFFA9C98A)],
      [Color(0xFFF2DBB5), Color(0xFFE0B97C)],
    ];
    final t = tints[index.abs() % 3];
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(colors: t, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Icon(Icons.apartment, color: Colors.white.withOpacity(.85), size: (height ?? 60) * 0.45),
    );
  }
}

/// The note's photo (local file) or a placeholder when there is none.
class NotePhoto extends StatelessWidget {
  final String? path;
  final int seed;
  final double? width, height;
  final double radius;
  final BoxFit fit;

  const NotePhoto({
    super.key,
    required this.path,
    this.seed = 0,
    this.width,
    this.height,
    this.radius = 12,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = PhotoPlaceholder(seed, width: width, height: height, radius: radius);
    if (path == null) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.file(
        File(path!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => placeholder,
      ),
    );
  }
}
