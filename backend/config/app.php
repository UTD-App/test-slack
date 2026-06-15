<?php

return [

    'google_cloud_file' => env('GOOGLE_CLOUD_KEY_FILE'),
    'google_cloud_storage_bucket' => env('GOOGLE_CLOUD_STORAGE_BUCKET'),
    'cache' => env('CACHE_ENABLE', 'disabled'),

    // Deploy webhook secret
    'deploy_secret' => env('DEPLOY_SECRET', 'change-this-secret-token'),

    'agora_app_id' => env('AGORA_APP_ID'),
    'agora_certificate' => env('AGORA_APP_CERTIFICATE'),
    'payment_url' => env('PAYMENT_URL'),
    'node_server_name' => env('NODE_SERVER_NAME'),

    'owner_timezone' => env('OWNER_TIMEZONE', '-03:00'),
    'zego_client_id' => env('ZEGO_CLIENT_ID'),
    // 'baishun_app_id' => env('BAISHUN_APP_Id', "4280702746"),
    // 'baishun_app_key' => env('BAISHUN_APP_KEY', "LzfGx3f3ZKQSYxMNRqdRTOmfd0Jb59DF"),
    // 'baishun_server_url' => env('BAISHUN_SERVER_URL', 'https://mesh-channels-test.jieyou.shop'),
    // 'baishun_channel'      => env('BAISHUN_CHANNEL', ''),
    // 'baishun_gsp'      => env('BAISHUN_GSP', '201'),

    'balance_user_name'     => env('BALANCE_USER_NAME', 'superAdmin'),
    'balance_password'      => env('BALANCE_PASSWORD', '12345678'),
    'one_coins'             => env('ONE_COINS'),

    'appLogo' => env('APP_LOGO', 'https://demo.24hourworx.com/assets/images/BG2.jpg'),

    // fairbase
    'fileName' => env('FILE_NAME', 'firebase_credentials.json'),
    'projectName' => env('FIREBASE_PROJECT_NAME', ''),
    'senderId' => env('SENDER_ID', 'hola-chat-5554d'),
    'zego_credential' => env('ZEGOENCRYPTtkEY', '7b5d61e6f4a8c2d3e9b7a6f8e1c3d2f4'),
    'utd_secret_key' => env('UTDSECRTKEY', '7b5d61e6f4a8c2d3e9b7a6f8e1c3d2f4'),
    'utd_client_id' => env('UTDCLIENTID', '3030'),
    'google_client_id' => env('GOOGLE_CLIENT_ID', '790444932875-co6ri5d8e3m59ktv73h7eana2gfqbv34.apps.googleusercontent.com'),


    /*
    |--------------------------------------------------------------------------
    | Application Name
    |--------------------------------------------------------------------------
    |
    | This value is the name of your application. This value is used when the
    | framework needs to place the application's name in a notification or
    | any other location as required by the application or its packages.
    |
    */

    'name' => env('APP_NAME', 'Laravel'),
    'name_en' => env('APP_NAME_EN', 'Laravel'),
    'name_ar' => env('APP_NAME_AR', 'لارافيل'),


    /*
    |--------------------------------------------------------------------------
    | Application Environment
    |--------------------------------------------------------------------------
    |
    | This value determines the "environment" your application is currently
    | running in. This may determine how you prefer to configure various
    | services the application utilizes. Set this in your ".env" file.
    |
    */

    'env' => env('APP_ENV', 'production'),

    'api_prefix' => env('API_PREFIX', ''),

    // Secret token guarding the web /setup/{key} bootstrap + /setup/gcs-test/{key}
    // routes so they can be run from a browser. Empty = the routes are disabled (404).
    'setup_key' => env('SETUP_KEY', ''),

    'app_origin_name' => env('APP_ORIGIN_NAME', 'r-star'),




    /*
    |--------------------------------------------------------------------------
    | Application Debug Mode
    |--------------------------------------------------------------------------
    |
    | When your application is in debug mode, detailed error messages with
    | stack traces will be shown on every error that occurs within your
    | application. If disabled, a simple generic error page is shown.
    |
    */

    'debug' => (bool) env('APP_DEBUG', false),

    /*
    |--------------------------------------------------------------------------
    | Application URL
    |--------------------------------------------------------------------------
    |
    | This URL is used by the console to properly generate URLs when using
    | the Artisan command line tool. You should set this to the root of
    | your application so that it is used when running Artisan tasks.
    |
    */

    'url' => env('APP_URL', 'http://localhost'),
    'utd_url' => env('UTD_URL', 'http://127.0.0.1:8082/api/'),
    'asset_url' => env('ASSET_URL', null),

    /*
    |--------------------------------------------------------------------------
    | Application Timezone
    |--------------------------------------------------------------------------
    |
    | Here you may specify the default timezone for your application, which
    | will be used by the PHP date and date-time functions. We have gone
    | ahead and set this to a sensible default for you out of the box.
    |
    */

    'timezone' => env('APP_TIMEZONE', 'UTC'),

    /*
    |--------------------------------------------------------------------------
    | Application Locale Configuration
    |--------------------------------------------------------------------------
    |
    | The application locale determines the default locale that will be used
    | by the translation service provider. You are free to set this value
    | to any of the locales which will be supported by the application.
    |
    */

    'locale' => 'en',

    /*
    |--------------------------------------------------------------------------
    | Application Fallback Locale
    |--------------------------------------------------------------------------
    |
    | The fallback locale determines the locale to use when the current one
    | is not available. You may change the value to correspond to any of
    | the language folders that are provided through your application.
    |
    */

    'fallback_locale' => 'ar',

    /*
    |--------------------------------------------------------------------------
    | Faker Locale
    |--------------------------------------------------------------------------
    |
    | This locale will be used by the Faker PHP library when generating fake
    | data for your database seeds. For example, this will be used to get
    | localized telephone numbers, street address information and more.
    |
    */

    'faker_locale' => 'en_US',

    /*
    |--------------------------------------------------------------------------
    | Encryption Key
    |--------------------------------------------------------------------------
    |
    | This key is used by the Illuminate encrypter service and should be set
    | to a random, 32 character string, otherwise these encrypted strings
    | will not be safe. Please do this before deploying an application!
    |
    */

    'key' => env('APP_KEY'),

    'cipher' => 'AES-256-CBC',

    /*
    |--------------------------------------------------------------------------
    | Autoloaded Service Providers
    |--------------------------------------------------------------------------
    |
    | The service providers listed here will be automatically loaded on the
    | request to your application. Feel free to add your own services to
    | this array to grant expanded functionality to your applications.
    |
    */

    'providers' => [

        /*
         * Laravel Framework Service Providers...
         */
        Illuminate\Auth\AuthServiceProvider::class,
        Illuminate\Broadcasting\BroadcastServiceProvider::class,
        Illuminate\Bus\BusServiceProvider::class,
        Illuminate\Cache\CacheServiceProvider::class,
        Illuminate\Foundation\Providers\ConsoleSupportServiceProvider::class,
        Illuminate\Cookie\CookieServiceProvider::class,
        Illuminate\Database\DatabaseServiceProvider::class,
        Illuminate\Encryption\EncryptionServiceProvider::class,
        Illuminate\Filesystem\FilesystemServiceProvider::class,
        Illuminate\Foundation\Providers\FoundationServiceProvider::class,
        Illuminate\Hashing\HashServiceProvider::class,
        Illuminate\Mail\MailServiceProvider::class,
        Illuminate\Notifications\NotificationServiceProvider::class,
        Illuminate\Pagination\PaginationServiceProvider::class,
        Illuminate\Pipeline\PipelineServiceProvider::class,
        Illuminate\Queue\QueueServiceProvider::class,
        Illuminate\Redis\RedisServiceProvider::class,
        Illuminate\Auth\Passwords\PasswordResetServiceProvider::class,
        Illuminate\Session\SessionServiceProvider::class,
        Illuminate\Translation\TranslationServiceProvider::class,
        Illuminate\Validation\ValidationServiceProvider::class,
        Illuminate\View\ViewServiceProvider::class,

        /*
         * Application Service Providers...
         */
        App\Providers\AppServiceProvider::class,
        App\Providers\AuthServiceProvider::class,
        App\Providers\BroadcastServiceProvider::class,
        App\Providers\EventServiceProvider::class,
        App\Providers\Filament\AdminPanelProvider::class,
        App\Providers\RouteServiceProvider::class,
        App\Providers\SanctumServiceProvider::class,

        // Binds the base default implementation for every domain contract.
        // MUST come before PackageServiceProvider so package providers (registered
        // by it) can override these defaults.
        App\Providers\ContractsServiceProvider::class,

        // Generic package discovery — scans backend/packages/*, reads each
        // package's own composer.json, registers its PSR-4 + provider(s).
        App\Providers\PackageServiceProvider::class,

    ],

    /*
    |--------------------------------------------------------------------------
    | Class Aliases
    |--------------------------------------------------------------------------
    |
    | This array of class aliases will be registered when this application
    | is started. However, feel free to register as many as you wish as
    | the aliases are "lazy" loaded so they don't hinder performance.
    |
    */

    'aliases' => [

        // Package SDK facades (base seams; packages bind the real implementations)
        'Media'  => App\Facades\Media::class,
        'Notify' => App\Facades\Notify::class,
        'Wallet' => App\Facades\Wallet::class,

        'App' => Illuminate\Support\Facades\App::class,
        'Arr' => Illuminate\Support\Arr::class,
        'Artisan' => Illuminate\Support\Facades\Artisan::class,
        'Auth' => Illuminate\Support\Facades\Auth::class,
        'Blade' => Illuminate\Support\Facades\Blade::class,
        'Broadcast' => Illuminate\Support\Facades\Broadcast::class,
        'Bus' => Illuminate\Support\Facades\Bus::class,
        'Cache' => Illuminate\Support\Facades\Cache::class,
        'Config' => Illuminate\Support\Facades\Config::class,
        'Cookie' => Illuminate\Support\Facades\Cookie::class,
        'Crypt' => Illuminate\Support\Facades\Crypt::class,
        'Date' => Illuminate\Support\Facades\Date::class,
        'DB' => Illuminate\Support\Facades\DB::class,
        'Eloquent' => Illuminate\Database\Eloquent\Model::class,
        'Event' => Illuminate\Support\Facades\Event::class,
        'File' => Illuminate\Support\Facades\File::class,
        'Gate' => Illuminate\Support\Facades\Gate::class,
        'Hash' => Illuminate\Support\Facades\Hash::class,
        'Http' => Illuminate\Support\Facades\Http::class,
        'Js' => Illuminate\Support\Js::class,
        'Lang' => Illuminate\Support\Facades\Lang::class,
        'Log' => Illuminate\Support\Facades\Log::class,
        'Mail' => Illuminate\Support\Facades\Mail::class,
        'Notification' => Illuminate\Support\Facades\Notification::class,
        'Password' => Illuminate\Support\Facades\Password::class,
        'Queue' => Illuminate\Support\Facades\Queue::class,
        'RateLimiter' => Illuminate\Support\Facades\RateLimiter::class,
        'Redirect' => Illuminate\Support\Facades\Redirect::class,
        'Redis' => Illuminate\Support\Facades\Redis::class,
        'Request' => Illuminate\Support\Facades\Request::class,
        'Response' => Illuminate\Support\Facades\Response::class,
        'Route' => Illuminate\Support\Facades\Route::class,
        'Schema' => Illuminate\Support\Facades\Schema::class,
        'Session' => Illuminate\Support\Facades\Session::class,
        'Storage' => Illuminate\Support\Facades\Storage::class,
        'Str' => Illuminate\Support\Str::class,
        'URL' => Illuminate\Support\Facades\URL::class,
        'Validator' => Illuminate\Support\Facades\Validator::class,
        'View' => Illuminate\Support\Facades\View::class,

    ],

];
