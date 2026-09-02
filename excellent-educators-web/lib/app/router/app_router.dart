import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_batches_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_dashboard_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_detail_pages.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_students_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/admin_teachers_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/master_teacher_dashboard_page.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/role_pages.dart';
import 'package:excellent_educators_web/features/academic/presentation/pages/teacher_assessment_pages.dart';
import 'package:excellent_educators_web/features/assessments/presentation/pages/admin_assessment_pages.dart';
import 'package:excellent_educators_web/features/auth/presentation/pages/admin_login_page_editor.dart';
import 'package:excellent_educators_web/features/auth/presentation/pages/change_password_page.dart';
import 'package:excellent_educators_web/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:excellent_educators_web/features/auth/presentation/pages/login_page.dart';
import 'package:excellent_educators_web/features/auth/presentation/pages/reset_password_page.dart';
import 'package:excellent_educators_web/features/auth/presentation/pages/session_page.dart';
import 'package:excellent_educators_web/features/auth/presentation/providers/auth_controller.dart';
import 'package:excellent_educators_web/features/feedback/presentation/pages/feedback_pages.dart';
import 'package:excellent_educators_web/features/requests/presentation/pages/request_pages.dart';
import 'package:excellent_educators_web/features/notifications/presentation/pages/notifications_page.dart';
import 'package:excellent_educators_web/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: RoutePaths.login,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (!auth.isReady) {
        return null;
      }

      final location = state.matchedLocation;
      const publicPaths = {
        RoutePaths.login,
        RoutePaths.forgotPassword,
        RoutePaths.resetPassword,
      };
      if (!auth.isAuthenticated && !publicPaths.contains(location)) {
        return RoutePaths.login;
      }

      final loggingIn = location == RoutePaths.login;
      if (!auth.isAuthenticated) {
        return null;
      }
      final user = auth.user;
      if (user != null) {
        final home = RoutePaths.homeFor(
          isAdmin: user.isAdmin,
          isCommonTeacher: user.isCommonTeacher,
          isMasterTeacher: user.isMasterTeacher,
          isStudent: user.isStudent,
        );
        if (loggingIn || location == RoutePaths.session || location == '/' ||
            location == RoutePaths.forgotPassword || location == RoutePaths.resetPassword) {
          return home;
        }
        if (location == '/notifications') {
          return RoutePaths.notificationsFor(isStudent: user.isStudent);
        }
        if (location.startsWith('/admin') && !user.isAdmin) {
          return home;
        }
        if (location.startsWith('/teacher') && !user.isCommonTeacher) {
          if (!user.isMasterTeacher) {
            return home;
          }
          final masterTeacherRoutes = location.startsWith(RoutePaths.teacherProfile) ||
              location.startsWith(RoutePaths.teacherRequests) ||
              location.startsWith(RoutePaths.teacherNotifications);
          if (!masterTeacherRoutes) {
            return home;
          }
        }
        if (location.startsWith('/master-teacher') && !user.isMasterTeacher) {
          return home;
        }
        if (location.startsWith('/student') && !user.isStudent) {
          return home;
        }
        if (location == RoutePaths.changePassword && user.isAdmin) {
          return home;
        }
      }
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Page not found'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final user = ref.read(authControllerProvider).user;
                if (user == null) {
                  context.go(RoutePaths.login);
                  return;
                }
                context.go(RoutePaths.homeFor(
                  isAdmin: user.isAdmin,
                  isCommonTeacher: user.isCommonTeacher,
                  isMasterTeacher: user.isMasterTeacher,
                  isStudent: user.isStudent,
                ));
              },
              child: const Text('Go home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordPage(email: email, token: token);
        },
      ),
      GoRoute(
        path: RoutePaths.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: RoutePaths.session,
        builder: (context, state) => const SessionPage(),
      ),
      GoRoute(
        path: RoutePaths.adminDashboard,
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.adminStudents,
        builder: (context, state) => const AdminStudentsPage(),
      ),
      GoRoute(
        path: RoutePaths.adminStudentNew,
        builder: (context, state) => const AdminCreateStudentPage(),
      ),
      GoRoute(
        path: RoutePaths.adminStudentDetail,
        builder: (context, state) => AdminStudentDetailPage(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.adminFeedbackNew,
        builder: (context, state) => MonthlyFeedbackFormPage(
          studentId: state.pathParameters['id']!,
          audience: MonthlyFeedbackFormAudience.admin,
        ),
      ),
      GoRoute(
        path: RoutePaths.adminFeedbackEdit,
        builder: (context, state) => MonthlyFeedbackFormPage(
          studentId: state.pathParameters['id']!,
          feedbackId: state.pathParameters['feedbackId']!,
          audience: MonthlyFeedbackFormAudience.admin,
        ),
      ),
      GoRoute(
        path: RoutePaths.adminStudentResults,
        builder: (context, state) => AdminStudentResultsPage(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.adminTeachers,
        builder: (context, state) => const AdminTeachersPage(),
      ),
      GoRoute(
        path: RoutePaths.adminTeacherNew,
        builder: (context, state) => const AdminCreateTeacherPage(),
      ),
      GoRoute(
        path: RoutePaths.adminTeacherDetail,
        builder: (context, state) => AdminTeacherDetailPage(teacherId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.adminBatches,
        builder: (context, state) => const AdminBatchesPage(),
      ),
      GoRoute(
        path: RoutePaths.adminBatchNew,
        builder: (context, state) => const AdminCreateBatchPage(),
      ),
      GoRoute(
        path: RoutePaths.adminBatchDetail,
        builder: (context, state) => AdminBatchDetailPage(batchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.adminAssessments,
        builder: (context, state) => const AdminAssessmentsPage(),
      ),
      GoRoute(
        path: RoutePaths.adminAssessmentNew,
        builder: (context, state) => const AdminAssessmentEditorPage(),
      ),
      GoRoute(
        path: RoutePaths.adminAssessmentDetail,
        builder: (context, state) => AdminAssessmentEditorPage(assessmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.adminAssessmentAttempts,
        builder: (context, state) => AdminAssessmentAttemptsPage(assessmentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.adminLoginPage,
        builder: (context, state) => const AdminLoginPageEditor(),
      ),
      GoRoute(
        path: RoutePaths.adminRequests,
        builder: (context, state) => const AdminRequestsPage(),
      ),
      GoRoute(
        path: RoutePaths.adminRequestDetail,
        builder: (context, state) => AdminRequestDetailPage(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.teacherBatches,
        builder: (context, state) => const TeacherBatchesPage(),
      ),
      GoRoute(
        path: RoutePaths.teacherBatchStudents,
        builder: (context, state) => TeacherBatchStudentsPage(batchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.teacherBatchAssessments,
        builder: (context, state) => TeacherBatchAssessmentsPage(batchId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.teacherAssessmentNew,
        builder: (context, state) => TeacherCreateAssessmentPage(batchId: state.pathParameters['batchId']!),
      ),
      GoRoute(
        path: RoutePaths.teacherAssessmentDetail,
        builder: (context, state) => TeacherAssessmentDetailPage(
          batchId: state.pathParameters['batchId']!,
          assessmentId: state.pathParameters['assessmentId']!,
        ),
      ),
      GoRoute(
        path: RoutePaths.teacherStudentResults,
        builder: (context, state) => TeacherStudentResultsPage(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.masterTeacherDashboard,
        builder: (context, state) => const MasterTeacherDashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.masterTeacherStudents,
        builder: (context, state) => const MasterTeacherStudentsPage(),
      ),
      GoRoute(
        path: RoutePaths.masterTeacherStudentDetail,
        builder: (context, state) => MasterTeacherStudentDetailPage(studentId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.masterTeacherFeedbackNew,
        builder: (context, state) => MonthlyFeedbackFormPage(
          studentId: state.pathParameters['id']!,
          audience: MonthlyFeedbackFormAudience.masterTeacher,
        ),
      ),
      GoRoute(
        path: RoutePaths.masterTeacherFeedbackEdit,
        builder: (context, state) => MonthlyFeedbackFormPage(
          studentId: state.pathParameters['id']!,
          feedbackId: state.pathParameters['feedbackId']!,
          audience: MonthlyFeedbackFormAudience.masterTeacher,
        ),
      ),
      GoRoute(
        path: RoutePaths.teacherProfile,
        builder: (context, state) => const TeacherProfilePage(),
      ),
      GoRoute(
        path: RoutePaths.teacherRequests,
        builder: (context, state) => const TeacherRequestsPage(),
      ),
      GoRoute(
        path: RoutePaths.teacherRequestNew,
        builder: (context, state) => const TeacherNewRequestPage(),
      ),
      GoRoute(
        path: RoutePaths.studentNotifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RoutePaths.teacherNotifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: RoutePaths.studentDashboard,
        builder: (context, state) => const StudentDashboardPage(),
      ),
      GoRoute(
        path: RoutePaths.studentProfile,
        builder: (context, state) => const StudentProfilePage(),
      ),
      GoRoute(
        path: RoutePaths.studentFeedback,
        builder: (context, state) => const StudentFeedbackPage(),
      ),
      GoRoute(
        path: RoutePaths.studentRequests,
        builder: (context, state) => const StudentRequestsPage(),
      ),
      GoRoute(
        path: RoutePaths.studentRequestNew,
        builder: (context, state) => const StudentNewRequestPage(),
      ),
    ],
  );
});
