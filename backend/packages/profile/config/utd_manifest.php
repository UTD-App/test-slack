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

// user_profile — RICH profile bound to profile.user (primitives only): cover
// banner + gradient-ring avatar + name/flag + UID + bio card + country card,
// with a close button (core.closeDialog) since it's presented as a dialog.
// A starting layout the owner refines in UTD Studio (counters/cards need the
// social/gifts package bindings, added later).
// IMPORTANT: a Scope (utdObject) renders only ONE child, so ALL bound content
// must live under a SINGLE wrapper container (`body`) — the same shape the base
// `profile` screen uses (scope → header → …). Putting multiple nodes directly
// under the scope makes only the FIRST one render (the close button), leaving
// the rest of the screen blank.
// IMPORTANT: a Scope (utdObject) renders only ONE child, so ALL bound content
// lives under a SINGLE wrapper container (`body`). The ROOT paints the app's
// exact purple gradient; the cover is full-bleed and the avatar OVERLAPS it via
// a negative top margin on `header` (EdgeInsets supports negatives) — matching
// the native profile look.
$profileWidgets = [
    // Opened as a full dialog via _FullStudioPage, which gives this ROOT a
    // Positioned.fill (TIGHT full-screen constraints) — so a plain gradient
    // Container fills the whole screen on its own (no heightPercent needed; that
    // utdSized wrapper mis-sized it). SOLID bg under the gradient as a fallback.
    'ROOT'        => $node('Container', true, ['background' => $C['gradBot'], 'gradient' => 1, 'gradFrom' => $C['gradTop'], 'gradTo' => $C['gradBot'], 'gradDir' => 'to bottom', 'padding' => 0, 'gap' => 0, 'align' => 'stretch', 'flex' => 0], ['scope'], null),
    'scope'       => $node('Scope', true, ['source' => 'profile.user'], ['body'], 'ROOT'),
    'body'        => $node('Container', true, ['background' => '#00000000', 'padding' => 0, 'gap' => 0, 'align' => 'stretch', 'flex' => 0], ['coverWrap', 'header'], 'scope'),

    // Cover banner (full-bleed) with edit + refresh buttons OVER it. The Stack
    // uses fit:expand so the cover image fills it; the tools are a pos'd child.
    // coverWrap has its own bg so the banner shows even when the user has no cover.
    // widthPercent:100 gives the cover a DEFINITE width so the fit:expand Stack
    // bounds the image (width:0/auto let the bound cover render at its intrinsic
    // size → the 730px bottom overflow). Single non-positioned child (the image);
    // the scrim was dropped — a 2nd non-positioned child in a fit:expand Stack is
    // unreliable in the Studio transform.
    'coverWrap'   => $node('Container', true, ['widthPercent' => 100, 'height' => 170, 'background' => $C['card'], 'align' => 'stretch', 'flex' => 0], ['coverStack'], 'body'),
    'coverStack'  => $node('Stack', true, ['fit' => 'expand'], ['coverImg', 'tools', 'closeBtn'], 'coverWrap'),
    // EXPLICIT height (+ widthPercent) — the Studio transform DROPS the Stack's
    // fit:expand, so without a bound height the bound cover image renders at its
    // intrinsic size (~900px) and overflows the 170 box by ~744px (verified in the
    // served /api/stac/user_profile JSON). The explicit height caps it.
    'coverImg'    => $node('Image', false, ['src' => '', 'binding' => 'profile.user.cover', 'fit' => 'cover', 'radius' => 0, 'height' => 170, 'widthPercent' => 100], [], 'coverStack'),

    // Close button — this screen opens as a FULL dialog from the base avatar tap
    // (core.openDialog → style:full), so it owns its own close affordance.
    // pos:'top-left' → physical top-RIGHT in the RTL app (matches the native back chevron).
    'closeBtn'    => $node('Container', true, ['width' => 40, 'height' => 40, 'radius' => 20, 'background' => '#00000066', 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'pos' => 'top-left', 'onTapAction' => 'core.closeDialog'], ['closeIcon'], 'coverStack'),
    'closeIcon'   => $node('Icon', false, ['name' => 'arrow_back_ios_new', 'size' => 18, 'color' => $C['white']], [], 'closeBtn'),

    // Edit + refresh, pos:'top-right' → physical top-LEFT in the RTL app.
    'tools'       => $node('Row', true, ['gap' => 8, 'pos' => 'top-right', 'padding' => 10], ['editBtn', 'refreshBtn'], 'coverStack'),
    'editBtn'     => $node('Container', true, ['width' => 40, 'height' => 40, 'radius' => 20, 'background' => '#00000066', 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'onTapAction' => 'core.editProfile'], ['editIcon'], 'tools'),
    'editIcon'    => $node('Icon', false, ['name' => 'edit', 'size' => 20, 'color' => $C['white']], [], 'editBtn'),
    'refreshBtn'  => $node('Container', true, ['width' => 40, 'height' => 40, 'radius' => 20, 'background' => '#00000066', 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'onTapAction' => 'core.refresh'], ['refreshIcon'], 'tools'),
    'refreshIcon' => $node('Icon', false, ['name' => 'refresh', 'size' => 20, 'color' => $C['white']], [], 'refreshBtn'),

    // Identity: gradient-ring avatar OVERLAPPING the cover (negative top margin)
    // + flag + gender icon + name + UID row ("الأبدي: <id>").
    'header'      => $node('Container', true, ['background' => '#00000000', 'margin' => ['left' => 16, 'top' => -60, 'right' => 16, 'bottom' => 16], 'padding' => 0, 'gap' => 8, 'align' => 'center', 'flex' => 0], ['avatarRing', 'nameRow', 'uidRow'], 'body'),
    'avatarRing'  => $node('Container', true, ['width' => 116, 'height' => 116, 'radius' => 58, 'gradient' => 1, 'gradFrom' => $C['accent'], 'gradTo' => $C['pink'], 'gradDir' => 'to bottom right', 'padding' => 4, 'align' => 'center', 'valign' => 'center', 'flex' => 0], ['avatarImg'], 'header'),
    'avatarImg'   => $node('Image', false, ['src' => '', 'binding' => 'profile.user.avatar', 'width' => 108, 'height' => 108, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0], [], 'avatarRing'),
    'nameRow'     => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['flag', 'maleSign', 'femaleSign', 'name'], 'header'),
    'flag'        => $node('Image', false, ['src' => '', 'binding' => 'profile.user.flag', 'visibleBinding' => 'profile.user.flag', 'width' => 26, 'height' => 18, 'fit' => 'cover', 'radius' => 3], [], 'nameRow'),
    // Gender shown as a colored sign. UTD Studio drops `visibleBinding`, so a gated
    // Icon can't be hidden — instead bind a Text to a per-gender source field that
    // holds the symbol for the matching gender and an EMPTY string otherwise (an
    // empty bound Text renders nothing). So only the user's gender shows, colored.
    'maleSign'    => $node('Text', false, ['text' => '', 'binding' => 'profile.user.maleSign', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#42A5F5', 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'femaleSign'  => $node('Text', false, ['text' => '', 'binding' => 'profile.user.femaleSign', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#EC407A', 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'name'        => $node('Text', false, ['text' => 'الاسم', 'binding' => 'profile.user.name', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'uidRow'      => $node('Row', true, ['gap' => 4, 'justify' => 'center', 'align' => 'center', 'visibleBinding' => 'profile.user.uid'], ['uidLabel', 'uid', 'copyIcon'], 'header'),
    'uidLabel'    => $node('Text', false, ['text' => 'الأبدي:', 'binding' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'uidRow'),
    'uid'         => $node('Text', false, ['text' => '', 'binding' => 'profile.user.uid', 'fontSize' => 13, 'fontWeight' => 600, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'uidRow'),
    // Decorative copy glyph (matches the native profile). NOTE: there is no
    // core.copy clipboard action in the SDUI runtime yet, so this is visual-only
    // until a copy action parser is registered in the base.
    'copyIcon'    => $node('Icon', false, ['name' => 'content_copy', 'size' => 14, 'color' => $C['muted']], [], 'uidRow'),
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
    ],

    'default_screens' => [
        [
            'name'         => 'user_profile',
            'label'        => 'البروفايل الكامل (عند الصورة)',
            'icon'         => '👤',
            'version'      => '1.10.0',
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
