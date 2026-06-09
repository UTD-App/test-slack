<?php

return [

    /*
    |--------------------------------------------------------------------------
    | View Storage Paths
    |--------------------------------------------------------------------------
    |
    | Most templating systems load templates from disk. Here you may specify
    | an array of paths that should be checked for your views. Of course
    | the usual Laravel view path has already been registered for you.
    |
    */

    'paths' => [
        resource_path('views'),
    ],

    /*
    |--------------------------------------------------------------------------
    | Compiled View Path
    |--------------------------------------------------------------------------
    |
    | This option determines where all the compiled Blade templates will be
    | stored for your application. Typically, this is within the storage
    | directory. However, as usual, you are free to change this value.
    |
    */

    'compiled' => env(
        'VIEW_COMPILED_PATH',
        realpath(storage_path('framework/views'))
    ),

    'whatsapp_url'   => env('WHATSAPP_URL'),
    'whatsapp_token' => env('WHATSAPP_TOKEN'),
    'decrypt_key'    => 'L9:65W&+nG@g',
    'merchant_name' => 'software',
    'apple_endpoint' => env('APPLE_PAY_VERIFY_RECEIPT_ENDPOINT'),
    'merchant_id' =>'BCR2DN4T3GPIDDAG'
    /*
     *
MERCHANT_ID = 'BCR2DN4T3GPIDDAG'
MERCHANT_NAME = 'software'
DECRYPT_KEY= 'L9:65W&+nG@g'
     * */
];
