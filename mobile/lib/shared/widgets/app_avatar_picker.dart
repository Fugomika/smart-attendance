import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_text_styles.dart';
import '../utils/app_snack_bar.dart';

class AppAvatarPicker extends StatelessWidget {
  const AppAvatarPicker({
    required this.imagePath,
    required this.onChanged,
    this.size = 96,
    this.label,
    super.key,
  });

  final String? imagePath;
  final ValueChanged<String?> onChanged;
  final double size;
  final String? label;

  static final ImagePicker _picker = ImagePicker();

  Future<void> _pick(BuildContext context, ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked != null) {
        onChanged(picked.path);
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.error(context, 'Gagal mengambil foto. Coba lagi.');
      }
    }
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                _SheetTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Ambil dari kamera',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pick(context, ImageSource.camera);
                  },
                ),
                _SheetTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Pilih dari galeri',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pick(context, ImageSource.gallery);
                  },
                ),
                if (imagePath != null)
                  _SheetTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Hapus foto',
                    color: AppColors.danger,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onChanged(null);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _openSheet(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.softBlue,
                  border: Border.all(color: AppColors.border, width: 1.5),
                  image: imagePath != null
                      ? DecorationImage(
                          image: FileImage(File(imagePath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imagePath == null
                    ? const Icon(
                        Icons.person_outline_rounded,
                        size: 48,
                        color: AppColors.primary,
                      )
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.surface,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            label!,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.textPrimary;
    return ListTile(
      leading: Icon(icon, color: tileColor),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: tileColor,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
