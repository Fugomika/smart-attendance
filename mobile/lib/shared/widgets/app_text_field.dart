import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.errorText,
    this.keyboardType,
    this.onChanged,
    this.isSearch = false,
    this.autofillHints,
    this.autocorrect = false,
    this.enableSuggestions = false,
    this.textInputAction,
    this.onSubmitted,
    this.minLines,
    this.maxLines,
    this.maxLength,
    this.showCounter = true,
    super.key,
  });

  final TextEditingController? controller;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? errorText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool isSearch;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final bool enableSuggestions;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSearch ? Colors.transparent : AppColors.textSecondary;
    final focusedColor = isSearch ? Colors.transparent : AppColors.primary;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      minLines: obscureText ? null : minLines,
      maxLines: obscureText ? 1 : maxLines ?? 1,
      maxLength: maxLength,
      keyboardType: keyboardType,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      autofillHints: autofillHints,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
      style: AppTextStyles.body.copyWith(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textMuted,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        counterStyle: AppTextStyles.caption.copyWith(
          color: AppColors.textMuted,
        ),
        counterText: showCounter ? null : '',
        errorText: errorText,
        filled: true,
        fillColor: isSearch ? AppColors.canvasNeutral : AppColors.surface,
        prefixIcon: prefixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(
                  prefixIcon,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: suffixIcon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: IconTheme(
                  data: const IconThemeData(
                    color: AppColors.textSecondary,
                    size: 22,
                  ),
                  child: suffixIcon!,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 16,
        ),
        border: _border(borderColor),
        enabledBorder: _border(borderColor),
        focusedBorder: _border(focusedColor, width: 1.5),
        errorBorder: _border(AppColors.danger, width: 1.5),
        focusedErrorBorder: _border(AppColors.danger, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1.0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.large),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
