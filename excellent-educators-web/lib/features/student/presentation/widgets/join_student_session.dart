import 'package:excellent_educators_web/core/constants/app_strings.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/presentation/providers/schedule_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> joinStudentSession(
  WidgetRef ref,
  SessionBookingDto booking,
) async {
  final updated = await ref
      .read(scheduleRepositoryProvider)
      .studentJoinClass(booking.id);
  ref.invalidate(studentBookingsProvider);
  final url = updated.meetingUrl ?? booking.meetingUrl;
  if (url != null && url.isNotEmpty) {
    await launchUrl(Uri.parse(url), webOnlyWindowName: AppStrings.blank);
  }
}
