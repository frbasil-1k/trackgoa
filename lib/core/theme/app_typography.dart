import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const _base = TextStyle(color: AppColors.textPrimary);
  static final textTheme = TextTheme(
    displaySmall: _base.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
    headlineSmall: _base.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
    titleMedium: _base.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
    bodyMedium: _base.copyWith(fontSize: 15, height: 1.4),
    bodySmall: _base.copyWith(
      fontSize: 13,
      height: 1.35,
      color: AppColors.textSecondary,
    ),
    labelMedium: _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
  );
}
