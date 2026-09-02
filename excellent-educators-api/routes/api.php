<?php

use App\Http\Controllers\Api\V1\Admin\AdminRequestController as AdminAdminRequestController;
use App\Http\Controllers\Api\V1\Admin\AptitudeAssessmentController as AdminAptitudeAssessmentController;
use App\Http\Controllers\Api\V1\Admin\BatchController as AdminBatchController;
use App\Http\Controllers\Api\V1\Admin\CareerCompassLevelController;
use App\Http\Controllers\Api\V1\Admin\DashboardController;
use App\Http\Controllers\Api\V1\Admin\DevelopmentController as AdminDevelopmentController;
use App\Http\Controllers\Api\V1\Admin\LoginPageContentController as AdminLoginPageContentController;
use App\Http\Controllers\Api\V1\Admin\StudentController as AdminStudentController;
use App\Http\Controllers\Api\V1\Admin\StudentMentorController;
use App\Http\Controllers\Api\V1\Admin\TeacherController as AdminTeacherController;
use App\Http\Controllers\Api\V1\Auth\AuthController;
use App\Http\Controllers\Api\V1\Auth\LoginPageController;
use App\Http\Controllers\Api\V1\MasterTeacher\DashboardController as MasterTeacherDashboardController;
use App\Http\Controllers\Api\V1\MasterTeacher\FeedbackController as MasterTeacherFeedbackController;
use App\Http\Controllers\Api\V1\MasterTeacher\StudentController as MasterTeacherStudentController;
use App\Http\Controllers\Api\V1\NotificationController;
use App\Http\Controllers\Api\V1\Student\AdminRequestController as StudentAdminRequestController;
use App\Http\Controllers\Api\V1\Student\AssessmentController as StudentAssessmentController;
use App\Http\Controllers\Api\V1\Student\ProfileController;
use App\Http\Controllers\Api\V1\Teacher\AdminRequestController as TeacherAdminRequestController;
use App\Http\Controllers\Api\V1\Teacher\AssessmentController as TeacherAssessmentController;
use App\Http\Controllers\Api\V1\Teacher\BatchController as TeacherBatchController;
use App\Http\Controllers\Api\V1\Teacher\ProfileController as TeacherProfileController;
use App\Http\Controllers\Api\V1\Teacher\StudentController as TeacherStudentController;
use App\Http\Controllers\Api\V1\Teacher\StudentFeedbackController as TeacherStudentFeedbackController;
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

Route::middleware(['auth:sanctum', 'admin'])->prefix('admin')->group(function (): void {
    Route::get('dashboard', [DashboardController::class, 'show']);
    Route::get('career-compass-levels', [CareerCompassLevelController::class, 'index']);

    Route::get('students', [AdminStudentController::class, 'index']);
    Route::post('students', [AdminStudentController::class, 'store']);
    Route::get('students/{student}', [AdminStudentController::class, 'show']);
    Route::put('students/{student}', [AdminStudentController::class, 'update']);
    Route::put('students/{student}/mentor', [StudentMentorController::class, 'update']);
    Route::delete('students/{student}/mentor', [StudentMentorController::class, 'destroy']);

    Route::get('teachers', [AdminTeacherController::class, 'index']);
    Route::post('teachers', [AdminTeacherController::class, 'store']);
    Route::get('teachers/{teacher}', [AdminTeacherController::class, 'show']);
    Route::get('teachers/{teacher}/dashboard', [AdminTeacherController::class, 'dashboard']);
    Route::put('teachers/{teacher}', [AdminTeacherController::class, 'update']);

    Route::get('batches', [AdminBatchController::class, 'index']);
    Route::post('batches', [AdminBatchController::class, 'store']);
    Route::get('batches/{batch}', [AdminBatchController::class, 'show']);
    Route::put('batches/{batch}', [AdminBatchController::class, 'update']);
    Route::get('batches/{batch}/students', [AdminBatchController::class, 'students']);
    Route::post('batches/{batch}/students', [AdminBatchController::class, 'enroll']);
    Route::delete('batches/{batch}/students/{student}', [AdminBatchController::class, 'unenroll']);
    Route::post('batches/{batch}/teacher', [AdminBatchController::class, 'assignTeacher']);
    Route::delete('batches/{batch}/teacher', [AdminBatchController::class, 'unassignTeacher']);

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

    Route::get('login-page', [AdminLoginPageContentController::class, 'show']);
    Route::put('login-page', [AdminLoginPageContentController::class, 'update']);

    Route::get('requests', [AdminAdminRequestController::class, 'index']);
    Route::get('requests/{adminRequest}', [AdminAdminRequestController::class, 'show']);
    Route::post('requests/{adminRequest}/resolve', [AdminAdminRequestController::class, 'resolve']);
});

Route::middleware(['auth:sanctum', 'role:common_teacher|master_teacher'])->group(function (): void {
    Route::get('teacher/profile', [TeacherProfileController::class, 'show']);
    Route::get('teacher/requests', [TeacherAdminRequestController::class, 'index']);
    Route::post('teacher/requests', [TeacherAdminRequestController::class, 'store']);
});

Route::middleware(['auth:sanctum', 'role:common_teacher'])->prefix('teacher')->group(function (): void {
    Route::get('batches', [TeacherBatchController::class, 'index']);
    Route::get('batches/{batch}/students', [TeacherBatchController::class, 'students']);
    Route::get('batches/{batch}/assessments', [TeacherAssessmentController::class, 'index']);
    Route::post('batches/{batch}/assessments', [TeacherAssessmentController::class, 'store']);
    Route::get('batches/{batch}/assessments/{assessment}', [TeacherAssessmentController::class, 'show']);
    Route::put('batches/{batch}/assessments/{assessment}', [TeacherAssessmentController::class, 'update']);
    Route::get('batches/{batch}/assessments/{assessment}/scores', [TeacherAssessmentController::class, 'scores']);
    Route::put('batches/{batch}/assessments/{assessment}/scores', [TeacherAssessmentController::class, 'recordScores']);
    Route::get('students/{student}', [TeacherStudentController::class, 'show']);
    Route::get('students/{student}/results', [TeacherStudentResultController::class, 'show']);
    Route::get('students/{student}/feedback', [TeacherStudentFeedbackController::class, 'index']);
    Route::get('students/{student}/feedback/summary', [TeacherStudentFeedbackController::class, 'summary']);
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
});
