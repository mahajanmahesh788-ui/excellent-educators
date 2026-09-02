<?php

namespace App\Enums;

enum AptitudeAssessmentStatus: string
{
    case Draft = 'draft';
    case Active = 'active';
    case Inactive = 'inactive';
}
