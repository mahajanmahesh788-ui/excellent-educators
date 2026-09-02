<?php

namespace App\Enums;

enum AdminRequestStatus: string
{
    case Pending = 'pending';
    case Completed = 'completed';
}
