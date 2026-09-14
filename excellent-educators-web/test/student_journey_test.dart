import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/features/student/presentation/widgets/student_journey.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new students are prompted to book an introduction', () {
    final snapshot = buildStudentJourney(
      eligibility: const BookingEligibilityDto(
        introductionCompleted: false,
        canBookIntroduction: true,
        canBookMasterClass: false,
      ),
      bookings: const [],
    );

    expect(snapshot.introduction.phase, JourneyPhase.current);
    expect(snapshot.introduction.detail, 'Book your introduction');
    expect(snapshot.masterClass.phase, JourneyPhase.upcoming);
    expect(snapshot.primaryType, 'introduction_call');
  });

  test('scheduled introduction is reflected before completion', () {
    final snapshot = buildStudentJourney(
      eligibility: const BookingEligibilityDto(
        introductionCompleted: false,
        canBookIntroduction: false,
        canBookMasterClass: false,
      ),
      bookings: [
        SessionBookingDto(
          id: '1',
          studentId: 's',
          teacherId: 't',
          type: 'introduction_call',
          date: '2099-01-15',
          start: '16:00',
          end: '16:30',
          status: 'scheduled',
        ),
      ],
    );

    expect(snapshot.introduction.detail, 'Scheduled');
    expect(snapshot.nextSession?.id, '1');
    expect(snapshot.primaryType, isNull);
    expect(snapshot.canBookIntroduction, isFalse);
  });

  test('live introduction is joinable and not offered for booking', () {
    final now = DateTime(2026, 9, 14, 16, 10);
    final snapshot = buildStudentJourney(
      now: now,
      eligibility: const BookingEligibilityDto(
        introductionCompleted: false,
        canBookIntroduction: true,
        canBookMasterClass: false,
      ),
      bookings: [
        SessionBookingDto(
          id: 'live',
          studentId: 's',
          teacherId: 't',
          type: 'introduction_call',
          date: '2026-09-14',
          start: '16:00',
          end: '16:30',
          status: 'scheduled',
          startsAtIso: now.subtract(const Duration(minutes: 10)).toIso8601String(),
          endsAtIso: now.add(const Duration(minutes: 20)).toIso8601String(),
          attendance: const BookingAttendanceDto(canJoin: true),
        ),
      ],
    );

    expect(snapshot.joinableSession?.id, 'live');
    expect(snapshot.nextSession?.id, 'live');
    expect(snapshot.primaryType, isNull);
    expect(snapshot.canBookIntroduction, isFalse);
    expect(snapshot.heroMessage, contains('Introduction Call is live'));
  });

  test('booked master class is not offered again this month', () {
    final now = DateTime(2026, 9, 14, 10);
    final snapshot = buildStudentJourney(
      now: now,
      eligibility: const BookingEligibilityDto(
        introductionCompleted: true,
        canBookIntroduction: false,
        canBookMasterClass: true,
      ),
      bookings: [
        SessionBookingDto(
          id: 'mc',
          studentId: 's',
          teacherId: 't',
          type: 'master_class',
          date: '2026-09-20',
          start: '16:00',
          end: '16:30',
          status: 'scheduled',
          startsAtIso: DateTime(2026, 9, 20, 16).toIso8601String(),
          endsAtIso: DateTime(2026, 9, 20, 16, 30).toIso8601String(),
        ),
      ],
    );

    expect(snapshot.primaryType, isNull);
    expect(snapshot.canBookMasterClass, isFalse);
    expect(snapshot.masterClass.detail, 'Scheduled');
  });

  test('completed master class this month is not offered for booking', () {
    final now = DateTime(2026, 9, 14, 17);
    final snapshot = buildStudentJourney(
      now: now,
      eligibility: const BookingEligibilityDto(
        introductionCompleted: true,
        canBookIntroduction: false,
        canBookMasterClass: true,
      ),
      bookings: [
        SessionBookingDto(
          id: 'mc',
          studentId: 's',
          teacherId: 't',
          type: 'master_class',
          date: '2026-09-14',
          start: '16:00',
          end: '16:30',
          status: 'scheduled',
          startsAtIso: DateTime(2026, 9, 14, 16).toIso8601String(),
          endsAtIso: DateTime(2026, 9, 14, 16, 30).toIso8601String(),
          attendance: const BookingAttendanceDto(classCompleted: true, studentJoinCount: 1),
        ),
      ],
    );

    expect(snapshot.canBookMasterClass, isFalse);
    expect(snapshot.primaryType, isNull);
    expect(snapshot.masterClass.detail, 'Completed');
  });

  test('past master class this month is not offered again even if eligibility is stale', () {
    final now = DateTime(2026, 9, 14, 19, 10);
    final snapshot = buildStudentJourney(
      now: now,
      eligibility: const BookingEligibilityDto(
        introductionCompleted: true,
        canBookIntroduction: false,
        canBookMasterClass: true,
      ),
      bookings: [
        SessionBookingDto(
          id: 'mc',
          studentId: 's',
          teacherId: 't',
          type: 'master_class',
          date: '2026-09-14',
          start: '18:00',
          end: '18:30',
          status: 'scheduled',
          startsAtIso: DateTime(2026, 9, 14, 18).toIso8601String(),
          endsAtIso: DateTime(2026, 9, 14, 18, 30).toIso8601String(),
        ),
      ],
    );

    expect(snapshot.canBookMasterClass, isFalse);
    expect(snapshot.primaryType, isNull);
    expect(snapshot.masterClass.detail, 'Completed');
  });
}
