import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/feedback/data/dto/feedback_dtos.dart';

class FeedbackRepository {
  FeedbackRepository(this._client);

  final ApiClient _client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(error.message, code: error.code);
    }
  }

  Future<List<FeedbackDimensionDto>> catalog() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.masterTeacherCatalog);
      return items
          .whereType<Map>()
          .map((item) => FeedbackDimensionDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<List<MonthlyFeedbackDto>> studentFeedback(String studentId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.masterTeacherFeedback(studentId));
      return _feedback(items);
    });
  }

  Future<MonthlyFeedbackDto> createFeedback(String studentId, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.masterTeacherFeedback(studentId), data: data);
      return MonthlyFeedbackDto.fromJson(json!);
    });
  }

  Future<MonthlyFeedbackDto> updateFeedback(
    String studentId,
    String feedbackId,
    Map<String, dynamic> data,
  ) {
    return _run(() async {
      final json = await _client.put(
        ApiEndpoints.masterTeacherFeedbackItem(studentId, feedbackId),
        data: data,
      );
      return MonthlyFeedbackDto.fromJson(json!);
    });
  }

  Future<void> deleteFeedback(String studentId, String feedbackId) {
    return _run(() async {
      await _client.delete(ApiEndpoints.masterTeacherFeedbackItem(studentId, feedbackId));
    });
  }

  Future<List<FeedbackDimensionDto>> adminCatalog() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.adminFeedbackCatalog);
      return items
          .whereType<Map>()
          .map((item) => FeedbackDimensionDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<MonthlyFeedbackDto> adminCreateFeedback(String studentId, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminStudentFeedback(studentId), data: data);
      return MonthlyFeedbackDto.fromJson(json!);
    });
  }

  Future<MonthlyFeedbackDto> adminUpdateFeedback(
    String studentId,
    String feedbackId,
    Map<String, dynamic> data,
  ) {
    return _run(() async {
      final json = await _client.put(
        ApiEndpoints.adminStudentFeedbackItem(studentId, feedbackId),
        data: data,
      );
      return MonthlyFeedbackDto.fromJson(json!);
    });
  }

  Future<void> adminDeleteFeedback(String studentId, String feedbackId) {
    return _run(() async {
      await _client.delete(ApiEndpoints.adminStudentFeedbackItem(studentId, feedbackId));
    });
  }

  Future<List<MonthlyFeedbackDto>> ownFeedback() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.studentFeedback);
      return _feedback(items);
    });
  }

  Future<FeedbackSummaryDto> ownFeedbackSummary() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.studentFeedbackSummary);
      return FeedbackSummaryDto.fromJson(json!);
    });
  }

  Future<List<MonthlyFeedbackDto>> adminStudentFeedback(String studentId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.adminStudentFeedback(studentId));
      return _feedback(items);
    });
  }

  Future<FeedbackSummaryDto> adminStudentFeedbackSummary(String studentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminStudentFeedbackSummary(studentId));
      return FeedbackSummaryDto.fromJson(json!);
    });
  }

  Future<List<MonthlyFeedbackDto>> teacherStudentFeedback(String studentId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.teacherStudentFeedback(studentId));
      return _feedback(items);
    });
  }

  Future<FeedbackSummaryDto> teacherStudentFeedbackSummary(String studentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.teacherStudentFeedbackSummary(studentId));
      return FeedbackSummaryDto.fromJson(json!);
    });
  }

  Future<FeedbackSummaryDto> masterTeacherStudentFeedbackSummary(String studentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.masterTeacherFeedbackSummary(studentId));
      return FeedbackSummaryDto.fromJson(json!);
    });
  }

  List<MonthlyFeedbackDto> _feedback(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((item) => MonthlyFeedbackDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
