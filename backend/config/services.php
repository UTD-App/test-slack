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
    'firebase' => [
    'credentials' => env('FILE_NAME'),
    ],

];
