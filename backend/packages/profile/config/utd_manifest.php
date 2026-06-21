<?php

/**
 * UTD Studio manifest for the PROFILE package.
 *
 * Ships the user-profile screen as a server-driven Stac screen editable from
 * UTD Studio. Follows the package authoring rules: the screen is decomposed
 * into explicit Craft primitives (Container/Row/Image/Text under a Scope) — NO
 * opaque package widget — so the designer can move/restyle/hide every piece.
 *
 * Every `binding` here resolves against the `profile.user` object source, whose
 * keys are produced on the client by `registerProfileStacSources()`
 * (flutter/lib/src/stac/profile_stac_sources.dart). Keys map 1:1 — no extra
 * mapping. UTD Studio discovers this via GET /api/utd/manifest and seeds the
 * Craft tree below into the app's Stac screens on Sync.
 *
 * DESIGN: mirrors the REAL native profile (the "Lumia" centered identity block —
 * circular avatar, name + country flag, UID, bio, email, country). This screen
 * renders inside the AppShell, so its ROOT is TRANSPARENT and the purple shell
 * Scaffold fills the whole screen (no short-container "split"). Empty fields
 * hide via visibleBinding so it degrades cleanly. The gradient ring / level
 * badges are bespoke Flutter flourishes primitives can't express.
 */

// ── Craft node helper (same shape the Studio design scripts emit) ──────────
$node = function (string $name, bool $canvas, array $props, array $kids = [], ?string $parent = null): array {
    $n = [
        'type'        => ['resolvedName' => $name],
        'isCanvas'    => $canvas,
        'props'       => $props,
        'displayName' => $name,
        'hidden'      => false,
        'nodes'       => $kids,
        'linkedNodes' => [],
    ];
    if ($parent !== null) {
        $n['parent'] = $parent;
    }
    return $n;
};

// ── Lumia palette ──────────────────────────────────────────────────────────
$C = [
    'screen'  => '#00000000', // transparent → inherit the AppShell's purple Scaffold
    'white'   => '#FFFFFF',
    'muted'   => '#CDBFEE',   // lumiaTextSecondary
    'bioText' => '#E3D8FB',
];

// user_profile — CENTERED identity bound to profile.user (Scope): circular
// avatar, name + country flag, UID, bio, email, country. Matches the native
// "Me"/profile landing (no cover banner in the main view).
$profileWidgets = [
    'ROOT'    => $node('Container', true, ['background' => $C['screen'], 'padding' => 20, 'gap' => 12, 'align' => 'center', 'flex' => 0], ['scope'], null),
    'scope'   => $node('Scope', true, ['source' => 'profile.user'], ['avatar', 'nameRow', 'uid', 'bio', 'country'], 'ROOT'),

    'avatar'  => $node('Image', false, ['src' => '', 'binding' => 'profile.user.avatar', 'width' => 110, 'height' => 110, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0], [], 'scope'),

    'nameRow' => $node('Row', true, ['gap' => 6, 'align' => 'center'], ['name', 'flag'], 'scope'),
    'name'    => $node('Text', false, ['text' => 'الاسم', 'binding' => 'profile.user.name', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'flag'    => $node('Image', false, ['src' => '', 'binding' => 'profile.user.flag', 'visibleBinding' => 'profile.user.flag', 'width' => 24, 'height' => 16, 'fit' => 'cover', 'radius' => 3], [], 'nameRow'),

    'uid'     => $node('Text', false, ['text' => '', 'binding' => 'profile.user.uid', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'scope'),
    'bio'     => $node('Text', false, ['text' => '', 'binding' => 'profile.user.bio', 'visibleBinding' => 'profile.user.bio', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['bioText'], 'align' => 'center', 'maxLines' => 0], [], 'scope'),
    'country' => $node('Text', false, ['text' => '', 'binding' => 'profile.user.country', 'visibleBinding' => 'profile.user.country', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 0], [], 'scope'),
];

return [
    'key'     => 'profile',
    'name'    => 'Profile',
    'icon'    => 'person',
    'screens' => ['user_profile'],

    // Display bindings (profile screen ⇄ profile.user object source)
    'elements' => [
        ['key' => 'name',    'label' => 'الاسم',    'type' => 'string',    'screen' => 'user_profile'],
        ['key' => 'bio',     'label' => 'نبذة',     'type' => 'string',    'screen' => 'user_profile'],
        ['key' => 'avatar',  'label' => 'الصورة',   'type' => 'image_url', 'screen' => 'user_profile'],
        ['key' => 'cover',   'label' => 'الغلاف',     'type' => 'image_url', 'screen' => 'user_profile'],
        ['key' => 'country', 'label' => 'الدولة',     'type' => 'string',    'screen' => 'user_profile'],
        ['key' => 'flag',    'label' => 'علم الدولة', 'type' => 'image_url', 'screen' => 'user_profile'],
        ['key' => 'uid',     'label' => 'المعرّف',    'type' => 'string',    'screen' => 'user_profile'],
    ],

    // Single-object source: the signed-in user's profile. Resolved on the client
    // by `registerProfileStacSources()`.
    'object_sources' => [
        [
            'key'      => 'profile.user',
            'label'    => 'الملف الشخصي',
            'provides' => [
                ['key' => 'name',    'label' => 'الاسم',   'type' => 'string'],
                ['key' => 'bio',     'label' => 'نبذة',    'type' => 'string'],
                ['key' => 'avatar',  'label' => 'الصورة',  'type' => 'image_url'],
                ['key' => 'cover',   'label' => 'الغلاف',     'type' => 'image_url'],
                ['key' => 'country', 'label' => 'الدولة',     'type' => 'string'],
                ['key' => 'flag',    'label' => 'علم الدولة', 'type' => 'image_url'],
                ['key' => 'uid',     'label' => 'المعرّف',    'type' => 'string'],
            ],
        ],
    ],

    'action_elements' => [
        // Open the (native) edit-profile screen. Reuses the core navigate action.
        [
            'key' => 'open_edit', 'label' => 'تعديل الملف',
            'produces' => 'core.navigate', 'default_shape' => 'button', 'screen' => 'user_profile',
            'params' => [
                ['key' => 'route', 'label' => 'الشاشة', 'type' => 'route'],
                ['key' => 'mode',  'label' => 'النمط (go/push/replace)', 'type' => 'string'],
            ],
        ],
    ],

    // ── Ready-to-edit default screen (seeded by UTD Studio on Sync) ──
    'default_screens' => [
        [
            'name'         => 'user_profile',
            'label'        => 'الملف الشخصي',
            'icon'         => '👤',
            'version'      => '1.2.0',
            'nav'          => false,
            'navIcon'      => 'person',
            'order'        => 31,
            'role'         => 'auth.profile',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'الملف الشخصي', 'bg' => $C['screen'], 'actions' => []]],
            'widgets'      => $profileWidgets,
        ],
    ],
];
