<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default Queue Connection Name
    |--------------------------------------------------------------------------
    |
    | Laravel's queue API supports an assortment of back-ends via a single
    | API, giving you convenient access to each back-end using the same
    | syntax for every one. Here you may define a default connection.
    |
    | Default: redis (for production)
    | Fallback: database (for development)
    |
    */

    'default' => env('QUEUE_CONNECTION', 'redis'),

    /*
    |--------------------------------------------------------------------------
    | Queue Connections
    |--------------------------------------------------------------------------
    |
    | Here you may configure the connection information for each server that
    | is used by your application. A default configuration has been added
    | for each back-end shipped with Laravel. You are free to add more.
    |
    | Drivers: "sync", "database", "beanstalkd", "sqs", "redis", "null"
    |
    */

    'connections' => [

        'sync' => [
            'driver' => 'sync',
        ],

        'database' => [
            'driver' => 'database',
            'table' => 'jobs',
            'queue' => 'default',
            'retry_after' => 300,
            'after_commit' => true,
        ],
        
        'luckyBox' => [
            'driver' => 'database',
            'connection' => 'default',
            'queue' => 'luckyBox',
            'retry_after' => 300,
            'block_for' => null,
            'after_commit' => true,
        ],
        'heavyProcessing' => [
            'driver' => env('QUEUE_CONNECTION', 'redis'),
            'connection' => 'default',
            'queue' => ['heavy1', 'heavy2', 'heavy3'],
            'retry_after' => 300,
            'block_for' => null,
            'after_commit' => true,
        ],
        'sendComment' => [
            'driver' => 'database',
            'connection' => 'default',
            'queue' => 'sendComment',
            'retry_after' => 300,
            'after_commit' => true,
        ],
        'notification' => [
            'driver' => 'database',
            'connection' => 'default',
            'queue' => ['default','heavy1'],
            'retry_after' => 300,
            'block_for' => null,
            'after_commit' => true,
        ],
        'luckyGift' => [
            'driver' => 'database',
            'connection' => 'default',
            'queue' => ['lucky_gift', 'lucky_gift_2', 'lucky_gift_3'],
            'retry_after' => 300,
            'block_for' => null,
            'after_commit' => true,
        ],

        'increment-diamond' => [
            'driver' => 'database',
            'connection' => 'default',
            'queue' => 'increment-diamond',
            'retry_after' => 300,
            'block_for' => null,
            'after_commit' => true,
        ],

        'beanstalkd' => [
            'driver' => 'beanstalkd',
            'host' => 'localhost',
            'queue' => 'default',
            'retry_after' => 300,
            'block_for' => 0,
            'after_commit' => true,
        ],

        'sqs' => [
            'driver' => 'sqs',
            'key' => env('AWS_ACCESS_KEY_ID'),
            'secret' => env('AWS_SECRET_ACCESS_KEY'),
            'prefix' => env('SQS_PREFIX', 'https://sqs.us-east-1.amazonaws.com/your-account-id'),
            'queue' => env('SQS_QUEUE', 'default'),
            'suffix' => env('SQS_SUFFIX'),
            'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
            'after_commit' => true,
            'retry_after' => 300,
        ],

        'redis' => [
            'driver' => 'redis',
            'connection' => 'default',
            'queue' => env('QUEUE_NAME', 'default'),
            'retry_after' => 300,
            'block_for' => null,
            'after_commit' => true,
        ],

    ],

    /*
    |--------------------------------------------------------------------------
    | Failed Queue Jobs
    |--------------------------------------------------------------------------
    |
    | These options configure the behavior of failed queue job logging so you
    | can control which database and table are used to store the jobs that
    | have failed. You may change them to any database / table you wish.
    |
    */

    'failed' => [
        'driver' => env('QUEUE_FAILED_DRIVER', 'database-uuids'),
        'database' => env('DB_CONNECTION', 'mysql'),
        'table' => 'failed_jobs',
    ],

    /*
    |--------------------------------------------------------------------------
    | Supervisor Configuration
    |--------------------------------------------------------------------------
    |
    | The supervisor group name for queue workers. Used when auto-restarting
    | workers after Pusher config changes.
    |
    */
    
    'supervisor_group' => env('QUEUE_SUPERVISOR_GROUP', 'laravel-worker:*'),

];
