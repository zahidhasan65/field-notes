import 'package:flutter/material.dart';
import '../core/core.dart';

class SearchBox extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchBox({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.muted),
        ),
      );
}
