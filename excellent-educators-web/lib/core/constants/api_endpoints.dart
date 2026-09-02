abstract final class ApiEndpoints {
  static const login = '/api/v1/auth/login';
  static const logout = '/api/v1/auth/logout';
  static const me = '/api/v1/auth/me';
  static const changePassword = '/api/v1/auth/password';
  static const forgotPassword = '/api/v1/auth/forgot-password';
  static const resetPassword = '/api/v1/auth/reset-password';
  static const loginPageContent = '/api/v1/auth/login-page';

  static const careerCompassLevels = '/api/v1/admin/career-compass-levels';
  static const adminDashboard = '/api/v1/admin/dashboard';
  static const adminStudents = '/api/v1/admin/students';
  static String adminStudent(String id) => '/api/v1/admin/students/$id';
  static String adminStudentMentor(String id) => '/api/v1/admin/students/$id/mentor';
  static const adminTeachers = '/api/v1/admin/teachers';
  static String adminTeacher(String id) => '/api/v1/admin/teachers/$id';
  static String adminTeacherDashboard(String id) => '/api/v1/admin/teachers/$id/dashboard';
  static const adminBatches = '/api/v1/admin/batches';
  static String adminBatch(String id) => '/api/v1/admin/batches/$id';
  static String adminBatchStudents(String id) => '/api/v1/admin/batches/$id/students';
  static String adminBatchStudent(String batchId, String studentId) =>
      '/api/v1/admin/batches/$batchId/students/$studentId';
  static String adminBatchTeacher(String id) => '/api/v1/admin/batches/$id/teacher';

  static const teacherBatches = '/api/v1/teacher/batches';
  static const teacherProfile = '/api/v1/teacher/profile';
  static String teacherBatchStudents(String id) => '/api/v1/teacher/batches/$id/students';
  static String teacherBatchAssessments(String batchId) => '/api/v1/teacher/batches/$batchId/assessments';
  static String teacherAssessment(String batchId, String assessmentId) =>
      '/api/v1/teacher/batches/$batchId/assessments/$assessmentId';
  static String teacherAssessmentScores(String batchId, String assessmentId) =>
      '/api/v1/teacher/batches/$batchId/assessments/$assessmentId/scores';

  static const masterTeacherStudents = '/api/v1/master-teacher/students';
  static const masterTeacherDashboard = '/api/v1/master-teacher/dashboard';
  static String masterTeacherStudent(String id) => '/api/v1/master-teacher/students/$id';

  static const studentProfile = '/api/v1/student/profile';
  static const studentAssessment = '/api/v1/student/assessment';
  static String studentAssessmentSubmit(String id) => '/api/v1/student/assessment/$id/submit';
  static const studentFeedback = '/api/v1/student/feedback';
  static const studentFeedbackSummary = '/api/v1/student/feedback/summary';

  static const adminAssessments = '/api/v1/admin/assessments';
  static String adminAssessment(String id) => '/api/v1/admin/assessments/$id';
  static String adminAssessmentActivate(String id) => '/api/v1/admin/assessments/$id/activate';
  static String adminAssessmentDeactivate(String id) => '/api/v1/admin/assessments/$id/deactivate';
  static String adminAssessmentAttempts(String id) => '/api/v1/admin/assessments/$id/attempts';
  static String adminStudentResults(String id) => '/api/v1/admin/students/$id/results';
  static String adminStudentFeedback(String id) => '/api/v1/admin/students/$id/feedback';
  static String adminStudentFeedbackItem(String studentId, String feedbackId) =>
      '/api/v1/admin/students/$studentId/feedback/$feedbackId';
  static String adminStudentFeedbackSummary(String id) => '/api/v1/admin/students/$id/feedback/summary';
  static const adminFeedbackCatalog = '/api/v1/admin/feedback-catalog';
  static const adminLoginPageContent = '/api/v1/admin/login-page';

  static const masterTeacherCatalog = '/api/v1/master-teacher/feedback-catalog';
  static String masterTeacherFeedback(String studentId) => '/api/v1/master-teacher/students/$studentId/feedback';
  static String masterTeacherFeedbackSummary(String studentId) =>
      '/api/v1/master-teacher/students/$studentId/feedback/summary';
  static String masterTeacherFeedbackItem(String studentId, String feedbackId) =>
      '/api/v1/master-teacher/students/$studentId/feedback/$feedbackId';
  static String masterTeacherStudentResults(String studentId) =>
      '/api/v1/master-teacher/students/$studentId/results';

  static String teacherStudentResults(String studentId) => '/api/v1/teacher/students/$studentId/results';
  static String teacherStudent(String studentId) => '/api/v1/teacher/students/$studentId';
  static String teacherStudentFeedback(String studentId) => '/api/v1/teacher/students/$studentId/feedback';
  static String teacherStudentFeedbackSummary(String studentId) =>
      '/api/v1/teacher/students/$studentId/feedback/summary';

  static const studentRequests = '/api/v1/student/requests';
  static const teacherRequests = '/api/v1/teacher/requests';
  static const adminRequests = '/api/v1/admin/requests';
  static String adminRequest(String id) => '/api/v1/admin/requests/$id';
  static String adminRequestResolve(String id) => '/api/v1/admin/requests/$id/resolve';

  static const notifications = '/api/v1/notifications';
  static const notificationsUnreadCount = '/api/v1/notifications/unread-count';
  static const notificationsReadAll = '/api/v1/notifications/read-all';
  static String notificationRead(String id) => '/api/v1/notifications/$id/read';
}
