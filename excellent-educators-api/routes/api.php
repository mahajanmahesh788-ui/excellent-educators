<?php

use App\Http\Controllers\Api\V1\Admin\AcademicLevelController;
use App\Http\Controllers\Api\V1\Admin\AdminRequestController as AdminAdminRequestController;
use App\Http\Controllers\Api\V1\Admin\AptitudeAssessmentController as AdminAptitudeAssessmentController;
use App\Http\Controllers\Api\V1\Admin\AttendanceController as AdminAttendanceController;
use App\Http\Controllers\Api\V1\Admin\BatchController as AdminBatchController;
use App\Http\Controllers\Api\V1\Admin\DashboardController;
use App\Http\Controllers\Api\V1\Admin\DevelopmentController as AdminDevelopmentController;
use App\Http\Controllers\Api\V1\Admin\GoogleMeetController as AdminGoogleMeetController;
use App\Http\Controllers\Api\V1\Admin\LoginPageContentController as AdminLoginPageContentController;
use App\Http\Controllers\Api\V1\Admin\ScheduleController as AdminScheduleController;
use App\Http\Controllers\Api\V1\Admin\SettingsController as AdminSettingsController;
use App\Http\Controllers\Api\V1\Admin\StudentController as AdminStudentController;
use App\Http\Controllers\Api\V1\Admin\StudentLearningController as AdminStudentLearningController;
use App\Http\Controllers\Api\V1\Admin\StudentMentorController;
use App\Http\Controllers\Api\V1\Admin\SubAdminController;
use App\Http\Controllers\Api\V1\Admin\TeacherController as AdminTeacherController;
use App\Http\Controllers\Api\V1\Admin\WeeklyLearningController as AdminWeeklyLearningController;
use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\Auth\LoginPageController;
use App\Http\Controllers\Api\V1\MasterTeacher\DashboardController as MasterTeacherDashboardController;
use App\Http\Controllers\Api\V1\MasterTeacher\FeedbackController as MasterTeacherFeedbackController;
use App\Http\Controllers\Api\V1\MasterTeacher\StudentController as MasterTeacherStudentController;
use App\Http\Controllers\Api\V1\MasterTeacher\StudentLearningController as MasterTeacherStudentLearningController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\Student\AdminRequestController as StudentAdminRequestController;
use App\Http\Controllers\Api\V1\Student\AssessmentController as StudentAssessmentController;
use App\Http\Controllers\Api\V1\Student\BookingController as StudentBookingController;
use App\Http\Controllers\Api\V1\Student\LearningJournalController as StudentLearningJournalController;
use App\Http\Controllers\Api\V1\Student\ProfileController;
use App\Http\Controllers\Api\V1\Teacher\AdminRequestController as TeacherAdminRequestController;
use App\Http\Controllers\Api\V1\Teacher\ProfileController as TeacherProfileController;
use App\Http\Controllers\Api\V1\Teacher\ScheduleController as TeacherScheduleController;
use App\Http\Controllers\Api\V1\Teacher\StudentController as TeacherStudentController;
use App\Http\Controllers\Api\V1\Teacher\StudentFeedbackController as TeacherStudentFeedbackController;
use App\Http\Controllers\Api\V1\Teacher\StudentLearningController as TeacherStudentLearningController;
use App\Http\Controllers\Api\V1\Teacher\StudentResultController as TeacherStudentResultController;
use Illuminate\Support\Facades\Route;

Route::prefix('auth')->group(function (): void {
    Route::get('login-page', [LoginPageController::class, 'show']);
    Route::post('login', [AuthController::class, 'login'])->middleware('throttle:auth');
    Route::post('forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:auth');
    Route::post('reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:auth');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('logout', [AuthController::class, 'logout']);
        Route::get('me', [AuthController::class, 'me']);
        Route::put('password', [AuthController::class, 'changePassword']);
    });
});

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('notifications', [NotificationController::class, 'index']);
    Route::get('notifications/unread-count', [NotificationController::class, 'unreadCount']);
    Route::post('notifications/read-all', [NotificationController::class, 'markAllRead']);
    Route::patch('notifications/{notification}/read', [NotificationController::class, 'markRead']);
});

