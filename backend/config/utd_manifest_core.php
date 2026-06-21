<?php

/**
 * UTD Studio manifest for the CORE app screens (auth / profile / settings).
 *
 * This is the base project's own design-time contract — the screens that ship
 * inside the base app (Intro, Login, Forgot password, Register, Profile,
 * Settings) exposed as server-driven Stac screens editable from UTD Studio,
 * exactly like the Chat package.
 *
 * UTD Studio discovers this via GET /api/utd/manifest. It stays generic: the
 * editor reads `elements` (data bindings), `screens` (data sources) and
 * `action_elements` (available actions) straight from here.
 *
 * Element keys map 1:1 to what the Flutter `core.currentUser` object source
 * exposes (see flutter/lib/shared/stac/core_stac_sources.dart).
 *
 * DESIGN: these trees mirror the REAL native screens as closely as the Stac
 * primitives allow. Native theme = "Lumia" dark purple / pink-accent.
 *
 * SCREEN BACKGROUND: home/profile/settings render INSIDE the AppShell (a
 * deep-purple Scaffold), so their ROOT is TRANSPARENT — the purple shell fills
 * the whole screen uniformly. Only `login` (pre-auth, outside the shell) carries
 * a solid purple background.
 *
 * PROFILE is built as a "Me hub": a centered identity header (avatar/name/flag/
 * uid/bio bound to the live user) + a pink Edit CTA + a list of tappable menu
 * cards — so the screen stays full and intentional even when the user's profile
 * fields are empty (cards are static). Gradients/level-badges are bespoke
 * Flutter flourishes primitives can't express.
 */

// ── Craft node helper (mirrors the Studio design scripts) ──────────────
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

$style = [
    'radius' => 0, 'borderWidth' => 0, 'borderColor' => '#e5e7eb', 'shadow' => 'none',
    'gradient' => 0, 'gradFrom' => '#2563eb', 'gradTo' => '#7c3aed', 'gradDir' => 'to bottom',
    'onTapAction' => 'none', 'onTapTarget' => '', 'onTapParams' => [],
];

// ── Lumia palette (solid approximations of the native gradient theme) ──────
$C = [
    'screen'     => '#00000000', // transparent → inherit the AppShell's purple Scaffold (tabs)
    'login'      => '#3A2A7E',   // solid deep purple for the pre-auth login
    'card'       => '#5B4399',   // card surface (≈ lumiaCardGradient)
    'cardBorder' => '#8E72D2',   // lumiaCardBorder
    'accent'     => '#BE4AFF',   // lumiaAccent
    'accentLt'   => '#D9A0FF',   // lumiaAccentLight (links / icons)
    'pink'       => '#EC4899',    // pinkCtaGradient (primary CTA)
    'red'        => '#FF5A6E',    // destructive (logout / delete)
    'white'      => '#FFFFFF',
    'muted'      => '#CDBFEE',    // lumiaTextSecondary
    'bioText'    => '#E3D8FB',
    'field'      => '#ECE7FB',    // light input fill → default dark field text stays legible
];

// Reusable tappable menu card (tinted icon + label + chevron), parented to ROOT.
$mkTile = function (string $id, string $icon, string $tint, string $label, string $tapAction, array $tapParams) use ($node, $style, $C): array {
    return [
        $id         => $node('Container', true, array_merge($style, ['background' => $C['card'], 'radius' => 14, 'padding' => 14, 'borderWidth' => 1, 'borderColor' => $C['cardBorder'], 'gap' => 0, 'align' => 'stretch', 'onTapAction' => $tapAction, 'onTapParams' => $tapParams]), [$id . 'Row'], 'ROOT'),
        $id . 'Row' => $node('Row', true, ['gap' => 12, 'align' => 'center'], [$id . 'Ic', $id . 'Lb', $id . 'Ch'], $id),
        $id . 'Ic'  => $node('Icon', false, ['name' => $icon, 'size' => 20, 'color' => $tint], [], $id . 'Row'),
        $id . 'Lb'  => $node('Text', false, ['text' => $label, 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['white'], 'align' => 'right', 'binding' => '', 'maxLines' => 1, 'flex' => 1], [], $id . 'Row'),
        $id . 'Ch'  => $node('Icon', false, ['name' => 'chevron_left', 'size' => 18, 'color' => $C['muted']], [], $id . 'Row'),
    ];
};

