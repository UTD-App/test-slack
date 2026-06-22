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

// ── Lumia palette (EXACT app colors, from ColorManager) ─────────────────────
// This screen opens as a full dialog from the avatar tap, so it paints its own
// background — the SAME purple gradient the native profile uses (lumiaBgGradient
// #7E3E97 → #3D2D86) so it matches the old look precisely.
$C = [
    'gradTop' => '#7E3E97', // lumiaBgGradient top
    'gradBot' => '#3D2D86', // lumiaBgGradient bottom
    'white'   => '#FFFFFF',
    'muted'   => '#D0C0EE', // lumiaTextSecondary
    'bioText' => '#E3D8FB',
    'accent'  => '#BE4AFF', // lumiaAccent
    'pink'    => '#EC4899',
    'card'    => '#6750AE', // lumiaCardBg
    'cardBd'  => '#8E72D2', // lumiaCardBorder
];

// user_profile — MIRRORS the base `profile` screen (the clean look the owner
// confirmed they want): gradient-ring avatar + camera badge, name/flag/gender/
// edit-pencil, UID + copy, bio + pencil. NO cover banner — the cover was the
// single source of every render bug (the Studio transform DROPS a Stack's
// fit:expand → the bound cover image rendered at intrinsic size → 744px overflow
// + the empty-cover placeholder + white bg). Bound to `profile.user` under a
// Scope (utdObject renders ONE child, so everything lives under `header`).
//
// Opened as a full dialog via _FullStudioPage (Positioned.fill = TIGHT
// full-screen), so the ROOT paints its OWN purple gradient (no AppShell behind
// it). _FullStudioPage already overlays a top-right back button, so the screen
// needs none of its own.
$profileWidgets = [
    'ROOT'        => $node('Container', true, ['background' => $C['gradBot'], 'gradient' => 1, 'gradFrom' => $C['gradTop'], 'gradTo' => $C['gradBot'], 'gradDir' => 'to bottom', 'padding' => 16, 'gap' => 14, 'align' => 'stretch', 'flex' => 0], ['scope'], null),
    'scope'       => $node('Scope', true, ['source' => 'profile.user'], ['header'], 'ROOT'),
    'header'      => $node('Container', true, ['background' => '#00000000', 'padding' => 8, 'gap' => 10, 'align' => 'center', 'flex' => 0], ['avatarBox', 'nameRow', 'uidRow', 'bioRow'], 'scope'),

    // Avatar: a FIXED-SIZE 124×124 box → gradient ring + circular image + camera
    // badge. The Stack MUST be wrapped in the fixed box (the Stac stack parser
    // ignores Stack w/h), so the badge's pos sits ON the ring edge instead of
    // flinging to the screen corner.
    'avatarBox'   => $node('Container', true, ['width' => 124, 'height' => 124, 'align' => 'center', 'valign' => 'center', 'flex' => 0], ['avatarStack'], 'header'),
    'avatarStack' => $node('Stack', true, [], ['ring', 'camBtn'], 'avatarBox'),
    'ring'        => $node('Container', true, ['width' => 124, 'height' => 124, 'radius' => 62, 'gradient' => 1, 'gradFrom' => $C['accent'], 'gradTo' => $C['pink'], 'gradDir' => 'to bottom right', 'padding' => 4, 'align' => 'center', 'valign' => 'center', 'flex' => 0], ['avatarImg'], 'avatarStack'),
    'avatarImg'   => $node('Image', false, ['src' => '', 'binding' => 'profile.user.avatar', 'width' => 116, 'height' => 116, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0], [], 'ring'),
    // pos:'top-left' → physical top-RIGHT (RTL), snug on the ring — same as base.
    'camBtn'      => $node('Container', true, ['width' => 34, 'height' => 34, 'radius' => 17, 'background' => $C['pink'], 'borderWidth' => 2, 'borderColor' => $C['white'], 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'pos' => 'top-left', 'onTapAction' => 'core.changeAvatar', 'onTapParams' => ['source' => 'gallery']], ['camIcon'], 'avatarStack'),
    'camIcon'     => $node('Icon', false, ['name' => 'photo_camera', 'size' => 16, 'color' => $C['white']], [], 'camBtn'),

    // Name + flag + gender sign + edit pencil.
    'nameRow'     => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['name', 'flag', 'maleSign', 'femaleSign', 'namePencil'], 'header'),
    'name'        => $node('Text', false, ['text' => 'الاسم', 'binding' => 'profile.user.name', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'flag'        => $node('Image', false, ['src' => '', 'binding' => 'profile.user.flag', 'visibleBinding' => 'profile.user.flag', 'width' => 26, 'height' => 18, 'fit' => 'cover', 'radius' => 3], [], 'nameRow'),
    // Gender sign: the symbol for the matching gender, '' otherwise (Studio drops
    // visibleBinding, so an empty bound Text is how the other one stays hidden).
    'maleSign'    => $node('Text', false, ['text' => '', 'binding' => 'profile.user.maleSign', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#42A5F5', 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'femaleSign'  => $node('Text', false, ['text' => '', 'binding' => 'profile.user.femaleSign', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#EC407A', 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'namePencil'  => $node('Icon', false, ['name' => 'edit', 'size' => 16, 'color' => $C['accent'], 'onTapAction' => 'core.editProfile'], [], 'nameRow'),

    // UID + copy glyph.
    'uidRow'      => $node('Row', true, ['gap' => 4, 'justify' => 'center', 'align' => 'center', 'visibleBinding' => 'profile.user.uid'], ['uidLabel', 'uid', 'copyIcon'], 'header'),
    'uidLabel'    => $node('Text', false, ['text' => 'الأبدي:', 'binding' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'uidRow'),
    'uid'         => $node('Text', false, ['text' => '', 'binding' => 'profile.user.uid', 'fontSize' => 13, 'fontWeight' => 600, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'uidRow'),
    'copyIcon'    => $node('Icon', false, ['name' => 'content_copy', 'size' => 14, 'color' => $C['muted']], [], 'uidRow'),

    // Bio + edit pencil.
    'bioRow'      => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['bio', 'bioPencil'], 'header'),
    'bio'         => $node('Text', false, ['text' => '', 'binding' => 'profile.user.bio', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['bioText'], 'align' => 'center', 'maxLines' => 0], [], 'bioRow'),
    'bioPencil'   => $node('Icon', false, ['name' => 'edit', 'size' => 14, 'color' => $C['accent'], 'onTapAction' => 'core.editProfile'], [], 'bioRow'),
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
                ['key' => 'isMale',   'label' => 'ذكر؟',  'type' => 'string'],
                ['key' => 'isFemale', 'label' => 'أنثى؟', 'type' => 'string'],
                ['key' => 'maleSign',   'label' => 'رمز ذكر',  'type' => 'string'],
                ['key' => 'femaleSign', 'label' => 'رمز أنثى', 'type' => 'string'],
            ],
        ],
    ],

    'action_elements' => [
        [
            'key' => 'edit_profile', 'label' => 'تعديل الملف (مودال)',
            'produces' => 'core.editProfile', 'default_shape' => 'button', 'screen' => 'user_profile',
        ],
        [
            'key' => 'refresh', 'label' => 'تحديث',
            'produces' => 'core.refresh', 'default_shape' => 'button', 'screen' => 'user_profile',
        ],
        [
            'key' => 'close_dialog', 'label' => 'إغلاق',
            'produces' => 'core.closeDialog', 'default_shape' => 'button', 'screen' => 'user_profile',
        ],
        [
            'key' => 'change_avatar', 'label' => 'تغيير الصورة',
            'produces' => 'core.changeAvatar', 'default_shape' => 'image', 'screen' => 'user_profile',
        ],
    ],

    'default_screens' => [
        [
            'name'         => 'user_profile',
            'label'        => 'البروفايل الكامل (عند الصورة)',
            'icon'         => '👤',
            'version'      => '1.11.0',
            'nav'          => false,
            'navIcon'      => 'person',
            'order'        => 31,
            'role'         => 'auth.profile',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            // Opened as a FULL dialog from the base profile's avatar tap
            // (core.openDialog → style:full). It MUST be type:'dialog' — otherwise
            // the runtime wraps it in a full scaffold INSIDE the window (the broken
            // "scaffold-in-a-window" look). The dialog has no appBar; the screen
            // owns its close button (closeBtn → core.closeDialog) + its own bg.
            // Opened as a FULL dialog from the base profile's avatar tap
            // (core.openDialog → style:full). NOTE: the Flutter runtime ignores
            // chrome.type and keys off presentation.style only; full → pushed as a
            // route via _FullStudioPage (white ColoredBox behind), so the ROOT owns
            // its purple fill. appBar.bg set to solid purple as a scaffold-bg
            // safety net. The screen owns its close button (closeBtn → core.closeDialog).
            'chrome'       => [
                'type'         => 'dialog',
                'presentation' => ['style' => 'full', 'barrierDismissible' => true],
                'appBar'       => ['enabled' => false, 'title' => 'الملف الشخصي', 'bg' => $C['gradBot'], 'actions' => []],
            ],
            'widgets'      => $profileWidgets,
        ],
    ],
];
