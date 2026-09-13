<?php

return [
    'student_id' => [
        'campaign_code' => env('STUDENT_ID_CAMPAIGN_CODE', 'APS'),
    ],
    'batch' => [
        'max_active_students' => 50,
    ],
    'scheduling' => [
        'day_start' => '06:00',
        'day_end' => '23:00',
        'slot_minutes' => 30,
        'break_minutes' => 60,
        'default_weekly_ranges' => [
            ['start' => '06:00', 'end' => '20:00'],
        ],
    ],
    'attendance' => [
        'join_lead_minutes' => 2,
        'join_event_retain_days' => 2,
    ],
];
