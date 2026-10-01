import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

void openNotificationDeepLink(
  BuildContext context,
  UserNotificationDto notification, {
  AppUser? user,
}) {
  final groupId = notification.data?['leave_request_group_id'] as String?;
  if ((notification.type == 'teacher_leave_submitted' ||
          notification.type == 'teacher_leave_cancelled') &&
      groupId != null &&
      groupId.isNotEmpty) {
    context.go(RoutePaths.adminLeaveRequest(groupId));
    return;
  }

  if (notification.type == 'admin_request_submitted' ||
      notification.type == 'admin_request_approved' ||
      notification.type == 'admin_request_rejected') {
    final requestId = notification.data?['admin_request_id'] as String?;
    if (requestId != null && requestId.isNotEmpty) {
      if (user?.isAdmin == true && notification.type == 'admin_request_submitted') {
        context.go(RoutePaths.adminRequestFor(requestId));
        return;
      }
      if (user?.isMasterTeacher == true || user?.isCommonTeacher == true) {
        context.go(RoutePaths.teacherRequests);
        return;
      }
      context.go(RoutePaths.adminRequestFor(requestId));
      return;
    }
  }

  if (notification.type == 'agent_registered_student') {
    final studentId = notification.data?['student_id'] as String?;
    if (studentId != null && studentId.isNotEmpty) {
      context.go(RoutePaths.adminStudent(studentId));
      return;
    }
  }

  final link = notification.data?['link'] as String?;
  if (link != null && link.isNotEmpty) {
    if (link.startsWith('/admin/requests/')) {
      final requestId = link.split('/').last;
      if (requestId.isNotEmpty) {
        context.go(RoutePaths.adminRequestFor(requestId));
      }
      return;
    }
    if (link.startsWith('/admin/students/')) {
      final studentId = link.split('/').last;
      if (studentId.isNotEmpty) {
        context.go(RoutePaths.adminStudent(studentId));
      }
      return;
    }
    if (link.startsWith('/admin/leaves/') ||
        link.startsWith('/admin/schedule/leave-requests/')) {
      final leaveGroupId = link.split('/').last;
      if (leaveGroupId.isNotEmpty) {
        context.go(RoutePaths.adminLeaveRequest(leaveGroupId));
      }
      return;
    }
    if (link.startsWith('/admin/attendance/')) {
      final issueId = link.split('/').last;
      if (issueId.isNotEmpty) {
        context.go(RoutePaths.adminAttendanceIssue(issueId));
      } else {
        context.go(RoutePaths.adminAttendance);
      }
      return;
    }
    if (link == '/student/payments') {
      context.go(RoutePaths.studentPayments);
      return;
    }
    if (link == '/student/bookings') {
      context.go(RoutePaths.studentBookings);
      return;
    }
    if (link == '/student/dashboard') {
      context.go(RoutePaths.studentDashboard);
      return;
    }
    if (link.startsWith('/teacher/schedule')) {
      context.go(RoutePaths.teacherDaySchedule);
      return;
    }
    if (link.startsWith('/admin/notifications') ||
        link.startsWith('/teacher/notifications') ||
        link.startsWith('/student/notifications')) {
      context.go(link);
      return;
    }
  }

  if (notification.type == 'session_booked' ||
      notification.type == 'session_rescheduled' ||
      notification.type == 'session_cancelled' ||
      notification.type == 'teacher_leave_approved' ||
      notification.type == 'teacher_leave_rejected' ||
      notification.type == 'teacher_leave_cancelled') {
    if ((user?.isCommonTeacher ?? false) || (user?.isMasterTeacher ?? false)) {
      context.go(RoutePaths.teacherDaySchedule);
    } else if (user?.isStudent ?? false) {
      context.go(RoutePaths.studentBookings);
    }
    return;
  }

  if (notification.type == 'payment_recorded' ||
      notification.type == 'payment_voided') {
    context.go(RoutePaths.studentPayments);
    return;
  }

  if (notification.type == 'attendance_conflict_reported') {
    final issueId = notification.data?['issue_id'] as String?;
    if (issueId != null && issueId.isNotEmpty) {
      context.go(RoutePaths.adminAttendanceIssue(issueId));
    } else {
      context.go(RoutePaths.adminAttendance);
    }
    return;
  }

  if (notification.type == 'attendance_conflict_resolved') {
    if (user?.isStudent ?? false) {
      context.go(RoutePaths.studentBookings);
    } else if ((user?.isCommonTeacher ?? false) ||
        (user?.isMasterTeacher ?? false)) {
      context.go(RoutePaths.teacherDaySchedule);
    }
    return;
  }

  if (notification.type == 'student_promoted' ||
      notification.type == 'aptitude_assessment_available') {
    context.go(RoutePaths.studentDashboard);
    return;
  }

  context.go(
    RoutePaths.notificationsFor(
      isStudent: user?.isStudent ?? false,
      isAdmin: user?.isAdmin ?? false,
    ),
  );
}
