import 'package:flutter/material.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';
import 'package:excellent_educators_web/features/learning/presentation/widgets/learning_journal_ui.dart';
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

  test('attempt answers match question options and correct states', () {
    final attempt = LearningAttemptDto.fromJson({
      'attempt_number': 1,
      'submitted_at': '2026-09-13T10:00:00Z',
      'answers': [
        {'question_id': 'q1', 'option_id': 'opt_earth'},
        {'question_id': 'q2', 'option_id': 'opt_sun'},
      ],
    });

    expect(attempt.attemptNumber, 1);
    expect(attempt.optionIdFor('q1'), 'opt_earth');
    expect(attempt.optionIdFor('q2'), 'opt_sun');
    expect(attempt.optionIdFor('q3'), isNull);
  });

  test('week assignment result parses the same dimension scores as assessments', () {
    final week = LearningWeekDto.fromJson({
      'journey_id': 'j1',
      'level': {'id': 'l1', 'name': 'Level 1'},
      'week_number': 1,
      'assignment_status': 'completed',
      'attempts_used': 1,
      'attempts_max': 2,
      'can_submit': false,
      'has_video': false,
      'result': {
        'id': 'a1',
        'assessment': {'title': 'Level 1 · Week 1'},
        'submitted_at': '2026-09-23T15:59:00Z',
        'dimensions': [
          {'name': 'Personality', 'score': 0},
          {'name': 'Interests', 'score': 0},
          {'name': 'Confidence', 'score': 1},
          {'name': 'Leadership', 'score': 1},
          {'name': 'Communication', 'score': 1},
          {'name': 'Decision-making', 'score': 2},
          {'name': 'Creativity', 'score': 1},
          {'name': 'Curiosity', 'score': 1},
          {'name': 'Teamwork', 'score': 0},
          {'name': 'Future Aspirations', 'score': 1},
        ],
      },
      'attempts': [
        {
          'attempt_number': 1,
          'submitted_at': '2026-09-23T15:59:00Z',
          'answers': [
            {'question_id': 'q1', 'option_id': 'o1'},
          ],
          'result': {
            'id': 'a1',
            'assessment': {'title': 'Level 1 · Week 1'},
            'dimensions': [
              {'name': 'Personality', 'score': 0},
              {'name': 'Teamwork', 'score': 0},
            ],
          },
        },
      ],
    });

    expect(week.result, isNotNull);
    expect(week.result!.assessmentTitle, 'Level 1 · Week 1');
    expect(week.result!.dimensions, hasLength(10));
    expect(week.result!.dimensions.first.name, 'Personality');
    expect(week.result!.dimensions.first.score, 0);
    expect(week.result!.dimensions[5].name, 'Decision-making');
    expect(week.result!.dimensions[5].score, 2);
    expect(week.attempts.first.result, isNotNull);
    expect(week.attempts.first.result!.dimensions.first.name, 'Personality');
  });

  testWidgets('staff learning journal table displays latest week on top and spans full width', (tester) async {
    final journal = LearningJournalDto.fromJson({
      'levels': [
        {
          'journey_id': 'j1',
          'level': {'id': 'l1', 'name': 'Level 1'},
          'week_count': 3,
          'is_current': true,
          'weeks': [
            {
              'journey_id': 'j1',
              'level': {'id': 'l1', 'name': 'Level 1'},
              'week_number': 1,
              'assignment_status': 'completed',
              'attempts_used': 1,
              'attempts_max': 2,
              'can_submit': false,
              'has_video': false,
            },
            {
              'journey_id': 'j1',
              'level': {'id': 'l1', 'name': 'Level 1'},
              'week_number': 2,
              'assignment_status': 'completed',
              'attempts_used': 1,
              'attempts_max': 2,
              'can_submit': false,
              'has_video': false,
            },
            {
              'journey_id': 'j1',
              'level': {'id': 'l1', 'name': 'Level 1'},
              'week_number': 3,
              'assignment_status': 'pending',
              'attempts_used': 0,
              'attempts_max': 2,
              'can_submit': true,
              'has_video': false,
            },
          ],
        },
      ],
    });

    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 1200,
            child: LearningJournalTable(
              journal: journal,
              staffView: true,
              onOpenWeek: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify weeks are ordered descending: Week 3, Week 2, Week 1
    final week3Finder = find.text('Week 3');
    final week2Finder = find.text('Week 2');
    final week1Finder = find.text('Week 1');

    expect(week3Finder, findsOneWidget);
    expect(week2Finder, findsOneWidget);
    expect(week1Finder, findsOneWidget);

    final week3Y = tester.getTopLeft(week3Finder).dy;
    final week2Y = tester.getTopLeft(week2Finder).dy;
    final week1Y = tester.getTopLeft(week1Finder).dy;

    // Week 3 must be on top of Week 2, which is on top of Week 1
    expect(week3Y < week2Y, isTrue);
    expect(week2Y < week1Y, isTrue);

    // Verify ConstrainedBox wrapping DataTable minWidth matches or exceeds the 1200 card width
    final constrainedBox = tester.widget<ConstrainedBox>(
      find.ancestor(
        of: find.byType(DataTable),
        matching: find.byType(ConstrainedBox),
      ).first,
    );
    expect(constrainedBox.constraints.minWidth, greaterThanOrEqualTo(1200));
  });
}