Route::middleware(['auth:sanctum', 'admin', 'admin.permission', 'subadmin.activity'])->prefix('admin')->group(function (): void {
    Route::get('dashboard', [DashboardController::class, 'show']);

    Route::get('sub-admins/permissions', [SubAdminController::class, 'catalog']);
    Route::get('sub-admins', [SubAdminController::class, 'index']);
    Route::post('sub-admins', [SubAdminController::class, 'store']);
    Route::get('sub-admins/{subAdmin}', [SubAdminController::class, 'show']);
    Route::get('sub-admins/{subAdmin}/history', [SubAdminController::class, 'history']);
    Route::put('sub-admins/{subAdmin}', [SubAdminController::class, 'update']);
    Route::delete('sub-admins/{subAdmin}', [SubAdminController::class, 'destroy']);

    Route::get('students', [AdminStudentController::class, 'index']);
    Route::post('students', [AdminStudentController::class, 'store']);
    Route::get('students/{student}', [AdminStudentController::class, 'show']);
    Route::put('students/{student}', [AdminStudentController::class, 'update']);
    Route::delete('students/{student}', [AdminStudentController::class, 'destroy']);
    Route::get('students/{student}/history', [AdminStudentController::class, 'history']);
    Route::put('students/{student}/mentor', [StudentMentorController::class, 'update']);
    Route::delete('students/{student}/mentor', [StudentMentorController::class, 'destroy']);
    Route::get('students/{student}/learning-journal', [AdminStudentLearningController::class, 'journal']);
    Route::get('students/{student}/learning-journal/{journey}/{week}', [AdminStudentLearningController::class, 'week']);
    Route::post('students/{student}/promote', [AdminStudentLearningController::class, 'promote']);

    Route::get('teachers', [AdminTeacherController::class, 'index']);
    Route::post('teachers', [AdminTeacherController::class, 'store']);
    Route::get('teachers/{teacher}', [AdminTeacherController::class, 'show']);
    Route::get('teachers/{teacher}/dashboard', [AdminTeacherController::class, 'dashboard']);
    Route::get('teachers/{teacher}/history', [AdminTeacherController::class, 'history']);
    Route::get('teachers/{teacher}/promoted-students', [AdminTeacherController::class, 'promotedStudents']);
    Route::put('teachers/{teacher}', [AdminTeacherController::class, 'update']);
    Route::delete('teachers/{teacher}', [AdminTeacherController::class, 'destroy']);

    Route::get('batches', [AdminBatchController::class, 'index']);
    Route::post('batches', [AdminBatchController::class, 'store']);
    Route::get('batches/{batch}', [AdminBatchController::class, 'show']);
    Route::put('batches/{batch}', [AdminBatchController::class, 'update']);
    Route::patch('batches/{batch}/status', [AdminBatchController::class, 'toggleStatus']);
    Route::get('batches/{batch}/students', [AdminBatchController::class, 'students']);
    Route::post('batches/{batch}/students', [AdminBatchController::class, 'enroll']);
    Route::delete('batches/{batch}/students/{student}', [AdminBatchController::class, 'unenroll']);

    Route::get('levels', [AcademicLevelController::class, 'index']);
    Route::post('levels', [AcademicLevelController::class, 'store']);
    Route::get('levels/{level}', [AcademicLevelController::class, 'show']);
    Route::put('levels/{level}', [AcademicLevelController::class, 'update']);
    Route::delete('levels/{level}', [AcademicLevelController::class, 'destroy']);
    Route::post('levels/{level}/batches', [AdminBatchController::class, 'storeForLevel']);
    Route::post('levels/{level}/teachers', [AcademicLevelController::class, 'assignTeacher']);
    Route::delete('levels/{level}/teachers/{teacher}', [AcademicLevelController::class, 'unassignTeacher']);
    Route::get('levels/{level}/weekly-learnings', [AdminWeeklyLearningController::class, 'index']);
    Route::put('levels/{level}/weekly-learnings', [AdminWeeklyLearningController::class, 'upsert']);

    Route::get('assessments', [AdminAptitudeAssessmentController::class, 'index']);
    Route::post('assessments', [AdminAptitudeAssessmentController::class, 'store']);
    Route::get('assessments/{aptitudeAssessment}', [AdminAptitudeAssessmentController::class, 'show']);
    Route::put('assessments/{aptitudeAssessment}', [AdminAptitudeAssessmentController::class, 'update']);
    Route::delete('assessments/{aptitudeAssessment}', [AdminAptitudeAssessmentController::class, 'destroy']);
    Route::post('assessments/{aptitudeAssessment}/activate', [AdminAptitudeAssessmentController::class, 'activate']);
    Route::post('assessments/{aptitudeAssessment}/deactivate', [AdminAptitudeAssessmentController::class, 'deactivate']);
    Route::get('assessments/{aptitudeAssessment}/attempts', [AdminAptitudeAssessmentController::class, 'attempts']);
    Route::post('assessments/{aptitudeAssessment}/questions', [AdminAptitudeAssessmentController::class, 'storeQuestion']);
    Route::put('assessments/{aptitudeAssessment}/questions/{question}', [AdminAptitudeAssessmentController::class, 'updateQuestion']);
    Route::delete('assessments/{aptitudeAssessment}/questions/{question}', [AdminAptitudeAssessmentController::class, 'destroyQuestion']);
    Route::post('assessments/{aptitudeAssessment}/questions/{question}/options', [AdminAptitudeAssessmentController::class, 'storeOption']);
    Route::put('assessments/{aptitudeAssessment}/options/{option}', [AdminAptitudeAssessmentController::class, 'updateOption']);
    Route::delete('assessments/{aptitudeAssessment}/options/{option}', [AdminAptitudeAssessmentController::class, 'destroyOption']);

    Route::get('students/{student}/results', [AdminDevelopmentController::class, 'studentResults']);
    Route::get('students/{student}/feedback', [AdminDevelopmentController::class, 'studentFeedback']);
    Route::post('students/{student}/feedback', [AdminDevelopmentController::class, 'storeStudentFeedback']);
    Route::put('students/{student}/feedback/{feedback}', [AdminDevelopmentController::class, 'updateStudentFeedback']);
    Route::delete('students/{student}/feedback/{feedback}', [AdminDevelopmentController::class, 'destroyStudentFeedback']);
    Route::get('students/{student}/feedback/summary', [AdminDevelopmentController::class, 'studentFeedbackSummary']);
    Route::get('feedback-catalog', [AdminDevelopmentController::class, 'feedbackCatalog']);

    Route::get('google/meet', [AdminGoogleMeetController::class, 'show']);
    Route::post('google/meet/authorize', [AdminGoogleMeetController::class, 'start']);
    Route::post('google/meet/spaces', [AdminGoogleMeetController::class, 'store']);

    Route::get('attendance', [AdminAttendanceController::class, 'index']);
    Route::get('attendance/{issue}', [AdminAttendanceController::class, 'show']);
    Route::post('attendance/{issue}/resolve', [AdminAttendanceController::class, 'resolve']);

    Route::get('login-page', [AdminLoginPageContentController::class, 'show']);
    Route::put('login-page', [AdminLoginPageContentController::class, 'update']);
    Route::get('settings', [AdminSettingsController::class, 'show']);
    Route::put('settings', [AdminSettingsController::class, 'update']);

    Route::get('requests', [AdminAdminRequestController::class, 'index']);
    Route::get('requests/{adminRequest}', [AdminAdminRequestController::class, 'show']);
    Route::post('requests/{adminRequest}/resolve', [AdminAdminRequestController::class, 'resolve']);

    Route::get('schedule/teachers', [AdminScheduleController::class, 'teachers']);
    Route::get('schedule/day', [AdminScheduleController::class, 'day']);
    Route::get('schedule/week', [AdminScheduleController::class, 'week']);
    Route::get('schedule/month', [AdminScheduleController::class, 'month']);
    Route::get('schedule/leaves', [AdminScheduleController::class, 'leaves']);
    Route::post('schedule/teachers/{teacher}/breaks', [AdminScheduleController::class, 'upsertBreaks']);
    Route::post('schedule/teachers/{teacher}/leaves', [AdminScheduleController::class, 'storeLeave']);
    Route::delete('schedule/leaves/{leave}', [AdminScheduleController::class, 'destroyLeave']);
    Route::get('schedule/bookings', [AdminScheduleController::class, 'bookings']);
    Route::post('schedule/bookings', [AdminScheduleController::class, 'storeBooking']);
    Route::put('schedule/bookings/{booking}', [AdminScheduleController::class, 'updateBooking']);
    Route::delete('schedule/bookings/{booking}', [AdminScheduleController::class, 'destroyBooking']);
    Route::post('schedule/bookings/{booking}/complete', [AdminScheduleController::class, 'completeBooking']);
    Route::get('schedule/teachers/{teacher}/availability', [AdminScheduleController::class, 'availability']);
    Route::put('schedule/teachers/{teacher}/availability', [AdminScheduleController::class, 'updateAvailability']);
    Route::post('schedule/teachers/{teacher}/availability/overrides', [AdminScheduleController::class, 'storeAvailabilityOverride']);
    Route::delete('schedule/teachers/{teacher}/availability/overrides/{override}', [AdminScheduleController::class, 'destroyAvailabilityOverride']);
});

