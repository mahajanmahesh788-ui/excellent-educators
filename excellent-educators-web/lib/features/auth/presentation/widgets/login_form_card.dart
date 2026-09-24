import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_colors.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginFormCard extends ConsumerStatefulWidget {
  const LoginFormCard({super.key});

  @override
  ConsumerState<LoginFormCard> createState() => _LoginFormCardState();
}

class _LoginFormCardState extends ConsumerState<LoginFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await ref.read(authControllerProvider.notifier).login(
          email: _email.text.trim(),
          password: _password.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final isMobile = Breakpoints.isMobile(context);
    final content = ref.watch(loginPageContentProvider).maybeWhen(
          data: (value) => value,
          orElse: () => LoginPageContentDto.defaults,
        );

    final formTitle = content.formTitle.isNotEmpty
        ? (content.formTitle == 'Welcome back'
            ? 'Welcome back 👋'
            : content.formTitle)
        : 'Welcome back 👋';

    final formSubtitle = content.formSubtitle.isNotEmpty
        ? (content.formSubtitle.startsWith('Sign in to track')
            ? 'Continue your learning journey.'
            : content.formSubtitle)
        : 'Continue your learning journey.';

    return AuthFormCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              formTitle,
              style: TextStyle(
                fontSize: isMobile ? 22 : 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Text(
              formSubtitle,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            SizedBox(height: isMobile ? 18 : 26),

            // Email field
            Text(
              AppStrings.email,
              style: TextStyle(
                fontSize: isMobile ? 12.5 : 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              style: TextStyle(
                fontSize: isMobile ? 14 : 14.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'student@example.com',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: isMobile ? 12 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppStrings.enterYourEmail;
                }
                if (!value.contains('@')) {
                  return AppStrings.enterAValidEmail;
                }
                return null;
              },
            ),
            SizedBox(height: isMobile ? 12 : 16),

            // Password field
            Text(
              AppStrings.password,
              style: TextStyle(
                fontSize: isMobile ? 12.5 : 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 5),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              style: TextStyle(
                fontSize: isMobile ? 14 : 14.5,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.canvas,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: isMobile ? 12 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                ),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.enterYourPassword;
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.go(RoutePaths.forgotPassword),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  AppStrings.forgotPassword,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryMid,
                  ),
                ),
              ),
            ),

            // Error display
            if (auth.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.dangerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.dangerBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        auth.error!,
                        style: const TextStyle(
                          color: AppColors.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: isMobile ? 16 : 22),

            // [ Sign In ] Primary Button
            SizedBox(
              height: isMobile ? 46 : 50,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: auth.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        AppStrings.signIn,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
