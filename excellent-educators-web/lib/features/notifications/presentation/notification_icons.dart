import 'package:flutter/material.dart';

IconData notificationIconFor(String type) {
  return switch (type) {
    'master_teacher_assigned' ||
    'master_teacher_changed' ||
    'master_teacher_removed' =>
      Icons.psychology_alt_rounded,
    'common_teacher_assigned' ||
    'common_teacher_changed' ||
    'common_teacher_removed' =>
      Icons.person_outline,
    'student_enrolled_in_batch' || 'student_unenrolled_from_batch' =>
      Icons.groups_rounded,
    'student_booking_failed' => Icons.warning_amber_rounded,
    'session_booked' => Icons.event_available_rounded,
    'session_rescheduled' || 'session_mentor_updated' =>
      Icons.event_repeat_rounded,
    'session_cancelled' => Icons.event_busy_rounded,
    'teacher_leave_submitted' ||
    'teacher_leave_approved' ||
    'teacher_leave_rejected' ||
    'teacher_leave_cancelled' =>
      Icons.event_busy_rounded,
    'payment_recorded' || 'payment_voided' => Icons.payments_outlined,
    'attendance_conflict_reported' || 'attendance_conflict_resolved' =>
      Icons.report_outlined,
    'student_promoted' => Icons.school_outlined,
    'aptitude_assessment_available' => Icons.quiz_outlined,
    'admin_announcement' => Icons.campaign_outlined,
    _ => Icons.notifications_outlined,
  };
}
