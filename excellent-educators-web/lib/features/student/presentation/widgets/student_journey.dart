import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';

enum JourneyPhase { completed, current, upcoming }

class JourneyNode {
  const JourneyNode({
    required this.title,
    required this.detail,
    required this.phase,
  });

  final String title;
  final String detail;
  final JourneyPhase phase;
}

class StudentJourneySnapshot {
  const StudentJourneySnapshot({
    required this.nextSession,
    required this.introduction,
    required this.masterClass,
    required this.nextMonth,
    required this.masterThisMonth,
    required this.introductionCompleted,
    required this.canBookIntroduction,
    required this.canBookMasterClass,
  });

  final SessionBookingDto? nextSession;
  final JourneyNode introduction;
  final JourneyNode masterClass;
  final JourneyNode nextMonth;
  final int masterThisMonth;
  final bool introductionCompleted;
  final bool canBookIntroduction;
  final bool canBookMasterClass;

  String get heroMessage {
    if (nextSession != null) {
      return 'Your next session is already on the calendar.';
    }
    if (canBookIntroduction) {
      return 'Your learning journey is waiting for you.';
    }
    if (canBookMasterClass) {
      return 'Your next Master Class is ready to book.';
    }
    return 'Your learning journey is moving forward.';
  }

  String? get primaryType {
    if (canBookIntroduction) return 'introduction_call';
    if (canBookMasterClass) return 'master_class';
    return null;
  }
}

String bookingActionLabel(String? type) {
  switch (type) {
    case 'introduction_call':
      return 'Book Introduction';
    case 'master_class':
      return 'Book Master Class';
    default:
      return 'Book a session';
  }
}

StudentJourneySnapshot buildStudentJourney({
  required BookingEligibilityDto eligibility,
  required List<SessionBookingDto> bookings,
}) {
  final now = DateTime.now();
  SessionBookingDto? next;
  for (final booking in bookings.where((item) => item.isScheduled)) {
    final start = booking.startsAt;
    if (start == null || start.isBefore(now)) {
      continue;
    }
    final current = next?.startsAt;
    if (current == null || start.isBefore(current)) {
      next = booking;
    }
  }

  final introScheduled = bookings.any((item) => item.type != 'master_class' && item.isScheduled);
  final JourneyNode introduction;
  if (eligibility.introductionCompleted) {
    introduction = const JourneyNode(title: 'Introduction', detail: 'Completed', phase: JourneyPhase.completed);
  } else if (introScheduled) {
    final lastChance = bookings.any(
      (item) => item.type != 'master_class' && item.isScheduled && (item.attemptNumber ?? 1) >= 2,
    );
    introduction = JourneyNode(
      title: 'Introduction',
      detail: lastChance ? 'Scheduled — last chance' : 'Scheduled',
      phase: JourneyPhase.current,
    );
  } else {
    introduction = JourneyNode(
      title: 'Introduction',
      detail: eligibility.introductionLastChance
          ? 'Last chance — book your Introduction Call'
          : 'Book your introduction',
      phase: JourneyPhase.current,
    );
  }

  final masterThisMonth = bookings.where((item) {
    if (item.type != 'master_class' || item.isCancelled) {
      return false;
    }
    final date = DateTime.tryParse(item.date);
    return date != null && date.year == now.year && date.month == now.month;
  }).toList();
  final masterScheduled = masterThisMonth.any((item) => item.isScheduled);
  final masterCompleted = masterThisMonth.any((item) => item.isCompleted);

  final JourneyNode master;
  if (!eligibility.introductionCompleted && !introScheduled) {
    master = const JourneyNode(title: 'Master Class', detail: 'Upcoming', phase: JourneyPhase.upcoming);
  } else if (masterCompleted) {
    master = const JourneyNode(title: 'Master Class', detail: 'Completed', phase: JourneyPhase.completed);
  } else if (masterScheduled) {
    master = const JourneyNode(title: 'Master Class', detail: 'Scheduled', phase: JourneyPhase.current);
  } else if (eligibility.canBookMasterClass) {
    master = const JourneyNode(title: 'Master Class', detail: 'Ready to book', phase: JourneyPhase.current);
  } else {
    master = const JourneyNode(title: 'Master Class', detail: 'Upcoming', phase: JourneyPhase.upcoming);
  }

  final nextMonth = JourneyNode(
    title: 'Next Month',
    detail: masterCompleted
        ? 'Your next Master Class opens next month'
        : 'Upcoming',
    phase: JourneyPhase.upcoming,
  );

  return StudentJourneySnapshot(
    nextSession: next,
    introduction: introduction,
    masterClass: master,
    nextMonth: nextMonth,
    masterThisMonth: masterThisMonth.length,
    introductionCompleted: eligibility.introductionCompleted,
    canBookIntroduction: eligibility.canBookIntroduction,
    canBookMasterClass: eligibility.canBookMasterClass,
  );
}

String greetingForNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}
