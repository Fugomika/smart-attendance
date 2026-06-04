import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_radius.dart';
import '../../../../app/theme/app_spacing.dart';

class AdminFilterDropdown<T> extends StatelessWidget {
  const AdminFilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
    this.leadingIcon,
    super.key,
  });

  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
            ),
            items: items.map((item) {
              if (leadingIcon == null) {
                return item;
              }

              return DropdownMenuItem<T>(
                value: item.value,
                child: Row(
                  children: [
                    Icon(leadingIcon, size: 20, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: item.child),
                  ],
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
