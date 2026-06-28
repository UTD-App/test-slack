<?php

return [
    'name' => 'Reels',

    // Secret guard for the dev seed route (GET /api/reels/seed?key=...). In
    // local/development/testing the route runs WITHOUT a key; in any other
    // environment (e.g. production) it requires ?key= to match this value, and
    // is blocked entirely when this is null. Override via REELS_SEED_KEY.
    'seed_key' => env('REELS_SEED_KEY'),

    // ── Feed load-spreading (see ReelsRepository::getAllReels) ───────────────
    // The feed serves a "deck" of the most-recent N reel ids, shared across all
    // users and cached briefly. Each user is rotated to a DIFFERENT start index
    // in that deck (offset derived from their user id), so 100 users entering at
    // once read 100 different windows of the catalog instead of hammering the
    // same newest few — spreading DB/storage/origin read load across the deck.
    //
    // feed_deck_size : how many recent reels form the deck a user rotates over.
    //                  Bigger = more spread + more reels before any repeat, at
    //                  the cost of a larger (still id-only) cached array.
    // feed_window_ttl: seconds the shared deck stays cached before it's rebuilt
    //                  (and re-shuffled), picking up newly uploaded reels.
    'feed_deck_size'  => (int) env('REELS_FEED_DECK_SIZE', 1000),
    'feed_window_ttl' => (int) env('REELS_FEED_WINDOW_TTL', 60),
];
