<?php

namespace App\Enums;

enum TeacherDailyMeetingStatus: string
{
    case Pending = 'pending';
    case Ready = 'ready';
    case Failed = 'failed';
}
