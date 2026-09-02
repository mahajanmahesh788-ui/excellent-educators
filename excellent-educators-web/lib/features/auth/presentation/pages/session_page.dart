import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/responsive_body.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SessionPage extends ConsumerWidget {
  const SessionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ExcellentEducators'),
        actions: [
          TextButton(
            onPressed: () => confirmSignOut(context, ref),
            child: const Text('Sign out'),
          ),
        ],
      ),
      body: SelectionArea(
        child: ResponsiveBody(
        maxWidth: 640,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Signed in', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Signed in. Use the navigation to open the screens for your role.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            if (user != null) ...[
              _InfoRow(label: 'Name', value: user.name),
              _InfoRow(label: 'Email', value: user.email),
              _InfoRow(label: 'Roles', value: user.roles.join(', ')),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
