import 'package:excellent_educators_web/features/academic/presentation/providers/master_teacher_students_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MasterTeacherStudentsFilter', () {
    test('currentMonth uses today year and month', () {
      final filter = MasterTeacherStudentsFilter.currentMonth();

      expect(filter.year, greaterThan(2020));
      expect(filter.rated, MasterTeacherStudentsRatedFilter.all);
    });

    test('toQuery includes year and month', () {
      const filter = MasterTeacherStudentsFilter(year: 2026, month: 8);

      expect(filter.toQuery(), {'year': '2026', 'month': '8'});
    });

    test('toQuery includes rated when filtered', () {
      const rated = MasterTeacherStudentsFilter(year: 2026, month: 9, rated: MasterTeacherStudentsRatedFilter.rated);
      const notRated = MasterTeacherStudentsFilter(year: 2026, month: 9, rated: MasterTeacherStudentsRatedFilter.notRated);

      expect(rated.toQuery(), {'year': '2026', 'month': '9', 'rated': '1'});
      expect(notRated.toQuery(), {'year': '2026', 'month': '9', 'rated': '0'});
    });

    test('copyWith preserves unchanged fields', () {
      const original = MasterTeacherStudentsFilter(year: 2026, month: 7, rated: MasterTeacherStudentsRatedFilter.rated);
      final updated = original.copyWith(month: 8);

      expect(updated.year, 2026);
      expect(updated.month, 8);
      expect(updated.rated, MasterTeacherStudentsRatedFilter.rated);
    });

    test('equality compares year month and rated', () {
      const a = MasterTeacherStudentsFilter(year: 2026, month: 9);
      const b = MasterTeacherStudentsFilter(year: 2026, month: 9);
      const c = MasterTeacherStudentsFilter(year: 2026, month: 8);

      expect(a, b);
      expect(a == c, isFalse);
    });
  });

  group('masterTeacherStudentMonthOptions', () {
    test('returns requested count of options', () {
      final options = masterTeacherStudentMonthOptions(count: 6);

      expect(options, hasLength(6));
      expect(options.first.label, isNotEmpty);
    });
  });
}
