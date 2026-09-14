import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/auth/data/dto/login_page_dtos.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/login_page_providers.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/auth_form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:excellent_educators_web/app/theme/breakpoints.dart';

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
    final theme = Theme.of(context);
    final isMobile = Breakpoints.isMobile(context);
    final content = ref.watch(loginPageContentProvider).maybeWhen(
          data: (value) => value,
          orElse: () => LoginPageContentDto.defaults,
        );

    return AuthFormCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content.formTitle,
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
              content.formSubtitle,
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
            ),
            SizedBox(height: isMobile ? 10 : 16),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Enter your password.';
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
                style: isMobile
                    ? TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )
                    : null,
                child: const Text('Forgot password?'),
              ),
            ),
            if (auth.error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.25)),
                ),
                child: Text(
                  auth.error!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: isMobile ? 12 : 13),
                ),
              ),
            ],
            SizedBox(height: isMobile ? 12 : 20),
            FilledButton(
              onPressed: auth.isLoading ? null : _submit,
              style: isMobile
                  ? FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(42),
                    )
                  : null,
              child: auth.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
