import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/pwa/pwa_install.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Login-page install CTA for phones that never show the browser banner.
class LoginInstallAppSection extends StatefulWidget {
  const LoginInstallAppSection({super.key, this.isMobile = false});

  final bool isMobile;

  @override
  State<LoginInstallAppSection> createState() => _LoginInstallAppSectionState();
}

class _LoginInstallAppSectionState extends State<LoginInstallAppSection> {
  bool _standalone = false;
  bool _canNativeInstall = false;
  bool _isIos = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;
    _refresh();
    pwaOnAvailable(() {
      if (!mounted) return;
      _refresh();
    });
  }

  void _refresh() {
    setState(() {
      _standalone = pwaIsStandalone();
      _canNativeInstall = pwaCanInstall();
      _isIos = pwaIsIos();
    });
  }

  Future<void> _onInstall() async {
    if (_busy) return;

    if (_canNativeInstall) {
      setState(() => _busy = true);
      final outcome = await pwaPromptInstall();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _canNativeInstall = pwaCanInstall();
        _standalone = pwaIsStandalone();
      });
      if (outcome == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.appInstalledThanks)),
        );
      }
      return;
    }

    if (_isIos) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(AppStrings.installApp),
          content: const Text(AppStrings.installAppIosSteps),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(AppStrings.gotIt),
            ),
          ],
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.installApp),
        content: const Text(AppStrings.installAppBrowserSteps),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(AppStrings.gotIt),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Install is only useful on phones; hide on laptop/desktop.
    if (!kIsWeb || _standalone || !widget.isMobile) {
      return const SizedBox.shrink();
    }

    final isMobile = widget.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: isMobile ? 18 : 22),
        Row(
          children: [
            Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.9))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                AppStrings.orLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted.withValues(alpha: 0.9),
                ),
              ),
            ),
            Expanded(child: Divider(color: AppColors.border.withValues(alpha: 0.9))),
          ],
        ),
        SizedBox(height: isMobile ? 14 : 16),
        Text(
          AppStrings.installAppHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 12.5 : 13,
            height: 1.35,
            color: AppColors.textSecondary.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: isMobile ? 44 : 46,
          child: OutlinedButton.icon(
            onPressed: _busy ? null : _onInstall,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: Text(
              AppStrings.installApp,
              style: TextStyle(
                fontSize: isMobile ? 13.5 : 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary, width: 1.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
