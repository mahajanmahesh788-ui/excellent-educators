import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
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

    return AuthFormCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reset your password',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Brand.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the email you use to sign in. Students and teachers can use this form.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Brand.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.25)),
                ),
                child: Text(
                  _message!,
                  style: const TextStyle(color: Color(0xFF2E7D32)),
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.25)),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send reset link'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go(RoutePaths.login),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
