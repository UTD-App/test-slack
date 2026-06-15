<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Master switch
    |--------------------------------------------------------------------------
    | When false, Notifier::send/broadcast become no-ops (nothing stored or pushed).
    */
    'enabled' => env('NOTIFICATIONS_ENABLED', true),

    /*
    |--------------------------------------------------------------------------
    | Built-in channels
    |--------------------------------------------------------------------------
    | `database` (in-app feed) is always registered. `push` wraps the Base
    | NotificationSender (Firebase) and can be toggled off here. Channel plugins
    | (realtime, email, sms) register themselves with the ChannelRegistry.
    */
    'channels' => [
        'push' => env('NOTIFICATIONS_PUSH', true),
    ],

    /*
    |--------------------------------------------------------------------------
    | Feed
    |--------------------------------------------------------------------------
    */
    'per_page' => (int) env('NOTIFICATIONS_PER_PAGE', 20),

    /*
    |--------------------------------------------------------------------------
    | Push render locale fallback
    |--------------------------------------------------------------------------
    | Locale used to render PUSH messages when the recipient has no stored locale.
    | (The in-app feed always renders in the reader's request locale.)
    */
    'push_locale_fallback' => env('NOTIFICATIONS_PUSH_LOCALE', config('app.locale', 'en')),

];
