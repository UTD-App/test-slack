<?php

/**
 * UTD Studio manifest for the WALLET package.
 *
 * Exposes the coin balance as a design-time contract so UTD Studio can bind it
 * on any screen (e.g. a coin card composed into the `profile` screen). The
 * editor reads this via GET /api/utd/manifest (X-UTD-Secret).
 *
 * Runtime data lives on the Flutter side:
 *   flutter/lib/src/stac/wallet_stac_sources.dart → registerWalletStacSources()
 *   registers the single-object source `wallet.balance` ({ coins }). The map key
 *   MUST match the `provides` key below so the designer's binding
 *   `wallet.balance.coins` resolves with no extra mapping.
 *
 * Authoring rule (docs/PACKAGE-AUTHORING-RULES.md): the coin card is built from
 * primitive Craft nodes (Container/Row/Icon/Text) bound to `wallet.balance.*` —
 * NOT an opaque PackageWidget — so the designer can move/restyle/hide it.
 */

return [
    'key'     => 'wallet',
    'name'    => 'Wallet',
    'icon'    => 'account_balance_wallet',
    'screens' => [],

    // Bindable fields the designer sees in the Studio palette.
    'elements' => [
        ['key' => 'coins', 'label' => 'رصيد الكوينز', 'type' => 'string'],
    ],

    // Single-object source: the signed-in user's coin balance. Resolved on the
    // client by registerWalletStacSources() (StacDataRegistry → wallet.balance).
    'object_sources' => [
        [
            'key'      => 'wallet.balance',
            'label'    => 'رصيد المحفظة',
            'provides' => [
                ['key' => 'coins', 'label' => 'رصيد الكوينز', 'type' => 'string'],
            ],
        ],
    ],

    // Open the wallet page (the package registers the /wallet route).
    'action_elements' => [
        [
            'key'      => 'open_wallet',
            'label'    => 'فتح المحفظة',
            'produces' => 'wallet.open',
            'default_shape' => 'button',
        ],
    ],
];
