import 'package:excellent_educators_web/app/di/providers.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/schedule/data/schedule_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(apiClientProvider));
});

final teacherScheduleDateProvider = StateProvider.autoDispose<String>((ref) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});

final teacherDayProvider = FutureProvider.autoDispose<ScheduleDayDto>((ref) {
  final date = ref.watch(teacherScheduleDateProvider);
  return ref.watch(scheduleRepositoryProvider).teacherDay(date);
});

final teacherDayScheduleDateProvider = StateProvider.autoDispose<String>((ref) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});

final teacherDayScheduleProvider = FutureProvider.autoDispose<ScheduleDayDto>((ref) {
  final date = ref.watch(teacherDayScheduleDateProvider);
  return ref.watch(scheduleRepositoryProvider).teacherDay(date);
});

final teacherLeavesProvider = FutureProvider.autoDispose<List<LeaveRequestDto>>((ref) {
  return ref.watch(scheduleRepositoryProvider).teacherLeaves();
});

final studentEligibilityProvider = FutureProvider.autoDispose<BookingEligibilityDto>((ref) {
  return ref.watch(scheduleRepositoryProvider).studentEligibility();
});

final studentBookingsProvider = FutureProvider.autoDispose<List<SessionBookingDto>>((ref) {
  return ref.watch(scheduleRepositoryProvider).studentBookings();
});

final studentBookingTeachersProvider = FutureProvider.autoDispose<List<TeacherDto>>((ref) {
  return ref.watch(scheduleRepositoryProvider).studentTeachers();
});

typedef StudentAvailabilityKey = ({String teacherId, String date});

final studentAvailabilityProvider =
    FutureProvider.autoDispose.family<ScheduleDayDto, StudentAvailabilityKey>((ref, key) {
  return ref.watch(scheduleRepositoryProvider).studentAvailability(
        teacherId: key.teacherId,
        date: key.date,
      );
});

final adminScheduleTeacherIdProvider = StateProvider<String?>((ref) => null);
final adminScheduleDateProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});

final adminScheduleTeachersProvider = FutureProvider.autoDispose<List<TeacherDto>>((ref) {
  return ref.watch(scheduleRepositoryProvider).adminTeachers();
});

final adminScheduleDayProvider = FutureProvider.autoDispose<ScheduleDayDto?>((ref) {
  final teacherId = ref.watch(adminScheduleTeacherIdProvider);
  final date = ref.watch(adminScheduleDateProvider);
  if (teacherId == null || teacherId.isEmpty) {
    return null;
  }
  return ref.watch(scheduleRepositoryProvider).adminDay(teacherId: teacherId, date: date);
});

final adminScheduleLeavesProvider = FutureProvider.autoDispose<List<LeaveRequestDto>>((ref) {
  final teacherId = ref.watch(adminScheduleTeacherIdProvider);
  return ref.watch(scheduleRepositoryProvider).adminLeaves(teacherId: teacherId);
});

final adminAllLeavesProvider = FutureProvider.autoDispose<List<LeaveRequestDto>>((ref) {
  return ref.watch(scheduleRepositoryProvider).adminLeaves();
});

final adminTeacherLeavesProvider =
    FutureProvider.autoDispose.family<List<LeaveRequestDto>, String>((ref, teacherId) {
  return ref.watch(scheduleRepositoryProvider).adminLeaves(teacherId: teacherId);
});

final adminLeaveRequestProvider =
    FutureProvider.autoDispose.family<LeaveRequestDto, String>((ref, groupId) {
  return ref.watch(scheduleRepositoryProvider).adminLeaveRequest(groupId);
});

final adminScheduleBookingsProvider = FutureProvider.autoDispose<List<SessionBookingDto>>((ref) {
  final teacherId = ref.watch(adminScheduleTeacherIdProvider);
  return ref.watch(scheduleRepositoryProvider).adminBookings(teacherId: teacherId);
});

final adminGoogleMeetProvider = FutureProvider.autoDispose<GoogleMeetConnectionDto>((ref) {
  return ref.watch(scheduleRepositoryProvider).adminGoogleMeet();
});

final adminTeacherAvailabilityProvider =
    FutureProvider.autoDispose.family<TeacherAvailabilityDto, String>((ref, teacherId) {
  return ref.watch(scheduleRepositoryProvider).adminTeacherAvailability(teacherId);
});

final adminAttendanceProvider = FutureProvider.autoDispose.family<List<AttendanceIssueDto>, String>((ref, status) {
  return ref.watch(scheduleRepositoryProvider).adminAttendanceIssues(status: status == 'all' ? null : status);
});

final adminPendingConflictsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final items = await ref.watch(scheduleRepositoryProvider).adminAttendanceIssues(status: 'pending');
  return items.length;
});
