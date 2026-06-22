<?php

/**
 * UTD Studio manifest for the PROFILE package.
 *
 * Ships the user-profile screen as a server-driven Stac screen editable from
 * UTD Studio, decomposed into Stac PRIMITIVES (Container/Row/Image/Text under a
 * Scope) bound to the `profile.user` object source.
 *
 * NOTE: a richer pixel-match needs a CUSTOM native widget (`core.selfProfile`,
 * shipped + registered in Flutter as SelfProfileCardParser) — but UTD Studio's
 * Craft editor currently crashes deserializing a node of an unregistered custom
 * type. So until the Studio editor supports custom package widgets, this screen
 * stays primitives. See the message to the Studio owner.
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
// `screen` is a SOLID deep purple (not transparent): this screen opens as a
// full dialog from the avatar tap (core.openDialog style:full), so it can't
// inherit the AppShell's purple Scaffold — it must paint its own background.
$C = [
    'screen'  => '#241B45', // solid deep purple (dialog-safe background)
    'white'   => '#FFFFFF',
    'muted'   => '#CDBFEE',
    'bioText' => '#E3D8FB',
    'accent'  => '#BE4AFF',
    'pink'    => '#EC4899',
    'card'    => '#5B4399',
    'cardBd'  => '#8E72D2',
];

// user_profile — RICH profile bound to profile.user (primitives only): cover
// banner + gradient-ring avatar + name/flag + UID + bio card + country card,
// with a close button (core.closeDialog) since it's presented as a dialog.
// A starting layout the owner refines in UTD Studio (counters/cards need the
// social/gifts package bindings, added later).
$profileWidgets = [
    'ROOT'        => $node('Container', true, ['background' => $C['screen'], 'padding' => 0, 'gap' => 14, 'align' => 'stretch', 'flex' => 0], ['scope'], null),
    'scope'       => $node('Scope', true, ['source' => 'profile.user'], ['topBar', 'coverBox', 'header', 'bioCard', 'countryCard'], 'ROOT'),

    // Close button (dismisses the dialog).
    'topBar'      => $node('Container', true, ['background' => '#00000000', 'padding' => ['left' => 8, 'top' => 8, 'right' => 8, 'bottom' => 0], 'align' => 'start', 'flex' => 0], ['closeBtn'], 'scope'),
    'closeBtn'    => $node('Container', true, ['width' => 38, 'height' => 38, 'radius' => 19, 'background' => $C['card'], 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'onTapAction' => 'core.closeDialog'], ['closeIcon'], 'topBar'),
    'closeIcon'   => $node('Icon', false, ['name' => 'close', 'size' => 20, 'color' => $C['white']], [], 'closeBtn'),

    // Cover banner — full width via the column's stretch; hidden when no cover.
    'coverBox'    => $node('Container', true, ['margin' => ['left' => 16, 'top' => 0, 'right' => 16, 'bottom' => 0], 'padding' => 0, 'radius' => 18, 'background' => $C['card'], 'align' => 'stretch', 'flex' => 0, 'visibleBinding' => 'profile.user.cover'], ['coverImg'], 'scope'),
    'coverImg'    => $node('Image', false, ['src' => '', 'binding' => 'profile.user.cover', 'height' => 170, 'fit' => 'cover', 'radius' => 18], [], 'coverBox'),

    // Identity: gradient-ring avatar + name + flag + UID.
    'header'      => $node('Container', true, ['background' => '#00000000', 'padding' => ['left' => 16, 'top' => 0, 'right' => 16, 'bottom' => 0], 'gap' => 8, 'align' => 'center', 'flex' => 0], ['avatarRing', 'nameRow', 'uid'], 'scope'),
    'avatarRing'  => $node('Container', true, ['width' => 112, 'height' => 112, 'radius' => 56, 'gradient' => 1, 'gradFrom' => $C['accent'], 'gradTo' => $C['pink'], 'gradDir' => 'to bottom right', 'padding' => 4, 'align' => 'center', 'valign' => 'center', 'flex' => 0], ['avatarImg'], 'header'),
    'avatarImg'   => $node('Image', false, ['src' => '', 'binding' => 'profile.user.avatar', 'width' => 104, 'height' => 104, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0], [], 'avatarRing'),
    'nameRow'     => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['name', 'flag'], 'header'),
    'name'        => $node('Text', false, ['text' => 'الاسم', 'binding' => 'profile.user.name', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'flag'        => $node('Image', false, ['src' => '', 'binding' => 'profile.user.flag', 'visibleBinding' => 'profile.user.flag', 'width' => 26, 'height' => 18, 'fit' => 'cover', 'radius' => 3], [], 'nameRow'),
    'uid'         => $node('Text', false, ['text' => '', 'binding' => 'profile.user.uid', 'visibleBinding' => 'profile.user.uid', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'header'),

    // Bio card.
    'bioCard'     => $node('Container', true, ['margin' => ['left' => 16, 'top' => 0, 'right' => 16, 'bottom' => 0], 'padding' => 16, 'radius' => 16, 'background' => $C['card'], 'borderWidth' => 1, 'borderColor' => $C['cardBd'], 'gap' => 6, 'align' => 'stretch', 'flex' => 0], ['bioTitle', 'bio'], 'scope'),
    'bioTitle'    => $node('Text', false, ['text' => 'النبذة', 'binding' => '', 'fontSize' => 12, 'fontWeight' => 600, 'color' => $C['muted'], 'align' => 'right', 'maxLines' => 1], [], 'bioCard'),
    'bio'         => $node('Text', false, ['text' => '', 'binding' => 'profile.user.bio', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['bioText'], 'align' => 'right', 'maxLines' => 0], [], 'bioCard'),

    // Country card.
    'countryCard' => $node('Container', true, ['margin' => ['left' => 16, 'top' => 0, 'right' => 16, 'bottom' => 16], 'padding' => 16, 'radius' => 16, 'background' => $C['card'], 'borderWidth' => 1, 'borderColor' => $C['cardBd'], 'align' => 'stretch', 'flex' => 0, 'visibleBinding' => 'profile.user.country'], ['countryRow'], 'scope'),
    'countryRow'  => $node('Row', true, ['gap' => 10, 'justify' => 'start', 'align' => 'center'], ['cFlag', 'cName'], 'countryCard'),
    'cFlag'       => $node('Image', false, ['src' => '', 'binding' => 'profile.user.flag', 'visibleBinding' => 'profile.user.flag', 'width' => 28, 'height' => 20, 'fit' => 'cover', 'radius' => 3], [], 'countryRow'),
    'cName'       => $node('Text', false, ['text' => '', 'binding' => 'profile.user.country', 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['white'], 'align' => 'right', 'maxLines' => 1], [], 'countryRow'),
];

return [
    'key'     => 'profile',
    'name'    => 'Profile',
    'icon'    => 'person',
    'screens' => ['user_profile'],

    'elements' => [
        ['key' => 'name',    'label' => 'الاسم',    'type' => 'string',    'screen' => 'user_profile'],
        ['key' => 'bio',     'label' => 'نبذة',     'type' => 'string',    'screen' => 'user_profile'],
        ['key' => 'avatar',  'label' => 'الصورة',   'type' => 'image_url', 'screen' => 'user_profile'],
        ['key' => 'cover',   'label' => 'الغلاف',     'type' => 'image_url', 'screen' => 'user_profile'],
        ['key' => 'country', 'label' => 'الدولة',     'type' => 'string',    'screen' => 'user_profile'],
        ['key' => 'flag',    'label' => 'علم الدولة', 'type' => 'image_url', 'screen' => 'user_profile'],
        ['key' => 'uid',     'label' => 'المعرّف',    'type' => 'string',    'screen' => 'user_profile'],
    ],

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
        [
            'key' => 'open_edit', 'label' => 'تعديل الملف',
            'produces' => 'core.navigate', 'default_shape' => 'button', 'screen' => 'user_profile',
            'params' => [
                ['key' => 'route', 'label' => 'الشاشة', 'type' => 'route'],
                ['key' => 'mode',  'label' => 'النمط (go/push/replace)', 'type' => 'string'],
            ],
        ],
    ],

    'default_screens' => [
        [
            'name'         => 'user_profile',
            'label'        => 'الملف الشخصي',
            'icon'         => '👤',
            'version'      => '1.7.0',
            'nav'          => false,
            'navIcon'      => 'person',
            'order'        => 31,
            'role'         => 'auth.profile',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'الملف الشخصي', 'bg' => '#00000000', 'actions' => []]],
            'widgets'      => $profileWidgets,
        ],
    ],
];
