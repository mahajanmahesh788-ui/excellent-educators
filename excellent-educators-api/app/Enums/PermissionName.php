<?php

namespace App\Enums;

enum PermissionName: string
{
    case AssessmentsManage = 'assessments.manage';
    case AssessmentsView = 'assessments.view';
    case FeedbackManage = 'feedback.manage';
    case FeedbackView = 'feedback.view';
}
