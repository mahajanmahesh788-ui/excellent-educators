<?php

$isProduction = env('APP_ENV') === 'production';
$rawOrigins = trim((string) env('CORS_ALLOWED_ORIGINS', $isProduction ? '' : '*'));
$origins = array_values(array_filter(array_map(
    'trim',
    $rawOrigins === '' ? [] : explode(',', $rawOrigins),
)));

// Never allow wildcard CORS in production — browsers would accept any site.
if ($isProduction) {
    $origins = array_values(array_filter(
        $origins,
        static fn (string $origin): bool => $origin !== '*',
    ));
}

$frontend = rtrim(trim((string) env('FRONTEND_URL', '')), '/');
if (
    $frontend !== ''
    && ! in_array($frontend, $origins, true)
    && ! in_array('*', $origins, true)
) {
    $origins[] = $frontend;
}

if ($origins === []) {
    // Local/dev fallback keeps DX; production with empty list blocks unknown sites.
    $origins = $isProduction ? [] : ['*'];
}

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie', 'auth/google/*', 'media/*'],

    'allowed_methods' => ['*'],

    'allowed_origins' => $origins,

    'allowed_origins_patterns' => $isProduction
        ? []
        : [
            '#^https?://localhost(:\d+)?$#',
            '#^https?://127\.0\.0\.1(:\d+)?$#',
            '#^https?://\[::1\](:\d+)?$#',
        ],

    'allowed_headers' => ['*'],

    'exposed_headers' => ['X-Request-Id'],

    'max_age' => 86400,

    'supports_credentials' => false,
];
