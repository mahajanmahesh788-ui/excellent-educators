<?php

namespace App\Enums;

enum AssessmentAttemptStatus: string
{
    case Started = 'started';
    case Submitted = 'submitted';
}
