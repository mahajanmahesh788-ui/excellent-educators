<?php

namespace App\Enums;

enum AttendanceIssueType: string
{
    case TeacherDidNotJoin = 'teacher_did_not_join';
    case StudentDidNotJoin = 'student_did_not_join';
}
