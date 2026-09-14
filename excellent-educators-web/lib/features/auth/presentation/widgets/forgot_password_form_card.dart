import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ForgotPasswordFormCard extends ConsumerStatefulWidget {
  const ForgotPasswordFormCard({super.key});

  @override
  ConsumerState<ForgotPasswordFormCard> createState() => _ForgotPasswordFormCardState();
}

class _ForgotPasswordFormCardState extends ConsumerState<ForgotPasswordFormCard> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  var _loading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).forgotPassword(_email.text.trim());
      setState(() {
        _message = 'If that email exists, a password reset link has been sent.';
      });
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

    return AuthFormCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reset your password',
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
              'Enter the email you use to sign in. Students and teachers can use this form.',
              style: isMobile
                  ? const TextStyle(
                      fontSize: 12.5,
                      color: Brand.muted,
                      height: 1.35,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: Brand.muted,
                      height: 1.45,
                    ),
            ),
            SizedBox(height: isMobile ? 16 : 28),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter your email.';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(color: const Color(0xFF2E7D32), fontSize: isMobile ? 12 : 13),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.25)),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: isMobile ? 12 : 13),
                ),
              ),
            ],
            SizedBox(height: isMobile ? 14 : 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
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
                  : const Text('Send reset link'),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => context.go(RoutePaths.login),
              style: isMobile
                  ? TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    )
                  : null,
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
