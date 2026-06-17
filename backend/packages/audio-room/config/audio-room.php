<?php

return [
    'utd_stream' => [
        'app_id' => env('UTD_STREAM_APP_ID'),
        'server_secret' => env('UTD_STREAM_SERVER_SECRET'),
        'engine_url' => env('UTD_STREAM_ENGINE_URL', 'https://engine.udt-stream.com'),
    ],
];
