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
 * DESIGN: a "Me hub" — centered identity header (avatar/name/flag/uid/bio) with
 * inline EDIT affordances (tap avatar / "تغيير الصورة" to change photo; pencils
 * by name + bio open the edit screen) + tappable menu cards. Renders inside the
 * AppShell, so its ROOT is TRANSPARENT (the purple shell Scaffold fills the
 * screen). bio falls back to a "أضف نبذة" placeholder in the data source so the
 * bio + pencil row stays meaningful. Gradient ring / camera badge overlapping
 * the avatar / level badges are bespoke Flutter flourishes primitives can't do.
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
    'screen'     => '#00000000', // transparent → inherit the AppShell's purple Scaffold
    'card'       => '#5B4399',
    'cardBorder' => '#8E72D2',
    'accentLt'   => '#D9A0FF', // links / edit pencils
    'white'      => '#FFFFFF',
    'muted'      => '#CDBFEE',
    'bioText'    => '#E3D8FB',
];

// Reusable tappable menu card (tinted icon + label + chevron), parented to ROOT.
$mkTile = function (string $id, string $icon, string $tint, string $label, array $tapParams) use ($node, $C): array {
    return [
        $id         => $node('Container', true, ['background' => $C['card'], 'radius' => 14, 'padding' => 14, 'borderWidth' => 1, 'borderColor' => $C['cardBorder'], 'gap' => 0, 'align' => 'stretch', 'onTapAction' => 'core.navigate', 'onTapTarget' => '', 'onTapParams' => $tapParams], [$id . 'Row'], 'ROOT'),
        $id . 'Row' => $node('Row', true, ['gap' => 12, 'align' => 'center'], [$id . 'Ic', $id . 'Lb', $id . 'Ch'], $id),
        $id . 'Ic'  => $node('Icon', false, ['name' => $icon, 'size' => 20, 'color' => $tint], [], $id . 'Row'),
        $id . 'Lb'  => $node('Text', false, ['text' => $label, 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['white'], 'align' => 'right', 'binding' => '', 'maxLines' => 1, 'flex' => 1], [], $id . 'Row'),
        $id . 'Ch'  => $node('Icon', false, ['name' => 'chevron_left', 'size' => 18, 'color' => $C['muted']], [], $id . 'Row'),
    ];
};

// user_profile — "Me hub" bound to profile.user, with inline edit affordances.
$profileWidgets = array_merge(
    [
        'ROOT'       => $node('Container', true, ['background' => $C['screen'], 'padding' => 20, 'gap' => 14, 'align' => 'stretch', 'flex' => 0], ['scope', 'mSettings', 'mContact', 'mAbout'], null),
        'scope'      => $node('Scope', true, ['source' => 'profile.user'], ['header'], 'ROOT'),
        'header'     => $node('Container', true, ['background' => '#00000000', 'padding' => 8, 'gap' => 8, 'align' => 'center', 'flex' => 0], ['avatar', 'photoLink', 'nameRow', 'uid', 'bioRow'], 'scope'),
        'avatar'     => $node('Image', false, ['src' => '', 'binding' => 'profile.user.avatar', 'width' => 116, 'height' => 116, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0, 'onTapAction' => 'core.changeAvatar', 'onTapTarget' => '', 'onTapParams' => ['source' => 'gallery']], [], 'header'),
        'photoLink'  => $node('Container', true, ['background' => '#00000000', 'padding' => 2, 'gap' => 0, 'align' => 'center', 'onTapAction' => 'core.changeAvatar', 'onTapTarget' => '', 'onTapParams' => ['source' => 'gallery']], ['photoRow'], 'header'),
        'photoRow'   => $node('Row', true, ['gap' => 4, 'align' => 'center'], ['camIcon', 'camText'], 'photoLink'),
        'camIcon'    => $node('Icon', false, ['name' => 'photo_camera', 'size' => 15, 'color' => $C['accentLt']], [], 'photoRow'),
        'camText'    => $node('Text', false, ['text' => 'تغيير الصورة', 'fontSize' => 13, 'fontWeight' => 500, 'color' => $C['accentLt'], 'align' => 'center', 'binding' => '', 'maxLines' => 1], [], 'photoRow'),
        'nameRow'    => $node('Row', true, ['gap' => 6, 'align' => 'center'], ['name', 'flag', 'namePencil'], 'header'),
        'name'       => $node('Text', false, ['text' => 'الملف الشخصي', 'binding' => 'profile.user.name', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
        'flag'       => $node('Image', false, ['src' => '', 'binding' => 'profile.user.flag', 'visibleBinding' => 'profile.user.flag', 'width' => 24, 'height' => 16, 'fit' => 'cover', 'radius' => 3], [], 'nameRow'),
        'namePencil' => $node('Icon', false, ['name' => 'edit', 'size' => 16, 'color' => $C['accentLt'], 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/profile', 'mode' => 'push']], [], 'nameRow'),
        'uid'        => $node('Text', false, ['text' => '', 'binding' => 'profile.user.uid', 'visibleBinding' => 'profile.user.uid', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'header'),
        'bioRow'     => $node('Row', true, ['gap' => 6, 'align' => 'center'], ['bio', 'bioPencil'], 'header'),
        'bio'        => $node('Text', false, ['text' => '', 'binding' => 'profile.user.bio', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['bioText'], 'align' => 'center', 'maxLines' => 0], [], 'bioRow'),
        'bioPencil'  => $node('Icon', false, ['name' => 'edit', 'size' => 14, 'color' => $C['accentLt'], 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/profile', 'mode' => 'push']], [], 'bioRow'),
    ],
    $mkTile('mSettings', 'settings', '#42A5F5', 'الإعدادات', ['route' => '/settings', 'mode' => 'push']),
    $mkTile('mContact', 'support_agent', '#26C6DA', 'تواصل معنا', ['route' => '/contact-us', 'mode' => 'push']),
    $mkTile('mAbout', 'info', '#7C4DFF', 'عن التطبيق', ['route' => '/page/about', 'mode' => 'push'])
);

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
            'version'      => '1.4.0',
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
