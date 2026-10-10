import 'package:excellent_educators_web/app/router/route_paths.dart';
import 'package:excellent_educators_web/core/navigation/app_navigation.dart';
import 'package:excellent_educators_web/features/auth/domain/entities/app_user.dart';
import 'package:excellent_educators_web/features/notifications/data/dto/notification_dtos.dart';
import 'package:flutter/widgets.dart';

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
    openAppLink(context, RoutePaths.adminLeaveRequest(groupId));
    return;
  }

  if (notification.type == 'admin_request_submitted' ||
      notification.type == 'admin_request_approved' ||
      notification.type == 'admin_request_rejected') {
    final requestId = notification.data?['admin_request_id'] as String?;
    final studentId = notification.data?['student_id'] as String?;
    final requestType = notification.data?['request_type'] as String?;
    final isTeacher =
        (user?.isMasterTeacher ?? false) || (user?.isCommonTeacher ?? false);

    if (user?.isAdmin == true &&
        notification.type == 'admin_request_submitted' &&
        requestId != null &&
        requestId.isNotEmpty) {
      openAppLink(context, RoutePaths.adminRequestFor(requestId));
      return;
    }

    // Teachers: rejected upgrade → student profile (still on roster).
    // Approved upgrade → stay on notifications (student may have left this teacher).
    if (isTeacher) {
      if (notification.type == 'admin_request_rejected' &&
          studentId != null &&
          studentId.isNotEmpty &&
          (user?.isMasterTeacher ?? false)) {
        openAppLink(context, RoutePaths.masterTeacherStudentFor(studentId));
        return;
      }
      // No dedicated screen needed for approved/other teacher request outcomes.
      return;
    }

    if (user?.isAdmin == true &&
        requestId != null &&
        requestId.isNotEmpty) {
      openAppLink(context, RoutePaths.adminRequestFor(requestId));
      return;
    }

    // Students / agents: open their requests list when linked.
    if (requestType != null || requestId != null) {
      if (user?.isStudent ?? false) {
        openAppLink(context, RoutePaths.studentRequests);
        return;
      }
    }
  }

  if (notification.type == 'agent_registered_student') {
    final studentId = notification.data?['student_id'] as String?;
    if (studentId != null && studentId.isNotEmpty) {
      openAppLink(context, RoutePaths.adminStudent(studentId));
      return;
    }
  }

  final link = notification.data?['link'] as String?;
  if (link != null && link.isNotEmpty) {
    // Teachers must never open admin request detail (blank / redirected junk).
    if (link.startsWith('/admin/requests/') || link == '/teacher/requests') {
      final isTeacher =
          (user?.isMasterTeacher ?? false) || (user?.isCommonTeacher ?? false);
      if (isTeacher) {
        return;
      }
      if (link.startsWith('/admin/requests/')) {
        final requestId = link.split('/').last;
        if (requestId.isNotEmpty && (user?.isAdmin ?? false)) {
          openAppLink(context, RoutePaths.adminRequestFor(requestId));
        }
      }
      return;
    }
    if (link == '/student/requests') {
      if (user?.isStudent ?? false) {
        openAppLink(context, RoutePaths.studentRequests);
      }
      return;
    }
    if (link.startsWith('/admin/students/')) {
      final studentId = link.split('/').last;
      if (studentId.isNotEmpty) {
        openAppLink(context, RoutePaths.adminStudent(studentId));
      }
      return;
    }
    if (link.startsWith('/admin/leaves/') ||
        link.startsWith('/admin/schedule/leave-requests/')) {
      final leaveGroupId = link.split('/').last;
      if (leaveGroupId.isNotEmpty) {
        openAppLink(context, RoutePaths.adminLeaveRequest(leaveGroupId));
      }
      return;
    }
    if (link.startsWith('/admin/attendance/')) {
      final issueId = link.split('/').last;
      if (issueId.isNotEmpty) {
        openAppLink(context, RoutePaths.adminAttendanceIssue(issueId));
      } else {
        openAppLink(context, RoutePaths.adminAttendance);
      }
      return;
    }
    if (link == '/student/payments') {
      openAppLink(context, RoutePaths.studentPayments);
      return;
    }
    if (link == '/student/bookings') {
      openAppLink(context, RoutePaths.studentBookings);
      return;
    }
    if (link == '/student/dashboard') {
      openAppLink(context, RoutePaths.studentDashboard);
      return;
    }
    if (link.startsWith('/teacher/schedule')) {
      openAppLink(context, RoutePaths.teacherDaySchedule);
      return;
    }
    if (link.startsWith('/admin/notifications') ||
        link.startsWith('/teacher/notifications') ||
        link.startsWith('/student/notifications')) {
      openAppLink(context, link);
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
      openAppLink(context, RoutePaths.teacherDaySchedule);
    } else if (user?.isStudent ?? false) {
      openAppLink(context, RoutePaths.studentBookings);
    }
    return;
  }

  if (notification.type == 'payment_recorded' ||
      notification.type == 'payment_voided') {
    openAppLink(context, RoutePaths.studentPayments);
    return;
  }

  if (notification.type == 'attendance_conflict_reported') {
    final issueId = notification.data?['issue_id'] as String?;
    if (issueId != null && issueId.isNotEmpty) {
      openAppLink(context, RoutePaths.adminAttendanceIssue(issueId));
    } else {
      openAppLink(context, RoutePaths.adminAttendance);
    }
    return;
  }

  if (notification.type == 'attendance_conflict_resolved') {
    if (user?.isStudent ?? false) {
      openAppLink(context, RoutePaths.studentBookings);
    } else if ((user?.isCommonTeacher ?? false) ||
        (user?.isMasterTeacher ?? false)) {
      openAppLink(context, RoutePaths.teacherDaySchedule);
    }
    return;
  }

  if (notification.type == 'student_promoted' ||
      notification.type == 'aptitude_assessment_available') {
    openAppLink(context, RoutePaths.studentDashboard);
    return;
  }

  openAppLink(
    context,
    RoutePaths.notificationsFor(
      isStudent: user?.isStudent ?? false,
      isAdmin: user?.isAdmin ?? false,
    ),
  );
}
