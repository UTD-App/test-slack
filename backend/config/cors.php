<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    |
    | Here you may configure your settings for cross-origin resource sharing
    | or "CORS". This determines what cross-origin operations may execute
    | in web browsers. You are free to adjust these settings as needed.
    |
    | To learn more: https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS
    |
    */

    // Scope CORS to the API surface only. The native mobile app sends no Origin
    // header (CORS does not apply to it) and the Filament admin is same-origin,
    // so neither is affected by tightening these.
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    // Deny-by-default: list browser origins in CORS_ALLOWED_ORIGINS (comma
    // separated). Empty = no cross-origin browser access allowed. Never use '*'
    // together with credentials.
    'allowed_origins' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env('CORS_ALLOWED_ORIGINS', ''))
    ))),

    'allowed_origins_patterns' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env('CORS_ALLOWED_ORIGIN_PATTERNS', ''))
    ))),

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // Bearer-token API → cookies/credentials not needed. Enable only for a
    // cookie-based first-party SPA, and only with explicit origins above.
    'supports_credentials' => (bool) env('CORS_SUPPORTS_CREDENTIALS', false),

];
