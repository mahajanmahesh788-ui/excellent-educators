<?php

namespace App\Enums;

enum FeedbackTargetType: string
{
    case Skill = 'skill';
    case Module = 'module';
    case Dimension = 'dimension';
}
