import 'package:excellent_educators_web/features/schedule/data/dto/schedule_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatHm converts 24h slots to 12h labels', () {
    expect(formatHm('06:00'), '6:00 AM');
    expect(formatHm('09:30'), '9:30 AM');
    expect(formatHm('13:00'), '1:00 PM');
    expect(formatHm('19:30'), '7:30 PM');
  });

  test('ScheduleLeaveDto parses created_at correctly', () {
    final dto = ScheduleLeaveDto.fromJson({
      'id': 'leave-1',
      'date': '2026-09-17',
      'start_time': '09:00',
      'end_time': '13:00',
      'is_full_day': false,
      'reason': 'Personal',
      'created_at': '2026-09-13T09:21:40Z',
    });
    expect(dto.id, 'leave-1');
    expect(dto.createdAt, '2026-09-13T09:21:40Z');
  });
}
