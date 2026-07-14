import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Uppercase section label with an optional trailing action ("See All",
/// a filter, etc). Used above list/grid sections across the app.
class SectionHeader extends StatelessWidget {
  const SectionHeader({required this.title, this.trailing, this.icon, super.key});

  final String title;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (icon != null) ...<Widget>[
          Icon(icon, size: 16, color: AppColors.gold),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(title.toUpperCase(), style: AppTextStyles.label),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
