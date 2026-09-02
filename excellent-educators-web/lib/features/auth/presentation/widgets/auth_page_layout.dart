import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/app/theme/breakpoints.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/login_brand_panel.dart';
import 'package:flutter/material.dart';

class AuthPageLayout extends StatelessWidget {
  const AuthPageLayout({super.key, required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Brand.navyDeep, Brand.navy, Color(0xFF123456)],
        ),
      ),
      child: wide ? _WideAuthLayout(form: form) : _CompactAuthLayout(form: form),
    );
  }
}

class _WideAuthLayout extends StatelessWidget {
  const _WideAuthLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          flex: 11,
          child: LoginBrandPanel(compact: false),
        ),
        Expanded(
          flex: 9,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: form,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactAuthLayout extends StatelessWidget {
  const _CompactAuthLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const LoginBrandPanel(compact: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: form,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
