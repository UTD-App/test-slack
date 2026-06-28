<?php

return [
    'name' => 'Reels',

    // Secret guard for the dev seed route (GET /api/reels/seed?key=...). In
    // local/development/testing the route runs WITHOUT a key; in any other
    // environment (e.g. production) it requires ?key= to match this value, and
    // is blocked entirely when this is null. Override via REELS_SEED_KEY.
    'seed_key' => env('REELS_SEED_KEY'),
];
