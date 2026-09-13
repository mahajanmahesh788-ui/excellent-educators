<?php

namespace App\Enums;

enum AttendanceVerificationStatus: string
{
    case Pending = 'pending';
    case Resolved = 'resolved';
}
