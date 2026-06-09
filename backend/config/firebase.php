<?php

return [
    'apiKey' => env('FIREBASE_API_KEY'),
    'authDomain' => env('FIREBASE_AUTH_DOMAIN'),
    'projectId' => env('FIREBASE_PROJECT_ID'),
    'storageBucket' => env('FIREBASE_STORAGE_BUCKET'),
    'messagingSenderId' => env('FIREBASE_MESSAGING_SENDER_ID'),
    'appId' => env('FIREBASE_APP_ID'),
    'vapid_key' => env('FIREBASE_VAPID_KEY'),
    // 'credentials' => storage_path('app/firebase/service-account.json'),
    'credentials' => base_path(env('FILE_NAME')),
];
