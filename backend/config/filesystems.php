<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Filesystem Disk
    |--------------------------------------------------------------------------
    |
    | Here you may specify the default filesystem disk that should be used
    | by the framework. The "local" disk, as well as a variety of cloud
    | based disks are available to your application. Just store away!
    |
    */

    'default' => env('FILESYSTEM_DRIVER', 'local'),

    /*
    |--------------------------------------------------------------------------
    | Filesystem Disks
    |--------------------------------------------------------------------------
    |
    | Here you may configure as many filesystem "disks" as you wish, and you
    | may even configure multiple disks of the same driver. Defaults have
    | been setup for each driver as an example of the required options.
    |
    | Supported Drivers: "local", "ftp", "sftp", "s3"
    |
    */

    'disks' => [

        'local' => [
            'driver' => 'local',
            'root' => storage_path('app'),
        ],

        'public' => [
            'driver' => 'local',
            'root' => storage_path('app/public'),
            // Defaults to APP_URL/storage; override with STORAGE_PUBLIC_URL when
            // the host serving images differs (e.g. the Android emulator needs
            // http://10.0.2.2:8000/storage while admin stays on APP_URL).
            'url' => env('STORAGE_PUBLIC_URL', rtrim(env('APP_URL', 'http://localhost'), '/').'/storage'),
            'visibility' => 'public',
            'throw' => false,
        ],


        'conversation' => [
            'driver' => 'gcs',
            'root' => storage_path('app/public/conversation'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'path' => 'conversation',
        ],

        'admin' => [
            'driver' => 'gcs',
//            'root' => storage_path('app/public'),

            'key_file_path' => env('GOOGLE_CLOUD_KEY_FILE', base_path('service-account.json')), // optional: /path/to/service-account.json
            'key_file' => [], // optional: Array of data that substitutes the .json file (see below)
            'project_id' => env('GOOGLE_CLOUD_PROJECT_ID', 'your-project-id'), // optional: is included in key file
            'bucket' => env('GOOGLE_CLOUD_STORAGE_BUCKET', 'your-bucket'),
            //            'path' => 'storage/app/public',
            'url' => 'https://storage.googleapis.com/'.env('GOOGLE_CLOUD_STORAGE_BUCKET'),
            'path_prefix' => '', // optional: /default/path/to/apply/in/bucket
            //            'storage_api_uri' => env('GOOGLE_CLOUD_STORAGE_API_URI', null), // see: Public URLs below
            //            'apiEndpoint' => env('GOOGLE_CLOUD_STORAGE_API_ENDPOINT', null), // set storageClient apiEndpoint
            //            'visibility' => 'public', // optional: public|private
            //            'visibility_handler' => null, // optional: set to \League\Flysystem\GoogleCloudStorage\UniformBucketLevelAccessVisibility::class to enable uniform bucket level access
            //            'metadata' => ['cacheControl'=> 'public,max-age=86400'], // optional: default metadata
        ],


        'profile' => [
            'driver' => 'gcs',
            'root' => storage_path('app/public/profile'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'path' => 'profile',
        ],

        'custom' => [
            'driver' => 'gcs',
            'root' => public_path(''),
            'url' => env('APP_URL').'/public',
            'visibility' => 'public',
        ],

        'ticket' => [
            'driver' => 'gcs',
            'root' => storage_path('app/public/ticket'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'path' => 'ticket'
        ],

        'rooms' => [
            'driver' => 'gcs',
            'root' => storage_path('app/public/rooms'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'path' => 'rooms'
        ],
        'unions' => [
            'driver' => 'gcs',
            'root' => storage_path('app/public/unions'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'path' => 'unions'
        ],

        'families' => [
            'driver' => 'gcs',
            'root' => storage_path('app/public/families'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'path' => 'families'
        ],

        'images' => [
            'driver' => 'gcs',
            'root' => storage_path('app/public/images'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'path' => 'images'
        ],

        'videos' => [
            'driver' => 'gcs',
            'root' => storage_path('app/public/videos'),
            'url' => env('APP_URL').'/storage',
            'visibility' => 'public',
            'path' => 'videos'
        ],

        's3' => [
            'driver' => 's3',
            'key' => env('AWS_ACCESS_KEY_ID'),
            'secret' => env('AWS_SECRET_ACCESS_KEY'),
            'region' => env('AWS_DEFAULT_REGION'),
            'bucket' => env('AWS_BUCKET'),
            'url' => env('AWS_URL'),
            'endpoint' => env('AWS_ENDPOINT'),
            'use_path_style_endpoint' => env('AWS_USE_PATH_STYLE_ENDPOINT', false),
        ],

        'gcs' => [
            'driver' => 'gcs',
            'key_file_path' => env('GOOGLE_CLOUD_KEY_FILE', base_path('service-account.json')), // optional: /path/to/service-account.json
//            'key_file_path' => base_path('new-service-account.json'),
            'key_file' => [], // optional: Array of data that substitutes the .json file (see below)
            'project_id' => env('GOOGLE_CLOUD_PROJECT_ID', 'your-project-id'), // optional: is included in key file
            'bucket' => env('GOOGLE_CLOUD_STORAGE_BUCKET', 'your-bucket'),
            'path_prefix' => env('GOOGLE_CLOUD_STORAGE_PATH_PREFIX', ''), // optional: /default/path/to/apply/in/bucket
            'storage_api_uri' => env('GOOGLE_CLOUD_STORAGE_API_URI', null), // see: Public URLs below
            'apiEndpoint' => env('GOOGLE_CLOUD_STORAGE_API_ENDPOINT', null), // set storageClient apiEndpoint
            'visibility' => 'public', // optional: public|private
            'visibility_handler' => null, // optional: set to \League\Flysystem\GoogleCloudStorage\UniformBucketLevelAccessVisibility::class to enable uniform bucket level access
            'metadata' => ['cacheControl'=> 'public,max-age=86400'], // optional: default metadata
            'url' => 'https://storage.googleapis.com/'.env('GOOGLE_CLOUD_STORAGE_BUCKET'),

        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Symbolic Links
    |--------------------------------------------------------------------------
    |
    | Here you may configure the symbolic links that will be created when the
    | `storage:link` Artisan command is executed. The array keys should be
    | the locations of the links and the values should be their targets.

    |
    */

    'links' => [
        public_path('storage') => storage_path('app/public'),
    ],

];
