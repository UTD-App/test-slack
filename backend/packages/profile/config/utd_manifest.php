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

// user_profile — avatar + name + uid + bio + country bound to profile.user (Scope)
$profileWidgets = [
    'ROOT'    => $node('Container', true, ['background' => '#ffffff', 'padding' => 16, 'gap' => 12, 'align' => 'stretch', 'flex' => 0], ['scope'], null),
    'scope'   => $node('Scope', true, ['source' => 'profile.user'], ['cover', 'row', 'bio', 'country'], 'ROOT'),

    // Cover banner — hidden when the user has no cover image.
    'cover'   => $node('Image', false, ['src' => '', 'binding' => 'profile.user.cover', 'visibleBinding' => 'profile.user.cover', 'height' => 160, 'fit' => 'cover', 'radius' => 12], [], 'scope'),

    // Header row: circular avatar + (name / uid) column.
    'row'     => $node('Row', true, ['gap' => 12, 'align' => 'center'], ['avatar', 'idcol'], 'scope'),
    'avatar'  => $node('Image', false, ['src' => '', 'binding' => 'profile.user.avatar', 'width' => 88, 'height' => 88, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0], [], 'row'),
    'idcol'   => $node('Container', true, ['flex' => 1, 'gap' => 4, 'align' => 'flex-start'], ['name', 'uid'], 'row'),
    'name'    => $node('Text', false, ['text' => 'الاسم', 'binding' => 'profile.user.name', 'fontSize' => 18, 'fontWeight' => 600, 'color' => '#0F172A', 'align' => 'right', 'maxLines' => 0], [], 'idcol'),
    'uid'     => $node('Text', false, ['text' => '', 'binding' => 'profile.user.uid', 'fontSize' => 12, 'fontWeight' => 400, 'color' => '#94A3B8', 'align' => 'right', 'maxLines' => 0], [], 'idcol'),

    'bio'     => $node('Text', false, ['text' => 'نبذة', 'binding' => 'profile.user.bio', 'fontSize' => 14, 'fontWeight' => 400, 'color' => '#334155', 'align' => 'right', 'maxLines' => 0], [], 'scope'),
    'country' => $node('Text', false, ['text' => '', 'binding' => 'profile.user.country', 'fontSize' => 13, 'fontWeight' => 400, 'color' => '#64748B', 'align' => 'right', 'maxLines' => 0], [], 'scope'),
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
        ['key' => 'cover',   'label' => 'الغلاف',   'type' => 'image_url', 'screen' => 'user_profile'],
        ['key' => 'country', 'label' => 'الدولة',   'type' => 'string',    'screen' => 'user_profile'],
        ['key' => 'uid',     'label' => 'المعرّف',  'type' => 'string',    'screen' => 'user_profile'],
    ],

    // Single-object source: the signed-in user's profile. A `Scope` (utdObject)
    // bound to `profile.user` lets the designer bind its children to the live
    // profile. Resolved on the client by `registerProfileStacSources()`.
    'object_sources' => [
        [
            'key'      => 'profile.user',
            'label'    => 'الملف الشخصي',
            'provides' => [
                ['key' => 'name',    'label' => 'الاسم',   'type' => 'string'],
                ['key' => 'bio',     'label' => 'نبذة',    'type' => 'string'],
                ['key' => 'avatar',  'label' => 'الصورة',  'type' => 'image_url'],
                ['key' => 'cover',   'label' => 'الغلاف',  'type' => 'image_url'],
                ['key' => 'country', 'label' => 'الدولة',  'type' => 'string'],
                ['key' => 'uid',     'label' => 'المعرّف', 'type' => 'string'],
            ],
        ],
    ],

    'action_elements' => [
        // Open the (native) edit-profile screen. Reuses the core navigate action
        // — no package-specific Flutter parser needed.
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
            'version'      => '1.0.0',
            'nav'          => false,
            'navIcon'      => 'person',
            'order'        => 31,
            'role'         => 'auth.profile',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => true, 'title' => 'الملف الشخصي', 'bg' => '#ffffff', 'actions' => []]],
            'widgets'      => $profileWidgets,
        ],
    ],
];
