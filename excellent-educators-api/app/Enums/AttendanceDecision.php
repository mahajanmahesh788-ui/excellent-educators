<?php

namespace App\Enums;

enum AttendanceDecision: string
{
    case StudentAttended = 'student_attended';
    case TeacherAttended = 'teacher_attended';
    case BothAttended = 'both_attended';
    case StudentAbsent = 'student_absent';
    case TeacherAbsent = 'teacher_absent';
    case TechnicalIssue = 'technical_issue';
    case BothAbsent = 'both_absent';
    case NoConclusion = 'no_conclusion';
    case Resolved = 'resolved';
    case ExtraChance = 'extra_chance';
}
