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
  static String adminBatchStatus(String id) => '/api/v1/admin/batches/$id/status';
  static String adminBatchStudents(String id) => '/api/v1/admin/batches/$id/students';
  static String adminBatchStudent(String batchId, String studentId) =>
      '/api/v1/admin/batches/$batchId/students/$studentId';
  static String adminBatchTeacher(String id) => '/api/v1/admin/batches/$id/teacher';

  static const adminLevels = '/api/v1/admin/levels';
  static String adminLevel(String id) => '/api/v1/admin/levels/$id';
  static String adminLevelBatches(String levelId) => '/api/v1/admin/levels/$levelId/batches';
  static String adminLevelTeachers(String levelId) => '/api/v1/admin/levels/$levelId/teachers';
  static String adminLevelTeacher(String levelId, String teacherId) =>
      '/api/v1/admin/levels/$levelId/teachers/$teacherId';
  static String adminLevelWeeklyLearnings(String levelId) =>
      '/api/v1/admin/levels/$levelId/weekly-learnings';
  static String adminStudentLearningJournal(String studentId) =>
      '/api/v1/admin/students/$studentId/learning-journal';
  static String adminStudentLearningWeek(String studentId, String journeyId, int week) =>
      '/api/v1/admin/students/$studentId/learning-journal/$journeyId/$week';
  static String adminStudentPromote(String studentId) => '/api/v1/admin/students/$studentId/promote';

  static const studentLearningDashboard = '/api/v1/student/learning/dashboard';
  static const studentLearningJournal = '/api/v1/student/learning/journal';
  static String studentLearningWeek(String journeyId, int week) =>
      '/api/v1/student/learning/journal/$journeyId/$week';

  static String masterTeacherStudentLearningJournal(String studentId) =>
      '/api/v1/master-teacher/students/$studentId/learning-journal';
  static String masterTeacherStudentLearningWeek(String studentId, String journeyId, int week) =>
      '/api/v1/master-teacher/students/$studentId/learning-journal/$journeyId/$week';
  static String masterTeacherStudentPromote(String studentId) =>
      '/api/v1/master-teacher/students/$studentId/promote';

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
  static const adminSettings = '/api/v1/admin/settings';

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
  static String teacherStudentLearningJournal(String studentId) =>
      '/api/v1/teacher/students/$studentId/learning-journal';
  static String teacherStudentLearningWeek(String studentId, String journeyId, int week) =>
      '/api/v1/teacher/students/$studentId/learning-journal/$journeyId/$week';

  static const studentRequests = '/api/v1/student/requests';
  static const teacherRequests = '/api/v1/teacher/requests';
  static const adminRequests = '/api/v1/admin/requests';
  static String adminRequest(String id) => '/api/v1/admin/requests/$id';
  static String adminRequestResolve(String id) => '/api/v1/admin/requests/$id/resolve';

  static const notifications = '/api/v1/notifications';
  static const notificationsUnreadCount = '/api/v1/notifications/unread-count';
  static const notificationsReadAll = '/api/v1/notifications/read-all';
  static String notificationRead(String id) => '/api/v1/notifications/$id/read';

  static const teacherScheduleDay = '/api/v1/teacher/schedule/day';
  static const teacherScheduleWeek = '/api/v1/teacher/schedule/week';
  static const teacherScheduleMonth = '/api/v1/teacher/schedule/month';
  static const teacherScheduleBreaks = '/api/v1/teacher/schedule/breaks';
  static const teacherScheduleLeaves = '/api/v1/teacher/schedule/leaves';
  static String teacherScheduleLeave(String id) => '/api/v1/teacher/schedule/leaves/$id';

  static const studentBookings = '/api/v1/student/bookings';
  static const studentBookingEligibility = '/api/v1/student/bookings/eligibility';
  static const studentBookingTeachers = '/api/v1/student/bookings/teachers';
  static const studentBookingAvailability = '/api/v1/student/bookings/availability';
  static String studentBooking(String id) => '/api/v1/student/bookings/$id';
  static String studentBookingJoin(String id) => '/api/v1/student/bookings/$id/join';
  static String studentBookingAttendanceReport(String id) => '/api/v1/student/bookings/$id/attendance-reports';
  static String teacherBookingJoin(String id) => '/api/v1/teacher/schedule/bookings/$id/join';
  static String teacherBookingAttendanceReport(String id) => '/api/v1/teacher/schedule/bookings/$id/attendance-reports';
  static String teacherBookingWhatsApp(String id) => '/api/v1/teacher/schedule/bookings/$id/whatsapp';
  static const adminAttendance = '/api/v1/admin/attendance';
  static String adminAttendanceItem(String id) => '/api/v1/admin/attendance/$id';
  static String adminAttendanceResolve(String id) => '/api/v1/admin/attendance/$id/resolve';

  static const adminScheduleTeachers = '/api/v1/admin/schedule/teachers';
  static const adminScheduleDay = '/api/v1/admin/schedule/day';
  static const adminScheduleMonth = '/api/v1/admin/schedule/month';
  static const adminScheduleLeaves = '/api/v1/admin/schedule/leaves';
  static const adminScheduleBookings = '/api/v1/admin/schedule/bookings';
  static String adminTeacherAvailability(String teacherId) =>
      '/api/v1/admin/schedule/teachers/$teacherId/availability';
  static String adminTeacherAvailabilityOverrides(String teacherId) =>
      '/api/v1/admin/schedule/teachers/$teacherId/availability/overrides';
  static String adminTeacherAvailabilityOverride(String teacherId, String overrideId) =>
      '/api/v1/admin/schedule/teachers/$teacherId/availability/overrides/$overrideId';
  static String adminTeacherBreaks(String teacherId) => '/api/v1/admin/schedule/teachers/$teacherId/breaks';
  static String adminTeacherLeaves(String teacherId) => '/api/v1/admin/schedule/teachers/$teacherId/leaves';
  static String adminScheduleLeave(String id) => '/api/v1/admin/schedule/leaves/$id';
  static String adminScheduleBooking(String id) => '/api/v1/admin/schedule/bookings/$id';

  static const adminGoogleMeet = '/api/v1/admin/google/meet';
  static const adminGoogleMeetAuthorize = '/api/v1/admin/google/meet/authorize';
}
