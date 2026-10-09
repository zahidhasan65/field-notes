import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.asset(
          'assets/images/field_notes_app_logo_v2.png',
          height: 66,
          width: 66,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 5),
        Text('Field Notes', style: AppTextStyles.title.copyWith(fontSize: 20)),
      ],
    );
  }
}
