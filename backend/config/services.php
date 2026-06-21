<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'mailgun' => [
        'domain' => env('MAILGUN_DOMAIN'),
        'secret' => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
    ],

    'now_payments' =>[
        'api_key' => env('NOWPAYMENTS_API_KEY'),
        'callback_url' => env('NOWPAYMENTS_CALLBACK_URL'),
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    // 'baishun' => [
    //     'app_id' => env('BAISHUN_APP_Id',"4280702746"),
    //     'app_key' => env('BAISHUN_APP_KEY',"LzfGx3f3ZKQSYxMNRqdRTOmfd0Jb59DF"),
    //     'server_url' => env('BAISHUN_SERVER_URL','https://mesh-channels-test.jieyou.shop'),
    // ],

    'fawry' => [
        "fawry_secret"          => env('FAWRY_SECRET_KEY',"6ed92079-a485-4373-9453-505e20f6ef48"),
        "fawry_merchant_code"   => env('FAWRY_MERCHANT_CODE','770000019812'),
        "fawry_return_url"      => env('FAWRY_RETURN_URL','/admin/payment-with-method'),
        "fawry_url"        => env('FAWRY_URL','https://atfawry.fawrystaging.com/fawrypay-api/api/payments/init'),
        "fawry_webhook_url"        => env('FAWRY_WEBHOOK_URL','https://'),
    ],

    'utd_fawry' => [
        "utd_fawry_secret"          => env('FAWRY_SECRET_KEY',"6ed92079-a485-4373-9453-505e20f6ef48"),
        "utd_fawry_merchant_code"   => env('FAWRY_MERCHANT_CODE','770000019812'),
        "utd_url"               => env('UTD_URL','http://utd_backend.test/api/fawry-initial'),
        "utd_fawry_return_url"      => env('FAWRY_RETURN_URL','/admin/payment-with-method'),
        "utd_fawry_url"        => env('FAWRY_URL','https://atfawry.fawrystaging.com/fawrypay-api/api/payments/init'),
    ],

    'utd_paymob' => [
        "utd_paymob_secret"          => env('UTD_PAYMOB_SECRET'),
        "utd_paymob_merchant_code"   => env('UTD_PAYMOB_MERCHANT_CODE'),
        "utd_url"                    => env('UTD_PAYMOB_URL', 'http://utd_backend.test/api/paymob-initial'),
        "utd_paymob_return_url"      => env('UTD_PAYMOB_RETURN_URL', '/admin/payment-with-method'),
        "utd_paymob_url"             => env('UTD_PAYMOB_URL'),
    ],

    'zinipay' => [
        "api_key"          => env('ZINIPAY_API_KEY',"6ed92079-a485-4373-9453-505e20f6ef48"),
        "url"              => env('ZINIPAY_URL','https://api.zinipay.com/v1/payment/create'),
    ],

    'agora' => [
        'app_id' => env('AGORA_APP_ID'),
        'app_certificate' => env('AGORA_APP_CERTIFICATE'),
    ],

    // Google Cloud Translation (one of the translatable-content auto-translate
    // engines). Auth: GOOGLE_TRANSLATE_API_KEY if set, otherwise an ADC token
    // from the GCS service-account key file. Requires the Cloud Translation API
    // enabled + billing on the project.
    'google_translate' => [
        'enabled'    => env('GOOGLE_TRANSLATE_ENABLED', true),
        'api_key'    => env('GOOGLE_TRANSLATE_API_KEY'),
        'project_id' => env('GOOGLE_CLOUD_PROJECT_ID'),
        'key_file'   => env('GOOGLE_CLOUD_KEY_FILE', 'service-account.json'),
        'endpoint'   => env('GOOGLE_TRANSLATE_ENDPOINT', 'https://translation.googleapis.com/language/translate/v2'),
    ],

    // Gemini (the DEFAULT auto-translate engine). 'api_key' mode = Generative
    // Language API (just GEMINI_API_KEY). 'vertex' mode = Vertex AI via ADC (needs
    // the Vertex AI API enabled + roles/aiplatform.user on the project).
    'gemini' => [
        'enabled'     => env('GEMINI_ENABLED', true),
        'api_key'     => env('GEMINI_API_KEY'),
        'model'       => env('GEMINI_MODEL', 'gemini-2.5-flash'),
        'driver_mode' => env('GEMINI_DRIVER_MODE', 'api_key'), // api_key | vertex
        'project_id'  => env('GEMINI_PROJECT_ID', 'aitry-476410'),
        'location'    => env('GEMINI_LOCATION', 'us-central1'),
        // Explicit creds for vertex mode (a service-account OR a gcloud ADC json).
        // Leave blank to use ambient ADC (gcloud / metadata).
        'key_file'    => env('GEMINI_KEY_FILE'),
        'base_url'    => env('GEMINI_BASE_URL', 'https://generativelanguage.googleapis.com'),
    ],

    // Which engine powers the admin "Translate"/"AI translate" buttons.
    'translator' => [
        'driver' => env('TRANSLATOR_DRIVER', 'gemini'), // gemini | google
    ],
    'firebase' => [
    'credentials' => env('FILE_NAME'),
    ],

];
