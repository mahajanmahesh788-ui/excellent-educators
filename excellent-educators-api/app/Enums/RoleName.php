<?php

namespace App\Enums;

enum RoleName: string
{
    case SuperAdmin = 'super_admin';
    case OperationalAdmin = 'operational_admin';
    case CommonTeacher = 'common_teacher';
    case MasterTeacher = 'master_teacher';
    case Student = 'student';
}
