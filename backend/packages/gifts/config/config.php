<?php

return [

    // When false, the package does NOT bind GiftSender (gifting stays disabled → 503).
    'enabled' => env('GIFTS_ENABLED', true),

    /*
    | Currency the SENDER spends (must exist in config('wallet.currencies')).
    */
    'spend_currency' => 'coins',

    /*
    | Currency the RECEIVER earns. The gift value is credited here as the
    | host/earning currency. Requires 'diamonds' in config('wallet.currencies').
    */
    'earn_currency' => 'diamonds',

    /*
    | Fraction of the gift value the receiver earns (1.0 = full value).
    | Platform / room-owner / agency splits are layered later by listeners of
    | the App\Events\Gifts\GiftSent event — not here.
    */
    'receiver_rate' => 1.0,

    /*
    | Lucky gifts (type = lucky) require the lucky-gift plugin to bind
    | App\Contracts\LuckyGiftResolver. Until then they stay disabled.
    */
    'lucky_enabled' => false,

    /*
    | Enforce a gift's vip_level requirement on the sender. Only takes effect
    | when the vip package binds App\Contracts\VipLevelProvider; while unbound the
    | gate is skipped regardless of this flag.
    */
    'vip_gate' => true,

    // Cache TTL (seconds) for the gift catalog.
    'catalog_ttl' => 1800,

    /*
    | EXP conversion rates that drive sender/receiver levels (Eagle's exp). EXP is
    | banked per gift and accumulates (see gift_user_exp); the level is the highest
    | gift_levels threshold the stored exp reaches:
    |   sender   exp += coins spent    × exp_per_coin
    |   receiver exp += diamonds earned × exp_per_diamond
    | These are the DEFAULTS — the admin overrides them on the Gift EXP settings
    | page (stored in gift_settings, read via Support\GiftSettings).
    */
    'exp_per_coin'    => 1.0,
    'exp_per_diamond' => 1.0,
];
