<?php

namespace App\Enums;

enum ScheduleSlotStatus: string
{
    case Available = 'available';
    case Breakfast = 'breakfast';
    case Lunch = 'lunch';
    case Leave = 'leave';
    case Booked = 'booked';
    case WeeklyOff = 'weekly_off';
    case Unavailable = 'unavailable';
}
