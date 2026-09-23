import 'package:excellent_educators_web/core/constants/api_endpoints.dart';
import 'package:excellent_educators_web/core/network/api_client.dart';
import 'package:excellent_educators_web/core/network/maps_api_failures.dart';
import 'package:excellent_educators_web/features/academic/data/dto/academic_dtos.dart';
import 'package:excellent_educators_web/features/academic/presentation/providers/master_teacher_students_filter.dart';

class AcademicRepository with MapsApiFailures {
  AcademicRepository(this._client);

  final ApiClient _client;

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

  Future<AdminDashboardDto> adminDashboard({int? year, int? month}) {
    return runApi(() async {
      final json = await _client.get(
        ApiEndpoints.adminDashboard,
        query: {
          if (year != null) 'year': year.toString(),
          if (month != null) 'month': month.toString(),
        },
      );
      return AdminDashboardDto.fromJson(json!);
    });
  }

  Future<PagedResult> adminStudents({
    String? search,
    String? status,
    String? levelId,
    String? batchId,
    bool withoutBatch = false,
    bool withoutMasterTeacher = false,
    bool assessmentPending = false,
    bool withoutRatingThisMonth = false,
    String? spotlight,
    int page = 1,
    int perPage = 25,
  }) {
    return runApi(
      () => _client.getPage(
        ApiEndpoints.adminStudents,
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (levelId != null && levelId.isNotEmpty) 'level_id': levelId,
          if (batchId != null && batchId.isNotEmpty) 'batch_id': batchId,
          if (withoutBatch) 'without_batch': 'true',
          if (withoutMasterTeacher) 'without_master_teacher': 'true',
          if (assessmentPending) 'assessment_pending': 'true',
          if (withoutRatingThisMonth) 'without_rating_this_month': 'true',
          if (spotlight != null && spotlight.isNotEmpty) 'spotlight': spotlight,
          'page': '$page',
          'per_page': '$perPage',
        },
      ),
    );
  }

  Future<StudentDto> adminStudent(String id) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminStudent(id));
      return StudentDto.fromJson(json!);
    });
  }

  Future<StudentDto> updateStudent(String id, Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.put(ApiEndpoints.adminStudent(id), data: data);
      return StudentDto.fromJson(json!);
    });
  }

  Future<List<StudentActivityDto>> studentHistory(String id) {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.adminStudentHistory(id));
      return items
          .whereType<Map>()
          .map(
            (item) =>
                StudentActivityDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    });
  }

  Future<StudentDto> createStudent(Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.adminStudents, data: data);
      return StudentDto.fromJson(json!);
    });
  }

  Future<void> deleteStudent(String id) {
    return runApi(() async {
      await _client.delete(ApiEndpoints.adminStudent(id));
    });
  }

  Future<PagedResult> adminSubAdmins({
    String? search,
    String? status,
    int page = 1,
  }) {
    return runApi(
      () => _client.getPage(
        ApiEndpoints.adminSubAdmins,
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          'page': '$page',
        },
      ),
    );
  }

  Future<SubAdminDto> adminSubAdmin(String id) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminSubAdmin(id));
      return SubAdminDto.fromJson(json!);
    });
  }

  Future<List<PermissionCatalogGroupDto>> subAdminPermissionCatalog() {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.adminSubAdminPermissions,
      );
      return items
          .whereType<Map>()
          .map(
            (item) => PermissionCatalogGroupDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    });
  }

  Future<SubAdminDto> createSubAdmin(Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.adminSubAdmins, data: data);
      return SubAdminDto.fromJson(json!);
    });
  }

  Future<SubAdminDto> updateSubAdmin(String id, Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.put(
        ApiEndpoints.adminSubAdmin(id),
        data: data,
      );
      return SubAdminDto.fromJson(json!);
    });
  }

  Future<void> deleteSubAdmin(String id) {
    return runApi(() async {
      await _client.delete(ApiEndpoints.adminSubAdmin(id));
    });
  }

  Future<List<StudentActivityDto>> subAdminHistory(String id) {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.adminSubAdminHistory(id),
      );
      return items
          .whereType<Map>()
          .map(
            (item) =>
                StudentActivityDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    });
  }

  List<SubAdminDto> parseSubAdmins(PagedResult page) {
    return page.items
        .whereType<Map>()
        .map((item) => SubAdminDto.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<StudentDto> assignMasterTeacher({
    required String studentId,
    required String teacherId,
  }) {
    return runApi(() async {
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
    return runApi(
      () => _client.getPage(
        ApiEndpoints.adminTeachers,
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (role != null && role.isNotEmpty) 'role': role,
          if (excludeLevelId != null && excludeLevelId.isNotEmpty)
            'exclude_level_id': excludeLevelId,
          'page': page,
          'per_page': perPage,
        },
      ),
    );
  }

  Future<TeacherDto> adminTeacher(String id) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminTeacher(id));
      return TeacherDto.fromJson(json!);
    });
  }

  Future<MasterTeacherDashboardDto> adminTeacherDashboard(String id) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminTeacherDashboard(id));
      return MasterTeacherDashboardDto.fromJson(json!);
    });
  }

  Future<TeacherHistoryDto> adminTeacherHistory(String id) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminTeacherHistory(id));
      return TeacherHistoryDto.fromJson(json!);
    });
  }

  Future<List<StudentDto>> adminTeacherPromotedStudents(String id) {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.adminTeacherPromotedStudents(id),
      );
      return _students(items);
    });
  }

  Future<TeacherDto> updateTeacher(String id, Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.put(ApiEndpoints.adminTeacher(id), data: data);
      return TeacherDto.fromJson(json!);
    });
  }

  Future<TeacherDto> createTeacher(Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.adminTeachers, data: data);
      return TeacherDto.fromJson(json!);
    });
  }

  Future<void> deleteTeacher(String id) {
    return runApi(() async {
      await _client.delete(ApiEndpoints.adminTeacher(id));
    });
  }

  Future<PagedResult> adminBatches({
    String? search,
    String? status,
    bool full = false,
    int page = 1,
    int perPage = 25,
  }) {
    return runApi(
      () => _client.getPage(
        ApiEndpoints.adminBatches,
        query: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null && status.isNotEmpty) 'status': status,
          if (full) 'full': 'true',
          'page': '$page',
          'per_page': '$perPage',
        },
      ),
    );
  }

  Future<BatchDto> createBatch(Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.adminBatches, data: data);
      return BatchDto.fromJson(json!);
    });
  }

  Future<BatchDto> adminBatch(String id) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminBatch(id));
      return BatchDto.fromJson(json!);
    });
  }

  Future<List<StudentDto>> adminBatchStudents(String batchId) {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.adminBatchStudents(batchId),
      );
      return _students(items);
    });
  }

  Future<BatchDto> enrollStudent({
    required String batchId,
    required String studentId,
  }) {
    return runApi(() async {
      final json = await _client.post(
        ApiEndpoints.adminBatchStudents(batchId),
        data: {'student_id': studentId},
      );
      return BatchDto.fromJson(json!);
    });
  }

  Future<BatchDto> unenrollStudent({
    required String batchId,
    required String studentId,
  }) {
    return runApi(() async {
      final json = await _client.delete(
        ApiEndpoints.adminBatchStudent(batchId, studentId),
      );
      return BatchDto.fromJson(json!);
    });
  }

  Future<BatchDto> updateBatch(String id, Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.put(ApiEndpoints.adminBatch(id), data: data);
      return BatchDto.fromJson(json!);
    });
  }

  Future<BatchDto> toggleBatchStatus(String batchId) {
    return runApi(() async {
      final json = await _client.patch(ApiEndpoints.adminBatchStatus(batchId));
      return BatchDto.fromJson(json!);
    });
  }

  Future<List<AcademicLevelDto>> adminLevels() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.adminLevels);
      return items
          .whereType<Map>()
          .map(
            (item) =>
                AcademicLevelDto.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    });
  }

  Future<AcademicLevelDto> adminLevel(String id) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.adminLevel(id));
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<AcademicLevelDto> createLevel(Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.post(ApiEndpoints.adminLevels, data: data);
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<AcademicLevelDto> updateLevel(String id, Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.put(ApiEndpoints.adminLevel(id), data: data);
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<BatchDto> createLevelBatch(String levelId, Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.post(
        ApiEndpoints.adminLevelBatches(levelId),
        data: data,
      );
      return BatchDto.fromJson(json!);
    });
  }

  Future<AcademicLevelDto> assignLevelTeacher({
    required String levelId,
    required String teacherId,
  }) {
    return runApi(() async {
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
    return runApi(() async {
      final json = await _client.delete(
        ApiEndpoints.adminLevelTeacher(levelId, teacherId),
      );
      return AcademicLevelDto.fromJson(json!);
    });
  }

  Future<StudentDto> unassignMasterTeacher(String studentId) {
    return runApi(() async {
      final json = await _client.delete(
        ApiEndpoints.adminStudentMentor(studentId),
      );
      return StudentDto.fromJson(json!);
    });
  }

  Future<List<AssessmentDto>> teacherBatchAssessments(String batchId) {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.teacherBatchAssessments(batchId),
      );
      return _assessments(items);
    });
  }

  Future<AssessmentDto> createAssessment(
    String batchId,
    Map<String, dynamic> data,
  ) {
    return runApi(() async {
      final json = await _client.post(
        ApiEndpoints.teacherBatchAssessments(batchId),
        data: data,
      );
      return AssessmentDto.fromJson(json!);
    });
  }

  Future<AssessmentDto> teacherAssessment(String batchId, String assessmentId) {
    return runApi(() async {
      final json = await _client.get(
        ApiEndpoints.teacherAssessment(batchId, assessmentId),
      );
      return AssessmentDto.fromJson(json!);
    });
  }

  Future<AssessmentDto> updateAssessment(
    String batchId,
    String assessmentId,
    Map<String, dynamic> data,
  ) {
    return runApi(() async {
      final json = await _client.put(
        ApiEndpoints.teacherAssessment(batchId, assessmentId),
        data: data,
      );
      return AssessmentDto.fromJson(json!);
    });
  }

  Future<AssessmentScoresPayload> teacherAssessmentScores(
    String batchId,
    String assessmentId,
  ) {
    return runApi(() async {
      final envelope = await _client.getPage(
        ApiEndpoints.teacherAssessmentScores(batchId, assessmentId),
      );
      return AssessmentScoresPayload(
        scores: _assessmentScores(envelope.items),
        version: (envelope.meta['version'] as num?)?.toInt() ?? 1,
        currentVersion:
            (envelope.meta['current_version'] as num?)?.toInt() ?? 1,
      );
    });
  }

  Future<AssessmentScoresPayload> recordAssessmentScores(
    String batchId,
    String assessmentId,
    List<Map<String, dynamic>> scores,
  ) {
    return runApi(() async {
      final json = await _client.put(
        ApiEndpoints.teacherAssessmentScores(batchId, assessmentId),
        data: {'scores': scores},
      );
      final assessment = AssessmentDto.fromJson(
        Map<String, dynamic>.from(json!['assessment'] as Map),
      );
      final scoreItems = (json['scores'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                AssessmentScoreDto.fromJson(Map<String, dynamic>.from(item)),
          )
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
        .map(
          (item) =>
              AssessmentScoreDto.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  Future<List<BatchDto>> teacherBatches() {
    return runApi(() async {
      final items = await _client.getList(ApiEndpoints.teacherBatches);
      return _batches(items);
    });
  }

  Future<List<StudentDto>> teacherBatchStudents(String batchId) {
    return runApi(() async {
      final items = await _client.getList(
        ApiEndpoints.teacherBatchStudents(batchId),
      );
      return _students(items);
    });
  }

  Future<StudentDto> teacherStudent(String studentId) {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.teacherStudent(studentId));
      return StudentDto.fromJson(json!);
    });
  }

  Future<MasterTeacherRosterDto> masterTeacherStudents(
    MasterTeacherStudentsFilter filter,
  ) {
    return runApi(() async {
      final page = await _client.getPage(
        ApiEndpoints.masterTeacherStudents,
        query: filter.toQuery(),
      );
      final levels = (page.meta['levels'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map(
            (item) => MasterTeacherRosterLevelDto.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
      return MasterTeacherRosterDto(
        students: _students(page.items),
        levels: levels,
      );
    });
  }

  Future<StudentDto> masterTeacherStudent(String studentId) {
    return runApi(() async {
      final json = await _client.get(
        ApiEndpoints.masterTeacherStudent(studentId),
      );
      return StudentDto.fromJson(json!);
    });
  }

  Future<MasterTeacherDashboardDto> masterTeacherDashboard() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.masterTeacherDashboard);
      return MasterTeacherDashboardDto.fromJson(json!);
    });
  }

  Future<StudentDto> studentProfile() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.studentProfile);
      return StudentDto.fromJson(json!);
    });
  }

  Future<TeacherDto> teacherProfile() {
    return runApi(() async {
      final json = await _client.get(ApiEndpoints.teacherProfile);
      return TeacherDto.fromJson(json!);
    });
  }

  Future<TeacherDto> updateTeacherProfile(Map<String, dynamic> data) {
    return runApi(() async {
      final json = await _client.put(ApiEndpoints.teacherProfile, data: data);
      return TeacherDto.fromJson(json!);
    });
  }

  Future<TeacherDto> studentMentorProfile(String teacherId) {
    return runApi(() async {
      final json = await _client.get(
        ApiEndpoints.studentBookingTeacher(teacherId),
      );
      return TeacherDto.fromJson(json!);
    });
  }

  List<TeacherDto> parseTeachers(PagedResult page) => _teachers(page.items);

  List<StudentDto> parseStudents(PagedResult page) => _students(page.items);

  List<BatchDto> parseBatches(PagedResult page) => _batches(page.items);
}
