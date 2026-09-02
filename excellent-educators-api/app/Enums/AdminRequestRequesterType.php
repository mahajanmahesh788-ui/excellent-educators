<?php

namespace App\Enums;

enum AdminRequestRequesterType: string
{
    case Student = 'student';
    case Teacher = 'teacher';
}
