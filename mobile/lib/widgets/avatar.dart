import 'package:flutter/material.dart';

Color avatarColor(String s) {
  const colors = [
    Color(0xFF22A06B), Color(0xFF3B82F6), Color(0xFFEF6C47),
    Color(0xFF8B5CF6), Color(0xFFF59E0B), Color(0xFF0EA5A4),
  ];
  return colors[(s.isEmpty ? 0 : s.codeUnitAt(0)) % colors.length];
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  const Avatar(this.name, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final c = avatarColor(name);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c.withOpacity(.16), shape: BoxShape.circle),
      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
          style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: size * 0.4)),
    );
  }
}
