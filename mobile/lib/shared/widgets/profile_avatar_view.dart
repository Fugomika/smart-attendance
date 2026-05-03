import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_text_styles.dart';

class ProfileAvatarView extends StatelessWidget {
  const ProfileAvatarView({
    required this.name,
    this.photoPath,
    this.size = 56,
    this.textStyle,
    super.key,
  });

  final String name;
  final String? photoPath;
  final double size;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.canvasNeutral,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        image: photoPath != null
            ? DecorationImage(
                image: FileImage(File(photoPath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: photoPath == null
          ? Text(
              initials,
              style:
                  textStyle ??
                  AppTextStyles.h3.copyWith(
                    color: AppColors.primary,
                    fontSize: size * 0.38,
                  ),
            )
          : null,
    );
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
