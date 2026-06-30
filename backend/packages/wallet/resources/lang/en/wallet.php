<?php

// Wallet UI strings (the Flutter `wallet.*` keys). Stored FLAT; served via the API
// and overlaid over the package's baked-in defaults (backend wins). Nested arrays
// flatten to dot-keys (e.g. tx_type.admin_charge -> `wallet.tx_type.admin_charge`).

return [
    'title'           => 'Wallet',
    'coins'           => 'Coins',
    'transactions'    => 'Transactions',
    'no_transactions' => 'No transactions yet',
    'filter'          => 'Filter',
    'clear_filter'    => 'Clear',
    'something_wrong' => 'Something went wrong',
    'retry'           => 'Retry',

    // Transaction-type labels — mirror the CoinTransactionType enum (+ the
    // admin_deduct reason used by ChargeService). The app falls back to the
    // humanized type when a key is missing, so new types still render.
    'tx_type' => [
        'admin_charge'               => 'Admin charge',
        'admin_deduct'               => 'Admin deduction',
        'area_manager_charge'        => 'Area manager charge',
        'bd_charge'                  => 'BD charge',
        'app_charge'                 => 'In-app charge',
        'return_charge'              => 'Charge reversal',
        'payment'                    => 'Payment',
        'google_pay'                 => 'Google Pay',
        'huawei_pay'                 => 'Huawei Pay',
        'exchange'                   => 'Exchange',
        'gift'                       => 'Gift',
        'lucky_gift'                 => 'Lucky gift',
        'cashback'                   => 'Cashback',
        'daily_gift'                 => 'Daily gift',
        'room_target'                => 'Room target',
        'room_level'                 => 'Room level',
        'create_room'                => 'Create room',
        'room_comment'               => 'Room comment',
        'coin_game'                  => 'Coin game',
        'lucky_box'                  => 'Lucky box',
        'pk'                         => 'PK battle',
        'super_admin_reward'         => 'Super admin reward',
        'region_manager_reward'      => 'Region manager reward',
        'admin_reward'               => 'Admin reward',
        'room_boom'                  => 'Room boom',
        'room_cup'                   => 'Room cup',
        'host_level'                 => 'Host level',
        'weekly_star'                => 'Weekly star',
        'milestone'                  => 'Milestone',
        'gift_ranking'               => 'Gift ranking',
        'level_interval'             => 'Level reward',
        'charge_event'               => 'Charge event',
        'cp'                         => 'CP reward',
        'cps'                        => 'CPS reward',
        'invitation_code'            => 'Invitation code',
        'invitation_charge_earnings' => 'Invitation charge earnings',
        'compensation'               => 'Compensation',
        'remaining_diamonds'         => 'Remaining diamonds',
        'vip'                        => 'VIP',
        'pack'                       => 'Pack',
        'family'                     => 'Family',
        'background_images'          => 'Background image',
        'special_id'                 => 'Special ID',
    ],
];
