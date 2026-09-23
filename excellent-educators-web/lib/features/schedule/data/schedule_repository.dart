import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/maps_api_failures.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';

class ScheduleRepository with MapsApiFailures {
  ScheduleRepository(this._client);

  final ApiClient _client;

  Future<ScheduleDayDto> teacherDay(String date) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.teacherScheduleDay, query: {'date': date});
      return ScheduleDayDto.fromJson(json!);
    });
  }

  Future<List<ScheduleDayDto>> teacherWeek(String start) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.teacherScheduleWeek, query: {'start': start});
      final days = json?['days'] as List<dynamic>? ?? const [];
      return days
          .whereType<Map>()
          .map((item) => ScheduleDayDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<List<ScheduleMonthDayDto>> teacherMonth(int year, int month) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.teacherScheduleMonth, query: {
        'year': year.toString(),
        'month': month.toString(),
      });
      return (json?['days'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ScheduleMonthDayDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<void> saveTeacherBreaks({String? breakfastStart, String? lunchStart}) {
    return runApi(() => _client.put(ApiEndpoints.teacherScheduleBreaks, data: {
          'breakfast_start': breakfastStart,
          'lunch_start': lunchStart,
        }));
  }

  Future<void> takeLeave({
    required String date,
    required bool isFullDay,
    required String reason,
    List<String>? slotStarts,
    String? startTime,
    String? endTime,
  }) {
    return runApi(() => _client.post(ApiEndpoints.teacherScheduleLeaves, data: {
          'date': date,
          'is_full_day': isFullDay,
          'reason': reason,
          if (slotStarts != null) 'slot_starts': slotStarts,
          if (startTime != null) 'start_time': startTime,
          if (endTime != null) 'end_time': endTime,
        }));
  }

  Future<void> deleteTeacherLeave(String id) {
    return runApi(() => _client.delete(ApiEndpoints.teacherScheduleLeave(id)));
  }

  Future<List<ScheduleLeaveDto>> teacherLeaves() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.teacherScheduleLeaves);
      return items
          .whereType<Map>()
          .map((item) => ScheduleLeaveDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<BookingEligibilityDto> studentEligibility() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.studentBookingEligibility);
      return BookingEligibilityDto.fromJson(json!);
    });
  }

  Future<List<TeacherDto>> studentTeachers() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.studentBookingTeachers);
      return items
          .whereType<Map>()
          .map((item) => TeacherDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<ScheduleDayDto> studentAvailability({required String teacherId, required String date}) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.studentBookingAvailability, query: {
        'teacher_id': teacherId,
        'date': date,
      });
      return ScheduleDayDto.fromJson(json!);
    });
  }

  Future<List<SessionBookingDto>> studentBookings() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.studentBookings);
      return items
          .whereType<Map>()
          .map((item) => SessionBookingDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<SessionBookingDto> createStudentBooking({
    required String teacherId,
    required String type,
    required String date,
    required String start,
  }) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.studentBookings, data: {
        'teacher_id': teacherId,
        'type': type,
        'date': date,
        'start': start,
      });
      return SessionBookingDto.fromJson(json!);
    });
  }

  Future<SessionBookingDto> rescheduleStudentBooking({
    required String bookingId,
    required String teacherId,
    required String date,
    required String start,
  }) {
    return runApi(() async {
      final json = await _client.put(ApiEndpoints.studentBooking(bookingId), data: {
        'teacher_id': teacherId,
        'date': date,
        'start': start,
      });
      return SessionBookingDto.fromJson(json!);
    });
  }

  Future<SessionBookingDto> studentJoinClass(String bookingId) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.studentBookingJoin(bookingId));
      return SessionBookingDto.fromJson(json!);
    });
  }

  Future<SessionBookingDto> studentReportTeacher(String bookingId, String message) {
    return runApi(() async {
      final json = await _client.post(
        ApiEndpoints.studentBookingAttendanceReport(bookingId),
        data: {'message': message},
      );
      return SessionBookingDto.fromJson(json!);
    });
  }

  Future<SessionBookingDto> teacherJoinClass(String bookingId) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.teacherBookingJoin(bookingId));
      return SessionBookingDto.fromJson(json!);
    });
  }

  Future<SessionBookingDto> teacherReportStudent(String bookingId, String message) {
    return runApi(() async {
      final json = await _client.post(
        ApiEndpoints.teacherBookingAttendanceReport(bookingId),
        data: {'message': message},
      );
      return SessionBookingDto.fromJson(json!);
    });
  }

  Future<TeacherWhatsAppDto> teacherWhatsAppStudent(String bookingId) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.teacherBookingWhatsApp(bookingId));
      return TeacherWhatsAppDto.fromJson(json!);
    });
  }

  Future<List<AttendanceIssueDto>> adminAttendanceIssues({String? status}) {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.adminAttendance,
        query: {if (status != null) 'status': status},
      );
      return items
          .whereType<Map>()
          .map((item) => AttendanceIssueDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<AttendanceIssueDto> adminResolveAttendance({
    required String id,
    required String decision,
    String? notes,
  }) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.adminAttendanceResolve(id), data: {
        'decision': decision,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      });
      return AttendanceIssueDto.fromJson(json!);
    });
  }

  Future<List<TeacherDto>> adminTeachers() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.adminScheduleTeachers);
      return items
          .whereType<Map>()
          .map((item) => TeacherDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<ScheduleDayDto> adminDay({required String teacherId, required String date}) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminScheduleDay, query: {
        'teacher_id': teacherId,
        'date': date,
      });
      return ScheduleDayDto.fromJson(json!);
    });
  }

  Future<List<ScheduleMonthDayDto>> adminMonth({
    required String teacherId,
    required int year,
    required int month,
  }) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminScheduleMonth, query: {
        'teacher_id': teacherId,
        'year': year.toString(),
        'month': month.toString(),
      });
      return (json?['days'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => ScheduleMonthDayDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<void> adminSaveBreaks({
    required String teacherId,
    String? breakfastStart,
    String? lunchStart,
  }) {
    return runApi(() => _client.post(ApiEndpoints.adminTeacherBreaks(teacherId), data: {
          'breakfast_start': breakfastStart,
          'lunch_start': lunchStart,
        }));
  }

  Future<void> adminTakeLeave({
    required String teacherId,
    required String date,
    required bool isFullDay,
    required String reason,
    List<String>? slotStarts,
  }) {
    return runApi(() => _client.post(ApiEndpoints.adminTeacherLeaves(teacherId), data: {
          'date': date,
          'is_full_day': isFullDay,
          'reason': reason,
          if (slotStarts != null) 'slot_starts': slotStarts,
        }));
  }

  Future<List<ScheduleLeaveDto>> adminLeaves({String? teacherId}) {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.adminScheduleLeaves,
        query: {if (teacherId != null) 'teacher_id': teacherId},
      );
      return items
          .whereType<Map>()
          .map((item) => ScheduleLeaveDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<void> adminDeleteLeave(String id) {
    return runApi(() => _client.delete(ApiEndpoints.adminScheduleLeave(id)));
  }

  Future<List<SessionBookingDto>> adminBookings({String? teacherId}) {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.adminScheduleBookings,
        query: {if (teacherId != null) 'teacher_id': teacherId},
      );
      return items
          .whereType<Map>()
          .map((item) => SessionBookingDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<void> adminDeleteBooking(String id) {
    return runApi(() => _client.delete(ApiEndpoints.adminScheduleBooking(id)));
  }

  Future<TeacherAvailabilityDto> adminTeacherAvailability(String teacherId) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminTeacherAvailability(teacherId));
      return TeacherAvailabilityDto.fromJson(json ?? const {});
    });
  }

  Future<TeacherAvailabilityDto> adminSaveTeacherAvailability({
    required String teacherId,
    required String workType,
    required List<AvailabilityDayDto> weekly,
  }) {
    return runApi(() async {
      final json = await _client.put(
        ApiEndpoints.adminTeacherAvailability(teacherId),
        data: {
          'work_type': workType,
          'weekly': weekly.map((day) => day.toPayload()).toList(),
        },
      );
      return TeacherAvailabilityDto.fromJson(json ?? const {});
    });
  }

  Future<GoogleMeetConnectionDto> adminGoogleMeet() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminGoogleMeet);
      return GoogleMeetConnectionDto.fromJson(json ?? const {});
    });
  }

  Future<String> adminGoogleMeetAuthorizeUrl() {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.adminGoogleMeetAuthorize);
      return json?['authorization_url'] as String? ?? '';
    });
  }
}
