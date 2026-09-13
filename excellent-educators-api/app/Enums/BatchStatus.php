<?php

namespace App\Enums;

enum BatchStatus: string
{
    case Draft = 'draft';
    case Active = 'active';
    case Inactive = 'inactive';
    case Closed = 'closed';
}
