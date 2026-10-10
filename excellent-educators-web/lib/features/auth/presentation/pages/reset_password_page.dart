import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/core/navigation/app_navigation.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/auth_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({super.key, required this.email, required this.token});

  final String email;
  final String token;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  var _loading = false;
  var _obscure = true;
  String? _error;

  bool get _linkValid =>
      widget.email.trim().isNotEmpty && widget.token.trim().isNotEmpty;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_linkValid) {
      setState(() => _error = AppStrings.resetLinkInvalidOrExpired);
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            email: widget.email,
            token: widget.token,
            password: _password.text,
            passwordConfirmation: _confirm.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.passwordUpdatedYouCanSignInNow)),
      );
      goMenu(context, RoutePaths.login);
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);

    return Scaffold(
      backgroundColor: Brand.navyDeep,
      body: SelectionArea(
        child: AuthPageLayout(
          form: AuthFormCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.setNewPassword,
                    style: isMobile
                        ? const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Brand.ink,
                          )
                        : theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Brand.ink,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _linkValid
                        ? widget.email
                        : AppStrings.resetLinkInvalidOrExpired,
                    style: isMobile
                        ? TextStyle(
                            fontSize: 12.5,
                            color: _linkValid
                                ? Brand.muted
                                : theme.colorScheme.error,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          )
                        : theme.textTheme.bodyMedium?.copyWith(
                            color: _linkValid
                                ? Brand.muted
                                : theme.colorScheme.error,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                  SizedBox(height: isMobile ? 16 : 28),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    enabled: _linkValid,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: AppStrings.newPassword,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return AppStrings.useAtLeast8Characters;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirm,
                    obscureText: _obscure,
                    enabled: _linkValid,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: const InputDecoration(
                      labelText: AppStrings.confirmPassword,
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    validator: (value) {
                      if (value != _password.text) {
                        return AppStrings.passwordsDoNotMatch;
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: isMobile ? 12 : 13,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: isMobile ? 14 : 20),
                  FilledButton(
                    onPressed: (_loading || !_linkValid) ? null : _submit,
                    style: isMobile
                        ? FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                          )
                        : null,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.updatePassword),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: () => goMenu(context, RoutePaths.login),
                    style: isMobile
                        ? TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          )
                        : null,
                    child: const Text(AppStrings.backToSignIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
