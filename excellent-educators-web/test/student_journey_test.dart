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
  });
}
