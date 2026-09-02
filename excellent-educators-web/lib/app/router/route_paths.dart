abstract final class RoutePaths {
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const changePassword = '/change-password';
  static const session = '/session';
  static const adminDashboard = '/admin/dashboard';
  static const adminStudents = '/admin/students';
  static const adminStudentNew = '/admin/students/new';
  static const adminStudentDetail = '/admin/students/:id';
  static const adminStudentResults = '/admin/students/:id/results';
  static const adminTeachers = '/admin/teachers';
  static const adminTeacherNew = '/admin/teachers/new';
  static const adminTeacherDetail = '/admin/teachers/:id';
  static const adminBatches = '/admin/batches';
  static const adminBatchNew = '/admin/batches/new';
  static const adminBatchDetail = '/admin/batches/:id';
  static const teacherBatches = '/teacher/batches';
  static const teacherBatchStudents = '/teacher/batches/:id/students';
  static const teacherBatchAssessments = '/teacher/batches/:id/assessments';
  static const teacherAssessmentNew = '/teacher/batches/:batchId/assessments/new';
  static const teacherAssessmentDetail = '/teacher/batches/:batchId/assessments/:assessmentId';
  static const teacherStudentResults = '/teacher/students/:id/results';
  static const masterTeacherStudents = '/master-teacher/students';
  static const masterTeacherDashboard = '/master-teacher/dashboard';
  static const masterTeacherStudentDetail = '/master-teacher/students/:id';
  static const masterTeacherFeedbackNew = '/master-teacher/students/:id/feedback/new';
  static const masterTeacherFeedbackEdit = '/master-teacher/students/:id/feedback/:feedbackId/edit';
  static const teacherProfile = '/teacher/profile';
  static const teacherRequests = '/teacher/requests';
  static const teacherRequestNew = '/teacher/requests/new';
  static const studentDashboard = '/student/dashboard';
  static const studentProfile = '/student/profile';
  static const studentFeedback = '/student/feedback';
  static const studentRequests = '/student/requests';
  static const studentRequestNew = '/student/requests/new';
  static const adminAssessments = '/admin/assessments';
  static const adminAssessmentNew = '/admin/assessments/new';
  static const adminAssessmentDetail = '/admin/assessments/:id';
  static const adminAssessmentAttempts = '/admin/assessments/:id/attempts';
  static const adminRequests = '/admin/requests';
  static const adminLoginPage = '/admin/login-page';
  static const adminRequestDetail = '/admin/requests/:id';
  static const adminFeedbackNew = '/admin/students/:id/feedback/new';
  static const adminFeedbackEdit = '/admin/students/:id/feedback/:feedbackId/edit';

  static String adminBatch(String id) => '/admin/batches/$id';
  static String adminStudent(String id) => '/admin/students/$id';
  static String adminStudentResultsFor(String id) => '/admin/students/$id/results';
  static String adminTeacher(String id) => '/admin/teachers/$id';
  static String teacherBatch(String id) => '/teacher/batches/$id/students';
  static String teacherAssessmentsFor(String id) => '/teacher/batches/$id/assessments';
  static String teacherAssessmentNewFor(String batchId) => '/teacher/batches/$batchId/assessments/new';
  static String teacherAssessmentFor(String batchId, String assessmentId) =>
      '/teacher/batches/$batchId/assessments/$assessmentId';
  static String masterTeacherStudentFor(String id) => '/master-teacher/students/$id';
  static String masterTeacherFeedbackNewFor(String id) => '/master-teacher/students/$id/feedback/new';
  static String masterTeacherFeedbackEditFor(String studentId, String feedbackId) =>
      '/master-teacher/students/$studentId/feedback/$feedbackId/edit';
  static String adminAssessmentFor(String id) => '/admin/assessments/$id';
  static String adminAssessmentAttemptsFor(String id) => '/admin/assessments/$id/attempts';
  static String adminFeedbackNewFor(String id) => '/admin/students/$id/feedback/new';
  static String adminFeedbackEditFor(String studentId, String feedbackId) =>
      '/admin/students/$studentId/feedback/$feedbackId/edit';
  static String adminRequestFor(String id) => '/admin/requests/$id';
  static String teacherStudentResultsFor(String id) => '/teacher/students/$id/results';

  static String homeFor({
    required bool isAdmin,
    required bool isCommonTeacher,
    required bool isMasterTeacher,
    required bool isStudent,
  }) {
    if (isAdmin) {
      return adminDashboard;
    }
    if (isCommonTeacher) {
      return teacherBatches;
    }
    if (isMasterTeacher) {
      return masterTeacherDashboard;
    }
    if (isStudent) {
      return studentDashboard;
    }
    return session;
  }
}
