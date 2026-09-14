<?php

$origins = array_values(array_filter(array_map(
    'trim',
    explode(',', (string) env('CORS_ALLOWED_ORIGINS', '*')),
)));

$frontend = trim((string) env('FRONTEND_URL', ''));
if ($frontend !== '' && ! in_array($frontend, $origins, true) && ! in_array('*', $origins, true)) {
    $origins[] = $frontend;
}

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie', 'auth/google/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => $origins === [] ? ['*'] : $origins,

    'allowed_origins_patterns' => [
        '#^https?://localhost(:\d+)?$#',
        '#^https?://127\.0\.0\.1(:\d+)?$#',
        '#^https?://\[::1\](:\d+)?$#',
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => ['X-Request-Id'],

    'max_age' => 86400,

    'supports_credentials' => false,
];
