import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_names.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radius.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/constants/app_assets.dart';
import '../../../shared/widgets/app_system_overlay.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSystemOverlay.lightIcons(
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primary, AppColors.success],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final topGap = (constraints.maxHeight * 0.12).clamp(
                  AppSpacing.lg,
                  72.0,
                );
                final actionGap = (constraints.maxHeight * 0.12).clamp(
                  AppSpacing.xl,
                  88.0,
                );

                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: topGap),
                          Image.asset(
                            AppAssets.logo,
                            width: 88,
                            height: 88,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Smart\nAttendance',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.h1.copyWith(
                              color: AppColors.surface,
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Presensi cerdas dengan\nselfie dan lokasi real-time',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.surface,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.45,
                            ),
                          ),
                          SizedBox(height: actionGap),
                          _WelcomeActionButton(
                            label: 'Masuk',
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primary,
                            borderColor: AppColors.surface,
                            onPressed: () => context.go(RouteNames.login),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _WelcomeActionButton(
                            label: 'Daftar',
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.surface,
                            borderColor: AppColors.surface,
                            onPressed: () => context.go(RouteNames.register),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeActionButton extends StatelessWidget {
  const _WelcomeActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          textStyle: AppTextStyles.h2.copyWith(
            color: foregroundColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            side: BorderSide(color: borderColor, width: 2),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
