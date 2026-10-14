import 'dart:io';

import 'package:flutter/material.dart';

import 'avatar.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoPath;
  final double size;

  final bool onDark;

  const UserAvatar({
    super.key,
    required this.name,
    this.photoPath,
    this.size = 44,
    this.onDark = false,
  });

  Widget _initial() => onDark
      ? Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
          child: Text(
            name.isEmpty ? '?' : name[0].toUpperCase(),
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: size * 0.4),
          ),
        )
      : Avatar(name, size: size);

  @override
  Widget build(BuildContext context) {
    final path = photoPath;
    if (path == null) return _initial();
    return ClipOval(
      child: Image.file(
        File(path),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initial(),
      ),
    );
  }
}
