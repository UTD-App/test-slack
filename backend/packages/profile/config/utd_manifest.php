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

// user_profile — RICH profile: full-bleed COVER + a gradient-ring avatar whose
// TOP QUARTER overlaps the cover bottom (negative top margin on `header`), then
// name/flag/gender/edit-pencil, UID + copy, bio + pencil. Bound to `profile.user`
// under a Scope (utdObject renders ONE child → everything lives under `body`).
//
// NOT a dialog screen any more: chrome has NO type/presentation, so the Studio
// transform wraps it in scaffold → singleChildScrollView (exactly like the base
// `profile` tab). That gives it (a) a real scroll (no overflow), (b) a
// Directionality/Material context so Text doesn't render with the debug yellow
// underline, and (c) a scaffold backgroundColor (chrome.appBar.bg = purple) so it
// never goes white. It's still OPENED via core.openDialog(style:full) from the
// base avatar → pushed as a route by _FullStudioPage (which adds the back button).
//
// Cover image MUST have an explicit height — the transform DROPS the Stack's
// fit:expand, so a height-less bound image renders at intrinsic size and overflows.
$profileWidgets = [
    'ROOT'        => $node('Container', true, ['background' => $C['gradBot'], 'gradient' => 1, 'gradFrom' => $C['gradTop'], 'gradTo' => $C['gradBot'], 'gradDir' => 'to bottom', 'padding' => 0, 'gap' => 0, 'align' => 'stretch', 'flex' => 0], ['scope'], null),
    'scope'       => $node('Scope', true, ['source' => 'profile.user'], ['body'], 'ROOT'),
    // BODY IS A STACK: cover = base layer; the identity column sits ON TOP with a
    // fixed-height `spacer` that pushes the avatar down so only its TOP QUARTER
    // overlaps the cover bottom. (Negative margin can't do the overlap — Flutter's
    // Container asserts margin.isNonNegative and CRASHES. A Stack doesn't clip, so
    // the column's avatar/name/uid/bio paint over + below the cover.)
    'body'        => $node('Stack', true, ['fit' => 'expand'], ['coverImgBox', 'content', 'tools'], 'scope'),

    // Cover (base, top-left, full width). FIXED height; the image is stretched to
    // full width by its OWN column (align:'stretch') — a Stack won't stretch it.
    'coverImgBox' => $node('Container', true, ['widthPercent' => 100, 'height' => 180, 'background' => $C['card'], 'align' => 'stretch', 'flex' => 0], ['coverImg'], 'body'),
    'coverImg'    => $node('Image', false, ['src' => '', 'binding' => 'profile.user.cover', 'fit' => 'cover', 'radius' => 0, 'height' => 180], [], 'coverImgBox'),

    // Edit + refresh over the cover (pos:'top-right' → physical top-LEFT in RTL).
    'tools'       => $node('Row', true, ['gap' => 8, 'pos' => 'top-right', 'padding' => 10], ['editBtn', 'refreshBtn'], 'body'),
    'editBtn'     => $node('Container', true, ['width' => 40, 'height' => 40, 'radius' => 20, 'background' => '#00000066', 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'onTapAction' => 'core.editProfile'], ['editIcon'], 'tools'),
    'editIcon'    => $node('Icon', false, ['name' => 'edit', 'size' => 20, 'color' => $C['white']], [], 'editBtn'),
    'refreshBtn'  => $node('Container', true, ['width' => 40, 'height' => 40, 'radius' => 20, 'background' => '#00000066', 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'onTapAction' => 'core.refresh'], ['refreshIcon'], 'tools'),
    'refreshIcon' => $node('Icon', false, ['name' => 'refresh', 'size' => 20, 'color' => $C['white']], [], 'refreshBtn'),

    // Identity column ON TOP of the cover. `spacer` = cover 180 − overlap 31 = 149,
    // so the avatar starts 149px down → its top quarter (31px) overlaps the cover.
    'content'     => $node('Container', true, ['background' => '#00000000', 'widthPercent' => 100, 'padMode' => 'sides', 'padL' => 16, 'padT' => 0, 'padR' => 16, 'padB' => 16, 'gap' => 10, 'align' => 'center', 'flex' => 0], ['spacer', 'avatarBox', 'nameRow', 'uidRow', 'bioRow'], 'body'),
    'spacer'      => $node('Container', true, ['height' => 149, 'background' => '#00000000', 'flex' => 0], [], 'content'),

    // Avatar: a FIXED-SIZE 124×124 box → gradient ring + circular image + camera
    // badge. The Stack MUST be wrapped in the fixed box (the Stac stack parser
    // ignores Stack w/h), so the badge's pos sits ON the ring edge instead of
    // flinging to the screen corner.
    'avatarBox'   => $node('Container', true, ['width' => 124, 'height' => 124, 'align' => 'center', 'valign' => 'center', 'flex' => 0], ['avatarStack'], 'content'),
    'avatarStack' => $node('Stack', true, [], ['ring', 'camBtn'], 'avatarBox'),
    'ring'        => $node('Container', true, ['width' => 124, 'height' => 124, 'radius' => 62, 'gradient' => 1, 'gradFrom' => $C['accent'], 'gradTo' => $C['pink'], 'gradDir' => 'to bottom right', 'padding' => 4, 'align' => 'center', 'valign' => 'center', 'flex' => 0], ['avatarImg'], 'avatarStack'),
    'avatarImg'   => $node('Image', false, ['src' => '', 'binding' => 'profile.user.avatar', 'width' => 116, 'height' => 116, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0], [], 'ring'),
    // Camera badge on the avatar's BOTTOM-RIGHT corner (matches the target).
    'camBtn'      => $node('Container', true, ['width' => 34, 'height' => 34, 'radius' => 17, 'background' => $C['pink'], 'borderWidth' => 2, 'borderColor' => $C['white'], 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'pos' => 'bottom-right', 'onTapAction' => 'core.changeAvatar', 'onTapParams' => ['source' => 'gallery']], ['camIcon'], 'avatarStack'),
    'camIcon'     => $node('Icon', false, ['name' => 'photo_camera', 'size' => 16, 'color' => $C['white']], [], 'camBtn'),

    // Name + flag + gender sign + edit pencil.
    'nameRow'     => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['name', 'flag', 'maleSign', 'femaleSign', 'namePencil'], 'content'),
    'name'        => $node('Text', false, ['text' => 'الاسم', 'binding' => 'profile.user.name', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'flag'        => $node('Image', false, ['src' => '', 'binding' => 'profile.user.flag', 'visibleBinding' => 'profile.user.flag', 'width' => 26, 'height' => 18, 'fit' => 'cover', 'radius' => 3], [], 'nameRow'),
    // Gender sign: the symbol for the matching gender, '' otherwise (Studio drops
    // visibleBinding, so an empty bound Text is how the other one stays hidden).
    'maleSign'    => $node('Text', false, ['text' => '', 'binding' => 'profile.user.maleSign', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#42A5F5', 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'femaleSign'  => $node('Text', false, ['text' => '', 'binding' => 'profile.user.femaleSign', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#EC407A', 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
    'namePencil'  => $node('Icon', false, ['name' => 'edit', 'size' => 16, 'color' => $C['accent'], 'onTapAction' => 'core.editProfile'], [], 'nameRow'),

    // UID + copy glyph.
    'uidRow'      => $node('Row', true, ['gap' => 4, 'justify' => 'center', 'align' => 'center', 'visibleBinding' => 'profile.user.uid'], ['uidLabel', 'uid', 'copyIcon'], 'content'),
    'uidLabel'    => $node('Text', false, ['text' => 'الأبدي:', 'binding' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'uidRow'),
    'uid'         => $node('Text', false, ['text' => '', 'binding' => 'profile.user.uid', 'fontSize' => 13, 'fontWeight' => 600, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'uidRow'),
    'copyIcon'    => $node('Icon', false, ['name' => 'content_copy', 'size' => 14, 'color' => $C['muted']], [], 'uidRow'),

    // Bio + edit pencil.
    'bioRow'      => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['bio', 'bioPencil'], 'content'),
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
            'version'      => '1.14.0',
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
            // NOT a dialog screen: no chrome.type/presentation, so the transform
            // wraps it in scaffold → singleChildScrollView (like the base profile
            // tab) → real scroll + Directionality (no debug underlines) + a scaffold
            // backgroundColor. appBar.bg = solid purple is that scaffold bg (so it
            // never goes white). Still opened via core.openDialog(style:full) from
            // the base avatar — pushed as a route by _FullStudioPage (adds the back).
            'chrome'       => [
                'appBar' => ['enabled' => false, 'title' => 'الملف الشخصي', 'bg' => $C['gradBot'], 'actions' => []],
            ],
            'widgets'      => $profileWidgets,
        ],
    ],
];
