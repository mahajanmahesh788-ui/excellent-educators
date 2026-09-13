import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('student week payload can omit month year and rating', () {
    final week = LearningWeekDto.fromJson({
      'journey_id': 'j1',
      'level': {'id': 'l1', 'name': 'Level 1'},
      'week_number': 1,
      'assignment_status': 'pending',
      'attempts_used': 0,
      'attempts_max': 2,
      'can_submit': true,
      'has_video': true,
      'video_url': 'https://video.test/w1',
    });

    expect(week.weekNumber, 1);
    expect(week.month, isNull);
    expect(week.year, isNull);
    expect(week.completed, isFalse);
  });

  test('staff week payload keeps study date and curriculum month', () {
    final week = LearningWeekDto.fromJson({
      'journey_id': 'j1',
      'level': {'id': 'l1', 'name': 'Level 1'},
      'week_number': 1,
      'assignment_status': 'completed',
      'attempts_used': 1,
      'attempts_max': 2,
      'can_submit': false,
      'has_video': true,
      'video_url': 'https://video.test/w1',
      'study_date': '2026-07-15',
      'month': 'January',
      'year': 2026,
      'student': {'full_name': 'Ada', 'current_level': 'Level 1'},
    });

    expect(week.studyDate, '2026-07-15');
    expect(week.month, 'January');
    expect(week.year, 2026);
  });

  test('dashboard does not ask to complete an already submitted assignment', () {
    final dashboard = LearningDashboardDto.fromJson({
      'current_level': {'id': 'l1', 'name': 'Level 1'},
      'current_week': 2,
      'next_action': 'assignment_complete',
      'cta_label': 'Week 2 assignment completed',
      'progress': {'completed_weeks': 2, 'total_weeks': 52},
      'week': {
        'journey_id': 'j1',
        'level': {'id': 'l1', 'name': 'Level 1'},
        'week_number': 2,
        'assignment_status': 'completed',
        'attempts_used': 1,
        'attempts_max': 2,
        'can_submit': true,
        'has_video': true,
        'video_url': 'https://video.test/w2',
      },
    });

    expect(dashboard.assignmentPending, isFalse);
    expect(dashboard.week!.completed, isTrue);
  });

  test('week payload parses score correctly when present', () {
    final week = LearningWeekDto.fromJson({
      'journey_id': 'j1',
      'level': {'id': 'l1', 'name': 'Level 1'},
      'week_number': 3,
      'assignment_status': 'completed',
      'attempts_used': 1,
      'attempts_max': 2,
      'can_submit': false,
      'has_video': true,
      'video_url': 'https://video.test/w3',
      'score': {
        'correct': 4,
        'total': 5,
        'percentage': 80,
        'display': '4/5',
        'attempt_number': 1,
      },
    });

    expect(week.score, isNotNull);
    expect(week.score!.correct, 4);
    expect(week.score!.total, 5);
    expect(week.score!.percentage, 80);
    expect(week.score!.display, '4/5');
  });
}