Route::middleware(['auth:sanctum', 'role:common_teacher|master_teacher'])->group(function (): void {
    Route::get('teacher/profile', [TeacherProfileController::class, 'show']);
    Route::put('teacher/profile', [TeacherProfileController::class, 'update']);
    Route::get('teacher/requests', [TeacherAdminRequestController::class, 'index']);
    Route::post('teacher/requests', [TeacherAdminRequestController::class, 'store']);
    Route::get('teacher/schedule/day', [TeacherScheduleController::class, 'day']);
    Route::get('teacher/schedule/week', [TeacherScheduleController::class, 'week']);
    Route::get('teacher/schedule/month', [TeacherScheduleController::class, 'month']);
    Route::get('teacher/schedule/breaks', [TeacherScheduleController::class, 'breaks']);
    Route::put('teacher/schedule/breaks', [TeacherScheduleController::class, 'upsertBreaks']);
    Route::get('teacher/schedule/leaves', [TeacherScheduleController::class, 'leaves']);
    Route::post('teacher/schedule/leaves', [TeacherScheduleController::class, 'storeLeave']);
    Route::delete('teacher/schedule/leaves/{leave}', [TeacherScheduleController::class, 'destroyLeave']);
    Route::post('teacher/schedule/bookings/{booking}/complete', [TeacherScheduleController::class, 'completeBooking']);
    Route::post('teacher/schedule/bookings/{booking}/join', [TeacherScheduleController::class, 'joinBooking']);
    Route::post('teacher/schedule/bookings/{booking}/attendance-reports', [TeacherScheduleController::class, 'reportStudent']);
    Route::post('teacher/schedule/bookings/{booking}/whatsapp', [TeacherScheduleController::class, 'whatsappStudent']);
});

