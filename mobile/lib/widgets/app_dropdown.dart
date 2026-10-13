import 'package:flutter/material.dart';
import 'field_label.dart';

class AppDropdown<T> extends StatelessWidget {
  final String label, hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isRequired;

  const AppDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FieldLabel(label, isRequired: isRequired),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            isExpanded: true,
            onChanged: onChanged,
            hint: Text(hint, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            validator: isRequired ? (v) => v == null ? 'Required' : null : null,
          ),
        ]),
      );
}
