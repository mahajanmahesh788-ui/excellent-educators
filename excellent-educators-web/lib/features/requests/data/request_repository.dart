import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/requests/data/dto/request_dtos.dart';

class RequestRepository {
  RequestRepository(this._client);

  final ApiClient _client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(error.message, code: error.code);
    }
  }

  Future<List<AdminRequestDto>> studentRequests() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.studentRequests);
      return _parse(items);
    });
  }

  Future<AdminRequestDto> createStudentRequest({
    required String subtitle,
    required String description,
  }) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.studentRequests,
        data: {'subtitle': subtitle, 'description': description},
      );
      return AdminRequestDto.fromJson(json!);
    });
  }

  Future<List<AdminRequestDto>> teacherRequests() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.teacherRequests);
      return _parse(items);
    });
  }

  Future<AdminRequestDto> createTeacherRequest({
    required String subtitle,
    required String description,
  }) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.teacherRequests,
        data: {
          'request_type': 'general',
          'subtitle': subtitle,
          'description': description,
        },
      );
      return AdminRequestDto.fromJson(json!);
    });
  }

  Future<AdminRequestDto> createTeacherRemoveMenteeRequest({
    required String studentId,
    String? reason,
  }) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.teacherRequests,
        data: {
          'request_type': 'remove_mentee',
          'student_id': studentId,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
      return AdminRequestDto.fromJson(json!);
    });
  }

  Future<AdminRequestDto> createTeacherRemoveBatchStudentRequest({
    required String studentId,
    required String batchId,
    String? reason,
  }) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.teacherRequests,
        data: {
          'request_type': 'remove_batch_student',
          'student_id': studentId,
          'batch_id': batchId,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
      return AdminRequestDto.fromJson(json!);
    });
  }

  Future<PagedResult> adminRequests({
    int page = 1,
    String? status,
    String search = '',
  }) {
    return _run(() async {
      return _client.getPage(
        ApiEndpoints.adminRequests,
        query: {
          'page': page,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search.isNotEmpty) 'search': search,
        },
      );
    });
  }

  Future<AdminRequestDto> adminRequest(String id) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminRequest(id));
      return AdminRequestDto.fromJson(json!);
    });
  }

  Future<AdminRequestDto> resolveAdminRequest(String id, {bool applyAction = true}) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.adminRequestResolve(id),
        data: {'apply_action': applyAction},
      );
      return AdminRequestDto.fromJson(json!);
    });
  }

  List<AdminRequestDto> parseRequests(PagedResult page) {
    return page.items
        .whereType<Map>()
        .map((item) => AdminRequestDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<AdminRequestDto> _parse(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((item) => AdminRequestDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
