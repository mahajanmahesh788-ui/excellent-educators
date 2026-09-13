<?php

return [
    'meet' => [
        'driver' => env('GOOGLE_MEET_DRIVER', 'google'),
        'workspace_user' => env('GOOGLE_WORKSPACE_USER'),
        'calendar_id' => env('GOOGLE_CALENDAR_ID', 'primary'),
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect_uri' => env('GOOGLE_REDIRECT_URI'),
        'scope' => env('GOOGLE_MEET_SCOPE', 'https://www.googleapis.com/auth/meetings.space.created'),
        'service_account' => env('GOOGLE_SERVICE_ACCOUNT'),
        'service_account_path' => env('GOOGLE_SERVICE_ACCOUNT_PATH'),
    ],
];
