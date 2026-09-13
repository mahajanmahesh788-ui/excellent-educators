import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/errors/api_error_message.dart';
import 'package:excellent_educators_web/core/errors/failure.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/api_exception.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/master_teacher_students_filter.dart';

class AcademicRepository {
  AcademicRepository(this._client);

  final ApiClient _client;

  Future<T> _run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw Failure(formatApiErrorMessage(error), code: error.code);
    }
  }

  List<StudentDto> _students(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((item) => StudentDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<TeacherDto> _teachers(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((item) => TeacherDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<BatchDto> _batches(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((item) => BatchDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<CareerCompassLevelDto>> careerCompassLevels() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.careerCompassLevels);
      return items
          .whereType<Map>()
          .map((item) => CareerCompassLevelDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<AdminDashboardDto> adminDashboard() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminDashboard);
      return AdminDashboardDto.fromJson(json!);
    });
  }

  Future<PagedResult> adminStudents({
    String? search,
    String? careerCompassLevelId,
    String? status,
    bool withoutBatch = false,
    bool withoutMasterTeacher = false,
    bool assessmentPending = false,
    bool withoutRatingThisMonth = false,
    int page = 1,
    int perPage = 25,
  }) {
    return _run(
      () => _client.getPage(
        ApiEndpoints.adminStudents,
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (careerCompassLevelId != null && careerCompassLevelId.isNotEmpty)
            'career_compass_level_id': careerCompassLevelId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (withoutBatch) 'without_batch': 'true',
          if (withoutMasterTeacher) 'without_master_teacher': 'true',
          if (assessmentPending) 'assessment_pending': 'true',
          if (withoutRatingThisMonth) 'without_rating_this_month': 'true',
          'page': '$page',
          'per_page': '$perPage',
        },
      ),
    );
  }

  Future<StudentDto> adminStudent(String id) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminStudent(id));
      return StudentDto.fromJson(json!);
    });
  }

  Future<StudentDto> updateStudent(String id, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.put(ApiEndpoints.adminStudent(id), data: data);
      return StudentDto.fromJson(json!);
    });
  }

  Future<StudentDto> createStudent(Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminStudents, data: data);
      return StudentDto.fromJson(json!);
    });
  }

  Future<StudentDto> assignMasterTeacher({
    required String studentId,
    required String teacherId,
  }) {
    return _run(() async {
      final json = await _client.put(
        ApiEndpoints.adminStudentMentor(studentId),
        data: {'teacher_id': teacherId},
      );
      return StudentDto.fromJson(json!);
    });
  }

  Future<PagedResult> adminTeachers({
    String? search,
    String? status,
    String? role,
    String? excludeLevelId,
    int page = 1,
    int perPage = 25,
  }) {
    return _run(
      () => _client.getPage(
        ApiEndpoints.adminTeachers,
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (role != null && role.isNotEmpty) 'role': role,
          if (excludeLevelId != null && excludeLevelId.isNotEmpty) 'exclude_level_id': excludeLevelId,
          'page': page,
          'per_page': perPage,
        },
      ),
    );
  }

  Future<TeacherDto> adminTeacher(String id) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminTeacher(id));
      return TeacherDto.fromJson(json!);
    });
  }

  Future<MasterTeacherDashboardDto> adminTeacherDashboard(String id) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminTeacherDashboard(id));
      return MasterTeacherDashboardDto.fromJson(json!);
    });
  }

  Future<TeacherDto> updateTeacher(String id, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.put(ApiEndpoints.adminTeacher(id), data: data);
      return TeacherDto.fromJson(json!);
    });
  }

  Future<TeacherDto> createTeacher(Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminTeachers, data: data);
      return TeacherDto.fromJson(json!);
    });
  }

  Future<PagedResult> adminBatches({
    String? search,
    String? careerCompassLevelId,
    String? status,
    bool withoutCommonTeacher = false,
    bool full = false,
    int page = 1,
    int perPage = 25,
  }) {
    return _run(
      () => _client.getPage(
        ApiEndpoints.adminBatches,
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (careerCompassLevelId != null && careerCompassLevelId.isNotEmpty)
            'career_compass_level_id': careerCompassLevelId,
          if (status != null && status.isNotEmpty) 'status': status,
          if (withoutCommonTeacher) 'without_common_teacher': 'true',
          if (full) 'full': 'true',
          'page': '$page',
          'per_page': '$perPage',
        },
      ),
    );
  }

  Future<BatchDto> createBatch(Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminBatches, data: data);
      return BatchDto.fromJson(json!);
    });
  }

  Future<BatchDto> adminBatch(String id) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminBatch(id));
      return BatchDto.fromJson(json!);
    });
  }

  Future<List<StudentDto>> adminBatchStudents(String batchId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.adminBatchStudents(batchId));
      return _students(items);
    });
  }

  Future<BatchDto> enrollStudent({required String batchId, required String studentId}) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.adminBatchStudents(batchId),
        data: {'student_id': studentId},
      );
      return BatchDto.fromJson(json!);
    });
  }

  Future<BatchDto> unenrollStudent({required String batchId, required String studentId}) {
    return _run(() async {
      final json = await _client.delete(ApiEndpoints.adminBatchStudent(batchId, studentId));
      return BatchDto.fromJson(json!);
    });
  }

  Future<BatchDto> updateBatch(String id, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.put(ApiEndpoints.adminBatch(id), data: data);
      return BatchDto.fromJson(json!);
    });
  }

  Future<BatchDto> toggleBatchStatus(String batchId) {
    return _run(() async {
      final json = await _client.patch(ApiEndpoints.adminBatchStatus(batchId));
      return BatchDto.fromJson(json!);
    });
  }

  Future<List<AcademicLevelDto>> adminLevels() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.adminLevels);
      return items
          .whereType<Map>()
          .map((item) => AcademicLevelDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    });
  }

  Future<AcademicLevelDto> adminLevel(String id) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.adminLevel(id));
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<AcademicLevelDto> createLevel(Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminLevels, data: data);
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<AcademicLevelDto> updateLevel(String id, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.put(ApiEndpoints.adminLevel(id), data: data);
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<BatchDto> createLevelBatch(String levelId, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.adminLevelBatches(levelId), data: data);
      return BatchDto.fromJson(json!);
    });
  }

  Future<AcademicLevelDto> assignLevelTeacher({
    required String levelId,
    required String teacherId,
  }) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.adminLevelTeachers(levelId),
        data: {'teacher_id': teacherId},
      );
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<AcademicLevelDto> unassignLevelTeacher({
    required String levelId,
    required String teacherId,
  }) {
    return _run(() async {
      final json = await _client.delete(ApiEndpoints.adminLevelTeacher(levelId, teacherId));
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<BatchDto> unassignCommonTeacher(String batchId) {
    return _run(() async {
      final json = await _client.delete(ApiEndpoints.adminBatchTeacher(batchId));
      return BatchDto.fromJson(json!);
    });
  }

  Future<StudentDto> unassignMasterTeacher(String studentId) {
    return _run(() async {
      final json = await _client.delete(ApiEndpoints.adminStudentMentor(studentId));
      return StudentDto.fromJson(json!);
    });
  }

  Future<List<AssessmentDto>> teacherBatchAssessments(String batchId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.teacherBatchAssessments(batchId));
      return _assessments(items);
    });
  }

  Future<AssessmentDto> createAssessment(String batchId, Map<String, dynamic> data) {
    return _run(() async {
      final json = await _client.post(ApiEndpoints.teacherBatchAssessments(batchId), data: data);
      return AssessmentDto.fromJson(json!);
    });
  }

  Future<AssessmentDto> teacherAssessment(String batchId, String assessmentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.teacherAssessment(batchId, assessmentId));
      return AssessmentDto.fromJson(json!);
    });
  }

  Future<AssessmentDto> updateAssessment(
    String batchId,
    String assessmentId,
    Map<String, dynamic> data,
  ) {
    return _run(() async {
      final json = await _client.put(
        ApiEndpoints.teacherAssessment(batchId, assessmentId),
        data: data,
      );
      return AssessmentDto.fromJson(json!);
    });
  }

  Future<AssessmentScoresPayload> teacherAssessmentScores(String batchId, String assessmentId) {
    return _run(() async {
      final envelope = await _client.getPage(
        ApiEndpoints.teacherAssessmentScores(batchId, assessmentId),
      );
      return AssessmentScoresPayload(
        scores: _assessmentScores(envelope.items),
        version: (envelope.meta['version'] as num?)?.toInt() ?? 1,
        currentVersion: (envelope.meta['current_version'] as num?)?.toInt() ?? 1,
      );
    });
  }

  Future<AssessmentScoresPayload> recordAssessmentScores(
    String batchId,
    String assessmentId,
    List<Map<String, dynamic>> scores,
  ) {
    return _run(() async {
      final json = await _client.put(
        ApiEndpoints.teacherAssessmentScores(batchId, assessmentId),
        data: {'scores': scores},
      );
      final assessment = AssessmentDto.fromJson(
        Map<String, dynamic>.from(json!['assessment'] as Map),
      );
      final scoreItems = (json['scores'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AssessmentScoreDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return AssessmentScoresPayload(
        assessment: assessment,
        scores: scoreItems,
        version: assessment.version,
        currentVersion: assessment.version,
      );
    });
  }

  List<AssessmentDto> _assessments(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((item) => AssessmentDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  List<AssessmentScoreDto> _assessmentScores(List<dynamic> items) {
    return items
        .whereType<Map>()
        .map((item) => AssessmentScoreDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<BatchDto> assignCommonTeacher({required String batchId, required String teacherId}) {
    return _run(() async {
      final json = await _client.post(
        ApiEndpoints.adminBatchTeacher(batchId),
        data: {'teacher_id': teacherId},
      );
      return BatchDto.fromJson(json!);
    });
  }

  Future<List<BatchDto>> teacherBatches() {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.teacherBatches);
      return _batches(items);
    });
  }

  Future<List<StudentDto>> teacherBatchStudents(String batchId) {
    return _run(() async {
      final items = await _client.getList(ApiEndpoints.teacherBatchStudents(batchId));
      return _students(items);
    });
  }

  Future<StudentDto> teacherStudent(String studentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.teacherStudent(studentId));
      return StudentDto.fromJson(json!);
    });
  }

  Future<MasterTeacherRosterDto> masterTeacherStudents(MasterTeacherStudentsFilter filter) {
    return _run(() async {
      final page = await _client.getPage(
        ApiEndpoints.masterTeacherStudents,
        query: filter.toQuery(),
      );
      final levels = (page.meta['levels'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => MasterTeacherRosterLevelDto.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      return MasterTeacherRosterDto(students: _students(page.items), levels: levels);
    });
  }

  Future<StudentDto> masterTeacherStudent(String studentId) {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.masterTeacherStudent(studentId));
      return StudentDto.fromJson(json!);
    });
  }

  Future<MasterTeacherDashboardDto> masterTeacherDashboard() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.masterTeacherDashboard);
      return MasterTeacherDashboardDto.fromJson(json!);
    });
  }

  Future<StudentDto> studentProfile() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.studentProfile);
      return StudentDto.fromJson(json!);
    });
  }

  Future<TeacherDto> teacherProfile() {
    return _run(() async {
      final json = await _client.get(ApiEndpoints.teacherProfile);
      return TeacherDto.fromJson(json!);
    });
  }

  List<TeacherDto> parseTeachers(PagedResult page) => _teachers(page.items);

  List<StudentDto> parseStudents(PagedResult page) => _students(page.items);

  List<BatchDto> parseBatches(PagedResult page) => _batches(page.items);
}
