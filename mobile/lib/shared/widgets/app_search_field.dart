import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction ?? TextInputAction.search,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      style: AppTextStyles.body.copyWith(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: hintText ?? 'Cari',
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary,
          fontSize: 15,
        ),
        filled: true,
        fillColor: AppColors.surface,
        prefixIcon: const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 14,
        ),
        border: _border(AppColors.border),
        enabledBorder: _border(AppColors.border),
        focusedBorder: _border(AppColors.primary, width: 1.4),
        errorBorder: _border(AppColors.danger, width: 1.4),
        focusedErrorBorder: _border(AppColors.danger, width: 1.4),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.large),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