Route::middleware(['auth:sanctum', 'role:master_teacher'])->prefix('teacher')->group(function (): void {
    Route::get('students/{student}', [TeacherStudentController::class, 'show']);
    Route::get('students/{student}/results', [TeacherStudentResultController::class, 'show']);
    Route::get('students/{student}/feedback', [TeacherStudentFeedbackController::class, 'index']);
    Route::get('students/{student}/feedback/summary', [TeacherStudentFeedbackController::class, 'summary']);
    Route::get('students/{student}/learning-journal', [TeacherStudentLearningController::class, 'journal']);
    Route::get('students/{student}/learning-journal/{journey}/{week}', [TeacherStudentLearningController::class, 'week']);
});

Route::middleware(['auth:sanctum', 'role:master_teacher'])->prefix('master-teacher')->group(function (): void {
    Route::get('dashboard', [MasterTeacherDashboardController::class, 'show']);
    Route::get('students', [MasterTeacherStudentController::class, 'index']);
    Route::get('students/{student}', [MasterTeacherStudentController::class, 'show']);
    Route::get('feedback-catalog', [MasterTeacherFeedbackController::class, 'catalog']);
    Route::get('students/{student}/feedback', [MasterTeacherFeedbackController::class, 'index']);
    Route::get('students/{student}/feedback/summary', [MasterTeacherFeedbackController::class, 'summary']);
    Route::post('students/{student}/feedback', [MasterTeacherFeedbackController::class, 'store']);
    Route::put('students/{student}/feedback/{feedback}', [MasterTeacherFeedbackController::class, 'update']);
    Route::delete('students/{student}/feedback/{feedback}', [MasterTeacherFeedbackController::class, 'destroy']);
    Route::get('students/{student}/results', [MasterTeacherFeedbackController::class, 'results']);
    Route::get('students/{student}/learning-journal', [MasterTeacherStudentLearningController::class, 'journal']);
    Route::get('students/{student}/learning-journal/{journey}/{week}', [MasterTeacherStudentLearningController::class, 'week']);
    Route::post('students/{student}/promote', [MasterTeacherStudentLearningController::class, 'promote']);
});

