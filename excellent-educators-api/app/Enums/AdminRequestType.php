<?php

namespace App\Enums;

enum AdminRequestType: string
{
    case General = 'general';
    case RemoveMentee = 'remove_mentee';
    case RemoveBatchStudent = 'remove_batch_student';
}