// login — solid deep-purple screen (pre-auth, outside the AppShell).
$loginWidgets = [
    'ROOT'    => $node('Container', true, array_merge($style, ['background' => $C['login'], 'padding' => 22, 'gap' => 16, 'align' => 'stretch', 'flex' => 0]), ['t1', 't2', 'fEmail', 'fPass', 'recover', 'btn', 'regRow'], null),
    't1'      => $node('Text', false, ['text' => 'أهلاً بك 👋', 'fontSize' => 28, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
    't2'      => $node('Text', false, ['text' => 'سجّل دخولك للمتابعة', 'fontSize' => 15, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
    'fEmail'  => $node('TextField', false, ['fieldId' => 'email', 'placeholder' => 'البريد الإلكتروني', 'live' => true, 'keyboard' => 'email', 'fillColor' => $C['field'], 'radius' => 16, 'flex' => 0], [], 'ROOT'),
    'fPass'   => $node('TextField', false, ['fieldId' => 'password', 'placeholder' => 'كلمة المرور', 'live' => true, 'obscure' => true, 'fillColor' => $C['field'], 'radius' => 16, 'flex' => 0], [], 'ROOT'),
    'recover' => $node('Button', false, array_merge($style, ['label' => 'نسيت كلمة المرور؟', 'background' => '#00000000', 'color' => $C['accentLt'], 'radius' => 0, 'flex' => 0, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/forgot_password', 'mode' => 'push']]), [], 'ROOT'),
    'btn'     => $node('Button', false, array_merge($style, ['label' => 'دخول', 'background' => $C['pink'], 'color' => $C['white'], 'radius' => 28, 'flex' => 0, 'onTapAction' => 'core.login', 'onTapParams' => ['emailField' => 'email', 'passwordField' => 'password', 'successRoute' => '/']]), [], 'ROOT'),
    'regRow'  => $node('Row', true, ['gap' => 6, 'align' => 'center'], ['regText', 'regBtn'], 'ROOT'),
    'regText' => $node('Text', false, ['text' => 'ليس لديك حساب؟', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => '', 'maxLines' => 0], [], 'regRow'),
    'regBtn'  => $node('Button', false, array_merge($style, ['label' => 'سجّل الآن', 'background' => '#00000000', 'color' => $C['accentLt'], 'radius' => 0, 'flex' => 0, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/register', 'mode' => 'push']]), [], 'regRow'),
];

// home — title row + search + welcome card. Transparent ROOT.
$homeWidgets = [
    'ROOT'      => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 16, 'gap' => 16, 'align' => 'stretch', 'flex' => 0]), ['topRow', 'search', 'card'], null),
    'topRow'    => $node('Row', true, ['gap' => 8, 'align' => 'center'], ['appName', 'bell'], 'ROOT'),
    'appName'   => $node('Text', false, ['text' => 'الرئيسية', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'right', 'binding' => '', 'maxLines' => 1, 'flex' => 1], [], 'topRow'),
    'bell'      => $node('Icon', false, ['name' => 'notifications_none', 'size' => 24, 'color' => $C['white'], 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/notifications', 'mode' => 'push']], [], 'topRow'),
    'search'    => $node('TextField', false, ['fieldId' => 'home_search', 'placeholder' => 'بحث', 'live' => false, 'fillColor' => $C['field'], 'radius' => 16, 'flex' => 0], [], 'ROOT'),
    'card'      => $node('Container', true, array_merge($style, ['background' => $C['card'], 'radius' => 16, 'padding' => 22, 'borderWidth' => 1, 'borderColor' => $C['cardBorder'], 'gap' => 10, 'align' => 'center']), ['cardIcon', 'cardTitle', 'cardSub'], 'ROOT'),
    'cardIcon'  => $node('Icon', false, ['name' => 'auto_awesome', 'size' => 30, 'color' => $C['accentLt']], [], 'card'),
    'cardTitle' => $node('Text', false, ['text' => 'أهلاً بك في تطبيقك', 'fontSize' => 16, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => '', 'maxLines' => 0], [], 'card'),
    'cardSub'   => $node('Text', false, ['text' => 'ابدأ استكشاف كل المميزات', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => '', 'maxLines' => 0], [], 'card'),
];

// profile — the rich self-profile is a CUSTOM NATIVE widget (`core.selfProfile`,
// rendered by SelfProfileCardParser) that UTD Studio places on the screen.
// Primitives can't express the gradient avatar ring / camera badge / gender +
// level badges / feature grid, so this one node renders natively for a
// pixel-match with the standalone app — while the SCREEN stays server-driven
// (Studio owns the composition: it can add a header/sections around the card,
// hide it, or swap it). Declared in the `widgets` block below.
$profileWidgets = [
    'ROOT' => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 0, 'gap' => 0, 'align' => 'stretch', 'flex' => 0]), ['card'], null),
    'card' => $node('core.selfProfile', false, [], [], 'ROOT'),
];

// settings — in-body title + tappable purple cards + destructive logout.
$settingsWidgets = array_merge(
    [
        'ROOT'   => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 16, 'gap' => 12, 'align' => 'stretch', 'flex' => 0]), ['sTitle', 'tLang', 'tPrivacy', 'tTerms', 'tContact', 'tAbout', 'tAccount', 'btnLogout'], null),
        'sTitle' => $node('Text', false, ['text' => 'الإعدادات', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'right', 'binding' => '', 'maxLines' => 1], [], 'ROOT'),
    ],
    $mkTile('tLang', 'language', '#26C6DA', 'اللغة', 'core.setLocale', ['code' => 'ar']),
    $mkTile('tPrivacy', 'privacy_tip', '#66BB6A', 'سياسة الخصوصية', 'core.navigate', ['route' => '/page/privacy', 'mode' => 'push']),
    $mkTile('tTerms', 'description', '#26A69A', 'شروط الاستخدام', 'core.navigate', ['route' => '/page/terms', 'mode' => 'push']),
    $mkTile('tContact', 'support_agent', '#42A5F5', 'تواصل معنا', 'core.navigate', ['route' => '/contact-us', 'mode' => 'push']),
    $mkTile('tAbout', 'info', '#7C4DFF', 'عن التطبيق', 'core.navigate', ['route' => '/page/about', 'mode' => 'push']),
    $mkTile('tAccount', 'person', '#5C6BC0', 'الحساب', 'core.navigate', ['route' => '/profile', 'mode' => 'push']),
    [
        'btnLogout' => $node('Button', false, array_merge($style, ['label' => 'تسجيل الخروج', 'background' => $C['card'], 'color' => $C['red'], 'radius' => 14, 'flex' => 0, 'onTapAction' => 'core.logout', 'onTapParams' => ['confirm' => true]]), [], 'ROOT'),
    ]
);

// audio — bottom-nav tab placeholder for the audio-room feature (Eng-Hazem is
// building the real package). Marked nav=true so the tab shows in the shell; the
// screen is a themed "coming soon" until the audio-room package ships its own
// nav screen, at which point this can be removed.
$audioWidgets = [
    'ROOT'   => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 24, 'gap' => 12, 'align' => 'center', 'flex' => 0]), ['aIcon', 'aTitle', 'aSub'], null),
    'aIcon'  => $node('Icon', false, ['name' => 'graphic_eq', 'size' => 64, 'color' => $C['accentLt']], [], 'ROOT'),
    'aTitle' => $node('Text', false, ['text' => 'الغرف الصوتية', 'fontSize' => 20, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => '', 'maxLines' => 1], [], 'ROOT'),
    'aSub'   => $node('Text', false, ['text' => 'قريباً 🎧', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
];

return [
    'key'     => 'core',
    'name'    => 'Core',
    'icon'    => 'settings',
    'screens' => ['intro', 'login', 'register', 'forgot_password', 'home', 'audio', 'profile', 'settings'],

    // Display bindings (profile screen ⇄ current user)
    'elements' => [
        ['key' => 'name',    'label' => 'الاسم',         'type' => 'string',    'screen' => 'profile'],
        ['key' => 'email',   'label' => 'البريد',        'type' => 'string',    'screen' => 'profile'],
        ['key' => 'bio',     'label' => 'نبذة',          'type' => 'string',    'screen' => 'profile'],
        ['key' => 'avatar',  'label' => 'الصورة',        'type' => 'image_url', 'screen' => 'profile'],
        ['key' => 'cover',   'label' => 'الغلاف',        'type' => 'image_url', 'screen' => 'profile'],
        ['key' => 'country', 'label' => 'الدولة',        'type' => 'string',    'screen' => 'profile'],
        ['key' => 'flag',    'label' => 'علم الدولة',    'type' => 'image_url', 'screen' => 'profile'],
        ['key' => 'uid',     'label' => 'المعرّف',       'type' => 'string',    'screen' => 'profile'],
    ],

    // Single-object source: the signed-in user. Resolved on the client by
    // `registerCoreStacSources()` (flutter/lib/shared/stac/core_stac_sources.dart).
    'object_sources' => [
        [
            'key'      => 'core.currentUser',
            'label'    => 'المستخدم الحالي',
            'provides' => [
                ['key' => 'name',    'label' => 'الاسم',      'type' => 'string'],
                ['key' => 'email',   'label' => 'البريد',     'type' => 'string'],
                ['key' => 'bio',     'label' => 'نبذة',       'type' => 'string'],
                ['key' => 'avatar',  'label' => 'الصورة',     'type' => 'image_url'],
                ['key' => 'cover',   'label' => 'الغلاف',     'type' => 'image_url'],
                ['key' => 'country', 'label' => 'الدولة',     'type' => 'string'],
                ['key' => 'flag',    'label' => 'علم الدولة', 'type' => 'image_url'],
                ['key' => 'uid',     'label' => 'المعرّف',    'type' => 'string'],
            ],
        ],
    ],

    // Custom package widgets rendered natively by a Flutter StacParser (NOT
    // primitives). UTD Studio shows these in the palette so the designer can
    // drop them on a screen; `type` MUST match the parser's `type` in Flutter.
    'widgets' => [
        [
            'key'        => 'self_profile',
            'type'       => 'core.selfProfile',
            'label'      => 'بطاقة الملف الشخصي (تصميم أصلي)',
            'screen'     => 'profile',
            'provides'   => [],
            'properties' => [],
        ],
    ],

    'action_elements' => [
        // ── login ──
        [
            'key' => 'login_submit', 'label' => 'تسجيل الدخول',
            'produces' => 'core.login', 'default_shape' => 'button', 'screen' => 'login',
            'params' => [
                ['key' => 'emailField',    'label' => 'حقل البريد',       'type' => 'field_ref'],
                ['key' => 'passwordField', 'label' => 'حقل كلمة المرور',  'type' => 'field_ref'],
                ['key' => 'successRoute',  'label' => 'عند النجاح روح لـ', 'type' => 'route'],
            ],
        ],
        ['key' => 'email_input',    'label' => 'إدخال البريد',      'produces' => 'text', 'default_shape' => 'input', 'screen' => 'login'],
        ['key' => 'password_input', 'label' => 'إدخال كلمة المرور', 'produces' => 'text', 'default_shape' => 'input', 'screen' => 'login'],

        // ── register ──
        [
            'key' => 'register_submit', 'label' => 'إنشاء حساب',
            'produces' => 'core.register', 'default_shape' => 'button', 'screen' => 'register',
            'params' => [
                ['key' => 'emailField',    'label' => 'حقل البريد',       'type' => 'field_ref'],
                ['key' => 'passwordField', 'label' => 'حقل كلمة المرور',  'type' => 'field_ref'],
                ['key' => 'successRoute',  'label' => 'عند النجاح روح لـ', 'type' => 'route'],
            ],
        ],

        // ── forgot password ──
        [
            'key' => 'forgot_submit', 'label' => 'استعادة كلمة المرور',
            'produces' => 'core.forgotPassword', 'default_shape' => 'button', 'screen' => 'forgot_password',
            'params' => [
                ['key' => 'emailField', 'label' => 'حقل البريد', 'type' => 'field_ref'],
            ],
        ],

        // ── profile ──
        [
            'key' => 'profile_save', 'label' => 'حفظ الملف الشخصي',
            'produces' => 'core.saveProfile', 'default_shape' => 'button', 'screen' => 'profile',
            'params' => [
                ['key' => 'nameField', 'label' => 'حقل الاسم', 'type' => 'field_ref'],
                ['key' => 'bioField',  'label' => 'حقل النبذة', 'type' => 'field_ref'],
            ],
        ],
        // تغيير صورة الملف الشخصي: العميل بيحطّه كـ onTap على عنصر الصورة.
        [
            'key' => 'change_avatar', 'label' => 'تغيير صورة الملف',
            'produces' => 'core.changeAvatar', 'default_shape' => 'image', 'screen' => 'profile',
            'params' => [
                ['key' => 'source', 'label' => 'المصدر (gallery/camera)', 'type' => 'string'],
            ],
        ],

        // ── settings ──
        [
            'key' => 'logout', 'label' => 'تسجيل الخروج',
            'produces' => 'core.logout', 'default_shape' => 'button', 'screen' => 'settings',
            'params' => [
                ['key' => 'confirm', 'label' => 'تأكيد قبل الخروج', 'type' => 'bool'],
            ],
        ],
        [
            'key' => 'toggle_theme', 'label' => 'الوضع الليلي',
            'produces' => 'core.toggleTheme', 'default_shape' => 'switch', 'screen' => 'settings',
        ],
        [
            'key' => 'set_locale', 'label' => 'تغيير اللغة',
            'produces' => 'core.setLocale', 'default_shape' => 'list', 'screen' => 'settings',
            'params' => [
                ['key' => 'code', 'label' => 'رمز اللغة', 'type' => 'string'],
            ],
        ],

        // ── navigation (any screen) ──
        [
            'key' => 'navigate', 'label' => 'انتقال لشاشة',
            'produces' => 'core.navigate', 'default_shape' => 'button', 'screen' => '*',
            'params' => [
                ['key' => 'route', 'label' => 'الشاشة', 'type' => 'route'],
                ['key' => 'mode',  'label' => 'النمط (go/push/replace)', 'type' => 'string'],
            ],
        ],
    ],

    // ── Ready-to-edit default screen layouts (seeded by UTD Studio on Sync) ──
    'default_screens' => [
        [
            'name'         => 'login',
            'label'        => 'تسجيل الدخول',
            'icon'         => '🔑',
            'version'      => '1.5.0',
            'nav'          => false,
            'navIcon'      => 'person',
            'order'        => 1,
            'role'         => 'auth.login',
            'requiresAuth' => false,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'تسجيل الدخول', 'bg' => $C['login'], 'actions' => []]],
            'widgets'      => $loginWidgets,
        ],
        [
            'name'         => 'home',
            'label'        => 'الرئيسية',
            'icon'         => '🏠',
            'version'      => '1.5.0',
            'nav'          => true,
            'navIcon'      => 'home',
            'order'        => 2,
            'role'         => 'app.home',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'الرئيسية', 'bg' => $C['screen'], 'actions' => []]],
            'widgets'      => $homeWidgets,
        ],
        [
            'name'         => 'audio',
            'label'        => 'الغرف الصوتية',
            'icon'         => '🎧',
            'version'      => '1.5.0',
            'nav'          => true,
            'navIcon'      => 'mic',
            'order'        => 20,
            'role'         => 'app.audio',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'الغرف الصوتية', 'bg' => $C['screen'], 'actions' => []]],
            'widgets'      => $audioWidgets,
        ],
        [
            'name'         => 'profile',
            'label'        => 'الملف الشخصي',
            'icon'         => '👤',
            'version'      => '1.5.0',
            'nav'          => true,
            'navIcon'      => 'person',
            'order'        => 30,
            'role'         => 'auth.profile',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'الملف الشخصي', 'bg' => $C['screen'], 'actions' => []]],
            'widgets'      => $profileWidgets,
        ],
        [
            'name'         => 'settings',
            'label'        => 'الإعدادات',
            'icon'         => '⚙️',
            'version'      => '1.5.0',
            'nav'          => true,
            'navIcon'      => 'settings',
            'order'        => 40,
            'role'         => 'app.settings',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'الإعدادات', 'bg' => $C['screen'], 'actions' => []]],
            'widgets'      => $settingsWidgets,
        ],
    ],
];
