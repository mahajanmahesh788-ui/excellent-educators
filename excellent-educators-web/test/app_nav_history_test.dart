import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/navigation/app_nav_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final history = AppNavHistory.instance;

  setUp(history.clear);
  tearDown(history.clear);

  test('shell destinations reset the stack', () {
    history.track(RoutePaths.studentDashboard);
    history.track('/student/journal/j1/1');
    history.track(RoutePaths.studentJournal);

    expect(history.stack, [RoutePaths.studentJournal]);
    expect(history.canGoBack, isFalse);
  });

  test('returning to an earlier detail truncates forward entries', () {
    history.track(RoutePaths.adminStudents);
    history.track('/admin/students/s1');
    history.track('/admin/students/s1/edit');
    history.track('/admin/students/s1');

    expect(history.stack, [
      RoutePaths.adminStudents,
      '/admin/students/s1',
    ]);
    expect(history.canGoBack, isTrue);
  });

  test('discardCurrent drops C so back from B goes to A', () {
    history.track(RoutePaths.adminStudents);
    history.track('/admin/students/s1');
    history.track('/admin/students/s1/edit');
    history.discardCurrent();

    expect(history.stack, [
      RoutePaths.adminStudents,
      '/admin/students/s1',
    ]);
    expect(history.takeBackTarget(), RoutePaths.adminStudents);
  });
}
