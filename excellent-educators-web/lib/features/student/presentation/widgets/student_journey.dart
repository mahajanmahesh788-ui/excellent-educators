import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:excellent_educators_web/core/constants/app_strings.dart';

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
    this.joinableSession,
    this.masterClassRemaining = 0,
    this.masterClassAllotment = 1,
  });

  final SessionBookingDto? nextSession;
  final SessionBookingDto? joinableSession;
  final JourneyNode introduction;
  final JourneyNode masterClass;
  final JourneyNode nextMonth;
  final int masterThisMonth;
  final bool introductionCompleted;
  final bool canBookIntroduction;
  final bool canBookMasterClass;
  final int masterClassRemaining;
  final int masterClassAllotment;

  bool get hasExtraMasterClasses => masterClassAllotment > 1;

  String get heroMessage {
    if (joinableSession != null) {
      return joinableSession!.type == 'master_class'
          ? AppStrings.yourMasterClassIsLiveJoinNowSoYouDon
          : AppStrings.yourIntroductionCallIsLiveJoinNowSoYouDon;
    }
    if (nextSession != null) {
      return AppStrings.yourNextSessionIsAlreadyOnTheCalendar;
    }
    if (canBookIntroduction) {
      return AppStrings.yourLearningJourneyIsWaitingForYou;
    }
    if (canBookMasterClass) {
      return AppStrings.yourNextMasterClassIsReadyToBook;
    }
    return AppStrings.yourLearningJourneyIsMovingForward;
  }

  String? get primaryType {
    if (joinableSession != null || nextSession != null) {
      return null;
    }
    if (canBookIntroduction) return 'introduction_call';
    if (canBookMasterClass) return 'master_class';
    return null;
  }
}

String bookingActionLabel(String? type) {
  switch (type) {
    case 'introduction_call':
      return AppStrings.bookIntroduction;
    case 'master_class':
      return AppStrings.bookMasterClass;
    default:
      return AppStrings.bookASession;
  }
}

StudentJourneySnapshot buildStudentJourney({
  required BookingEligibilityDto eligibility,
  required List<SessionBookingDto> bookings,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  SessionBookingDto? next;
  SessionBookingDto? joinable;
  for (final booking in bookings.where((item) => item.isScheduled)) {
    if (booking.hasEndedAt(clock)) {
      continue;
    }
    final start = booking.startsAt;
    if (start == null) {
      continue;
    }
    final current = next?.startsAt;
    if (current == null || start.isBefore(current)) {
      next = booking;
    }
    final canJoin =
        booking.attendance?.canJoin == true || booking.isOngoingAt(clock);
    if (canJoin) {
      final liveStart = joinable?.startsAt;
      if (liveStart == null || start.isBefore(liveStart)) {
        joinable = booking;
      }
    }
  }

  final introScheduled = bookings.any(
    (item) =>
        item.type != 'master_class' &&
        item.isScheduled &&
        !item.hasEndedAt(clock),
  );
  final JourneyNode introduction;
  if (eligibility.introductionCompleted) {
    introduction = const JourneyNode(
      title: AppStrings.introduction,
      detail: AppStrings.completed,
      phase: JourneyPhase.completed,
    );
  } else if (introScheduled) {
    final lastChance = bookings.any(
      (item) =>
          item.type != 'master_class' &&
          item.isScheduled &&
          (item.attemptNumber ?? 1) >= 2,
    );
    introduction = JourneyNode(
      title: AppStrings.introduction,
      detail: lastChance
          ? AppStrings.scheduledLastChance
          : AppStrings.scheduled,
      phase: JourneyPhase.current,
    );
  } else {
    introduction = JourneyNode(
      title: AppStrings.introduction,
      detail: eligibility.introductionLastChance
          ? AppStrings.lastChanceBookYourIntroductionCall
          : AppStrings.bookYourIntroduction,
      phase: JourneyPhase.current,
    );
  }

  final masterThisMonth = bookings.where((item) {
    if (item.type != 'master_class' || item.isCancelled) {
      return false;
    }
    final date = DateTime.tryParse(item.date);
    return date != null && date.year == clock.year && date.month == clock.month;
  }).toList();
  final masterScheduled = masterThisMonth.any(
    (item) => item.isScheduled && !item.hasEndedAt(clock),
  );
  final masterCompleted = masterThisMonth.any((item) {
    if (item.isCompleted || item.attendance?.classCompleted == true) {
      return true;
    }
    return item.hasEndedAt(clock);
  });

  final JourneyNode master;
  if (!eligibility.introductionCompleted && !introScheduled) {
    master = const JourneyNode(
      title: AppStrings.masterClass,
      detail: AppStrings.upcoming,
      phase: JourneyPhase.upcoming,
    );
  } else if (masterScheduled) {
    master = const JourneyNode(
      title: AppStrings.masterClass,
      detail: AppStrings.scheduled,
      phase: JourneyPhase.current,
    );
  } else if (eligibility.canBookMasterClass &&
      eligibility.masterClassRemaining > 0) {
    final remaining = eligibility.masterClassRemaining;
    final max = eligibility.masterClassAttemptsMax;
    master = JourneyNode(
      title: AppStrings.masterClass,
      detail: max > 1
          ? 'You have $remaining of $max Master Classes this month'
          : 'Ready to book',
      phase: JourneyPhase.current,
    );
  } else if (masterCompleted) {
    master = const JourneyNode(
      title: AppStrings.masterClass,
      detail: AppStrings.completed,
      phase: JourneyPhase.completed,
    );
  } else {
    master = const JourneyNode(
      title: AppStrings.masterClass,
      detail: AppStrings.upcoming,
      phase: JourneyPhase.upcoming,
    );
  }

  final nextMonth = JourneyNode(
    title: AppStrings.nextMonth,
    detail: masterCompleted
        ? AppStrings.yourNextMasterClassOpensNextMonth
        : AppStrings.upcoming,
    phase: JourneyPhase.upcoming,
  );

  return StudentJourneySnapshot(
    nextSession: next,
    joinableSession: joinable,
    introduction: introduction,
    masterClass: master,
    nextMonth: nextMonth,
    masterThisMonth: masterThisMonth.length,
    introductionCompleted: eligibility.introductionCompleted,
    canBookIntroduction: eligibility.canBookIntroduction && !introScheduled,
    canBookMasterClass:
        eligibility.canBookMasterClass &&
        eligibility.masterClassRemaining > 0 &&
        !masterScheduled,
    masterClassRemaining: eligibility.masterClassRemaining,
    masterClassAllotment: eligibility.masterClassAttemptsMax,
  );
}

String greetingForNow([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 12) return AppStrings.goodMorning;
  if (hour < 17) return AppStrings.goodAfternoon;
  return AppStrings.goodEvening;
}