Route::middleware(['auth:sanctum', 'role:student'])->prefix('student')->group(function (): void {
    Route::get('profile', [ProfileController::class, 'show']);
    Route::get('assessment', [StudentAssessmentController::class, 'show']);
    Route::post('assessment/{aptitudeAssessment}/submit', [StudentAssessmentController::class, 'submit']);
    Route::get('results', [StudentAssessmentController::class, 'results']);
    Route::get('feedback', [StudentAssessmentController::class, 'feedback']);
    Route::get('feedback/summary', [StudentAssessmentController::class, 'feedbackSummary']);
    Route::get('requests', [StudentAdminRequestController::class, 'index']);
    Route::post('requests', [StudentAdminRequestController::class, 'store']);
    Route::get('bookings/eligibility', [StudentBookingController::class, 'eligibility']);
    Route::get('bookings/teachers', [StudentBookingController::class, 'teachers']);
    Route::get('bookings/teachers/{teacher}', [StudentBookingController::class, 'showTeacher']);
    Route::get('bookings/availability', [StudentBookingController::class, 'availability']);
    Route::get('bookings', [StudentBookingController::class, 'index']);
    Route::post('bookings', [StudentBookingController::class, 'store']);
    Route::get('bookings/{booking}', [StudentBookingController::class, 'show']);
    Route::put('bookings/{booking}', [StudentBookingController::class, 'reschedule']);
    Route::post('bookings/{booking}/join', [StudentBookingController::class, 'join']);
    Route::post('bookings/{booking}/attendance-reports', [StudentBookingController::class, 'reportTeacher']);
    Route::get('learning/dashboard', [StudentLearningJournalController::class, 'dashboard']);
    Route::get('learning/journal', [StudentLearningJournalController::class, 'index']);
    Route::get('learning/journal/{journey}/{week}', [StudentLearningJournalController::class, 'show']);
    Route::post('learning/journal/{journey}/{week}', [StudentLearningJournalController::class, 'submit']);
});
