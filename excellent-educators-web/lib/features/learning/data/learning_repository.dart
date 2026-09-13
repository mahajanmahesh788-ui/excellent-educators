import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/errors/api_error_message.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/learning/data/dto/learning_dtos.dart';

class LearningRepository {
  LearningRepository(this._client);

  final ApiClient _client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(formatApiErrorMessage(error), code: error.code);
    }
  }

  Future<LearningDashboardDto> studentDashboard() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.studentLearningDashboard);
      return LearningDashboardDto.fromJson(json!);
    });
  }

  Future<LearningJournalDto> studentJournal() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.studentLearningJournal);
      return LearningJournalDto.fromJson(json!);
    });
  }

  Future<LearningWeekDto> studentWeek(String journeyId, int week) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.studentLearningWeek(journeyId, week));
      return LearningWeekDto.fromJson(json!);
    });
  }

  Future<LearningWeekDto> submitWeek({
    required String journeyId,
    required int week,
    required List<Map<String, dynamic>> answers,
  }) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.studentLearningWeek(journeyId, week),
        data: {'answers': answers},
      );
      return LearningWeekDto.fromJson(json!);
    });
  }

  Future<LearningJournalDto> adminJournal(String studentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminStudentLearningJournal(studentId));
      return LearningJournalDto.fromJson(json!);
    });
  }

  Future<LearningWeekDto> adminWeek(String studentId, String journeyId, int week) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminStudentLearningWeek(studentId, journeyId, week));
      return LearningWeekDto.fromJson(json!);
    });
  }

  Future<StudentDto> promoteStudent({required String studentId, required String levelId, bool masterTeacher = false}) {
    return _run(() async {
      final path = masterTeacher
          ? ApiEndpoints.masterTeacherStudentPromote(studentId)
          : ApiEndpoints.adminStudentPromote(studentId);
      final json = await _client.post(path, data: {'level_id': levelId});
      return StudentDto.fromJson(json!);
    });
  }

  Future<LearningJournalDto> teacherJournal(String studentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.teacherStudentLearningJournal(studentId));
      return LearningJournalDto.fromJson(json!);
    });
  }

  Future<LearningWeekDto> teacherWeek(String studentId, String journeyId, int week) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.teacherStudentLearningWeek(studentId, journeyId, week));
      return LearningWeekDto.fromJson(json!);
    });
  }

  Future<LearningJournalDto> masterTeacherJournal(String studentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.masterTeacherStudentLearningJournal(studentId));
      return LearningJournalDto.fromJson(json!);
    });
  }

  Future<LearningWeekDto> masterTeacherWeek(String studentId, String journeyId, int week) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.masterTeacherStudentLearningWeek(studentId, journeyId, week));
      return LearningWeekDto.fromJson(json!);
    });
  }

  Future<List<WeeklyLearningContentDto>> adminWeeklyLearnings(String levelId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.adminLevelWeeklyLearnings(levelId));
      return items
          .whereType<Map>()
          .map((item) => WeeklyLearningContentDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<WeeklyLearningContentDto> upsertWeeklyLearning({
    required String levelId,
    required int weekNumber,
    required String videoUrl,
    required List<Map<String, dynamic>> questions,
  }) {
    return _run(() async {
      final json = await _client.put(
        ApiEndpoints.adminLevelWeeklyLearnings(levelId),
        data: {
          'week_number': weekNumber,
          'video_url': videoUrl,
          'questions': questions,
        },
      );
      return WeeklyLearningContentDto.fromJson(json!);
    });
  }
}
