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
    // feed_ranking   : when true, the deck is ordered by a recency-decayed
    //                  engagement score (likes/comments/views) via a weighted
    //                  shuffle + author-diversity pass, so better/fresher reels
    //                  surface while every user still gets a varied, spread mix.
    //                  Set false to fall back to a plain random shuffle.
    'feed_deck_size'  => (int) env('REELS_FEED_DECK_SIZE', 1000),
    'feed_window_ttl' => (int) env('REELS_FEED_WINDOW_TTL', 60),
    'feed_ranking'    => filter_var(env('REELS_FEED_RANKING', true), FILTER_VALIDATE_BOOLEAN),

    // ── Seen-exclusion (don't re-show reels a user already watched) ───────────
    // The feed remembers the ids it served each user (in the cache — NO DB write)
    // and skips them on later pages/refreshes, so scrolling + pull-to-refresh keep
    // surfacing fresh reels instead of looping the same rotation. Best-effort: any
    // cache hiccup degrades to "no memory" (a possible repeat), never an error.
    // Keep feed_seen_cap BELOW feed_deck_size so there's always something unseen
    // to show (otherwise the feed falls back to re-showing the rotation).
    //
    // feed_seen_exclusion: master on/off (REELS_FEED_SEEN).
    // feed_seen_cap      : max reel ids remembered per user (most-recent kept).
    // feed_seen_ttl      : how long (seconds) that memory lasts (default 6h).
    'feed_seen_exclusion' => filter_var(env('REELS_FEED_SEEN', true), FILTER_VALIDATE_BOOLEAN),
    'feed_seen_cap'       => (int) env('REELS_FEED_SEEN_CAP', 400),
    'feed_seen_ttl'       => (int) env('REELS_FEED_SEEN_TTL', 21600),
];
