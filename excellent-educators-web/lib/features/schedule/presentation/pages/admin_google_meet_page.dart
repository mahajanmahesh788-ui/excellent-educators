import 'package:excellent_educators_web/app/theme/app_theme.dart';
import 'package:excellent_educators_web/core/widgets/app_scaffold.dart';
import 'package:excellent_educators_web/core/widgets/portal_chrome.dart';
import 'package:excellent_educators_web/features/academic/presentation/widgets/academic_ui.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

class AdminGoogleMeetPage extends ConsumerWidget {
  const AdminGoogleMeetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const AppScaffold(
      title: AppStrings.googleMeet,
      body: AdminGoogleMeetConnectPanel(),
    );
  }
}

class AdminGoogleMeetConnectPanel extends ConsumerStatefulWidget {
  const AdminGoogleMeetConnectPanel({super.key});

  @override
  ConsumerState<AdminGoogleMeetConnectPanel> createState() => _AdminGoogleMeetConnectPanelState();
}

class _AdminGoogleMeetConnectPanelState extends ConsumerState<AdminGoogleMeetConnectPanel> {
  var _connecting = false;

  Future<void> _connect() async {
    setState(() => _connecting = true);
    try {
      final url = await ref.read(scheduleRepositoryProvider).adminGoogleMeetAuthorizeUrl();
      if (url.isEmpty) {
        throw Exception(AppStrings.googleDidNotReturnAnAuthorizationUrl);
      }
      await launchUrl(Uri.parse(url), webOnlyWindowName: AppStrings.blank);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.finishGoogleConsentThenTapRefreshStatus)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(adminGoogleMeetProvider);

    return AsyncBody(
      value: status,
      onRetry: () => ref.invalidate(adminGoogleMeetProvider),
      builder: (GoogleMeetConnectionDto data) {
        return ListView(
          children: [
            const PortalHero(
              title: AppStrings.connectGoogleMeet,
              subtitle: AppStrings.anAdminAuthorizesGoogleOnceAfterThatEachTeacherAnd,
            ),
            const SizedBox(height: 16),
            PortalCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.connected ? AppStrings.connected : AppStrings.notConnected,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: data.connected ? const Color(0xFF0F766E) : Brand.navy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.connected
                        ? AppStrings.bookingsCanCreateGoogleMeetRoomsAutomatically
                        : AppStrings.clickConnectGoogleSignInWithTheSchoolGoogleAccount,
                    style: const TextStyle(height: 1.5, color: Color(0xFF475569)),
                  ),
                  if ((data.googleEmail ?? '').isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(data.googleEmail!, style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      PortalButton(
                        label: data.connected ? AppStrings.reconnectGoogle : AppStrings.connectGoogle,
                        busy: _connecting,
                        onPressed: _connecting ? null : _connect,
                      ),
                      PortalButton(
                        label: AppStrings.refreshStatus,
                        outlined: true,
                        onPressed: () => ref.invalidate(adminGoogleMeetProvider),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
