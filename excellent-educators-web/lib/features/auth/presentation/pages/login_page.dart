import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/auth_page_layout.dart';
import 'package:excellent_educators_web/features/auth/presentation/widgets/login_form_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Brand.navyDeep,
      body: SelectionArea(
        child: AuthPageLayout(form: const LoginFormCard()),
      ),
    );
  }
}
