<?php



return [

    /*
    |--------------------------------------------------------------------------
    | Octane Server
    |--------------------------------------------------------------------------
    |
    | This value is the type of server that Octane will be running on.
    |
    */

    'server' => env('OCTANE_SERVER', 'swoole'),

    /*
    |--------------------------------------------------------------------------
    | Octane Port
    |--------------------------------------------------------------------------
    |
    | This value is the port that Octane will be listening on.
    |
    */

    'port' => env('OCTANE_PORT', 8000),

    /*
    |--------------------------------------------------------------------------
    | Octane Workers
    |--------------------------------------------------------------------------
    |
    | The number of workers that should be assigned to Octane. By default,
    | this will be the number of CPU cores available on the machine.
    |
    */

    'workers' => env('OCTANE_WORKERS'),

    /*
    |--------------------------------------------------------------------------
    | Octane Max Requests
    |--------------------------------------------------------------------------
    |
    | The number of requests an Octane worker will process before being
    | recycled. This is useful for preventing memory leaks.
    |
    */

    'max_requests' => env('OCTANE_MAX_REQUESTS', 500),

    /*
    |--------------------------------------------------------------------------
    | Octane Tick Frequency
    |--------------------------------------------------------------------------
    |
    | The number of milliseconds between each "tick" of the Octane server.
    |
    */

    'tick_frequency' => env('OCTANE_TICK_FREQUENCY', 1000),

    /*
    |--------------------------------------------------------------------------
    | Octane Cache Table Size
    |--------------------------------------------------------------------------
    |
    | The size of the Swoole table used for caching.
    |
    */

    'cache_table_size' => env('OCTANE_CACHE_TABLE_SIZE', 32000),

    /*
    |--------------------------------------------------------------------------
    | Octane Listeners
    |--------------------------------------------------------------------------
    |
    | These listeners are called at various points in the Octane lifecycle.
    | They can be used to perform tasks like closing idle database connections.
    |
    */

    'listeners' => [
        //
    ],

    /*
    |--------------------------------------------------------------------------
    | Octane Middleware
    |--------------------------------------------------------------------------
    |
    | These middleware are applied to all requests processed by Octane.
    |
    */

    'middleware' => [
        // 'Illuminate\Http\Middleware\TrustProxies',
    ],

    /*
    |--------------------------------------------------------------------------
    | Octane Warm
    |--------------------------------------------------------------------------
    |
    | These classes will be instantiated and registered in the container
    | when Octane starts. This is useful for warming up the application.
    |
    */

    'warm' => [
        // 'App\Models\User',
    ],

];
