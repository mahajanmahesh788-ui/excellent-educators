<?php

namespace App\Enums;

enum NotificationType: string
{
    case StudentEnrolledInBatch = 'student_enrolled_in_batch';
    case StudentUnenrolledFromBatch = 'student_unenrolled_from_batch';
    case CommonTeacherAssigned = 'common_teacher_assigned';
    case CommonTeacherChanged = 'common_teacher_changed';
    case CommonTeacherRemoved = 'common_teacher_removed';
    case MasterTeacherAssigned = 'master_teacher_assigned';
    case MasterTeacherChanged = 'master_teacher_changed';
    case MasterTeacherRemoved = 'master_teacher_removed';
    case StudentBookingFailed = 'student_booking_failed';
    case TeacherLeaveSubmitted = 'teacher_leave_submitted';
    case TeacherLeaveRejected = 'teacher_leave_rejected';
    case SessionMentorUpdated = 'session_mentor_updated';
    case SessionBooked = 'session_booked';
    case SessionRescheduled = 'session_rescheduled';
}
