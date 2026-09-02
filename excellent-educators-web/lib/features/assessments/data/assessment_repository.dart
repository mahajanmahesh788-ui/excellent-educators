import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/assessments/data/dto/assessment_dtos.dart';

class AssessmentRepository {
  AssessmentRepository(this._client);

  final ApiClient _client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(error.message, code: error.code);
    }
  }

  Future<PagedResult> adminAssessments({int page = 1}) {
    return _run(() => _client.getPage(ApiEndpoints.adminAssessments, query: {'page': page, 'per_page': 15}));
  }

  Future<AptitudeAssessmentDto> adminAssessment(String id) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminAssessment(id));
      return AptitudeAssessmentDto.fromJson(json!);
    });
  }

  Future<AptitudeAssessmentDto> createAssessment(Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminAssessments, data: data);
      return AptitudeAssessmentDto.fromJson(json!);
    });
  }

  Future<AptitudeAssessmentDto> updateAssessment(String id, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.put(ApiEndpoints.adminAssessment(id), data: data);
      return AptitudeAssessmentDto.fromJson(json!);
    });
  }

  Future<AptitudeAssessmentDto> activate(String id) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminAssessmentActivate(id));
      return AptitudeAssessmentDto.fromJson(json!);
    });
  }

  Future<AptitudeAssessmentDto> deactivate(String id) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminAssessmentDeactivate(id));
      return AptitudeAssessmentDto.fromJson(json!);
    });
  }

  Future<List<AssessmentResultDto>> adminAttempts(String id) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.adminAssessmentAttempts(id));
      return _results(items);
    });
  }

  Future<List<AssessmentResultDto>> adminStudentResults(String studentId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.adminStudentResults(studentId));
      return _results(items);
    });
  }

  Future<StudentAssessmentPayload> studentAssessment() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.studentAssessment);
      return StudentAssessmentPayload.fromJson(json ?? const {});
    });
  }

  Future<void> submitAssessment(String id, List<Map<String, String>> answers) {
    return _run(() async {
      await _client.post(
        ApiEndpoints.studentAssessmentSubmit(id),
        data: {'answers': answers},
      );
    });
  }

  Future<List<AssessmentResultDto>> teacherStudentResults(String studentId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.teacherStudentResults(studentId));
      return _results(items);
    });
  }

  Future<List<AssessmentResultDto>> masterTeacherStudentResults(String studentId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.masterTeacherStudentResults(studentId));
      return _results(items);
    });
  }

  List<AptitudeAssessmentDto> parseAssessments(PagedResult page) {
    return page.items
        .whereType<Map>()
        .map((item) => AptitudeAssessmentDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<AssessmentResultDto> _results(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((item) => AssessmentResultDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
