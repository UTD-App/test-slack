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
 * `action_elements` (available actions) straight from here — it has NO
 * hardcoded knowledge of "core". Adding/removing an action = editing THIS file.
 *
 * Element keys map 1:1 to what the Flutter `core.currentUser` object source
 * exposes (see flutter/lib/shared/stac/core_stac_sources.dart).
 *
 * `default_screens` ships ready-to-edit Craft trees (login / home / profile /
 * settings) so UTD Studio seeds a working core app on first Sync.
 *
 * DESIGN: these trees mirror the REAL native screens as closely as the Stac
 * primitives allow, so what UTD Studio shows (and pushes back to the app)
 * matches the app — pulling them in produces no visual change. Native theme =
 * "Lumia" dark purple / pink-accent.
 *
 * SCREEN BACKGROUND: the home/profile/settings tabs render INSIDE the AppShell,
 * whose Scaffold is the deep-purple themed background. So their ROOT containers
 * use a TRANSPARENT background — the purple shell fills the whole screen
 * uniformly (no white/short-container "split", which is what looked broken
 * before). Only `login` (shown pre-auth, OUTSIDE the AppShell on a default
 * Scaffold) carries a SOLID purple background of its own.
 * Gradients/frosted-glass/level-badges are bespoke Flutter flourishes
 * primitives can't express; cards/text use solid Lumia colours.
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
    'login'      => '#3A2A7E',   // solid deep purple for the pre-auth login (no AppShell behind it)
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

// login — solid deep-purple screen (pre-auth, outside the AppShell): title +
// subtitle + email/password + recover link + pink CTA + register link.
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

// home — title row (name + notifications) + search + a welcome card. Transparent
// ROOT → the purple AppShell fills the screen (no white split).
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

// profile — CENTERED identity on the purple AppShell (transparent ROOT): circular
// avatar (tap → change), name + country flag, UID, bio, email, country. Empty
// fields hide via visibleBinding so it degrades cleanly. Native "Me" landing.
$profileWidgets = [
    'ROOT'    => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 20, 'gap' => 12, 'align' => 'center', 'flex' => 0]), ['scope'], null),
    'scope'   => $node('Scope', true, ['source' => 'core.currentUser'], ['avatar', 'nameRow', 'uid', 'bio', 'email', 'country'], 'ROOT'),
    'avatar'  => $node('Image', false, ['src' => '', 'width' => 110, 'height' => 110, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0, 'binding' => 'core.currentUser.avatar', 'onTapAction' => 'core.changeAvatar', 'onTapTarget' => '', 'onTapParams' => ['source' => 'gallery']], [], 'scope'),
    'nameRow' => $node('Row', true, ['gap' => 6, 'align' => 'center'], ['name', 'flag'], 'scope'),
    'name'    => $node('Text', false, ['text' => 'الاسم', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 'core.currentUser.name', 'maxLines' => 1], [], 'nameRow'),
    'flag'    => $node('Image', false, ['src' => '', 'width' => 24, 'height' => 16, 'fit' => 'cover', 'radius' => 3, 'binding' => 'core.currentUser.flag', 'visibleBinding' => 'core.currentUser.flag'], [], 'nameRow'),
    'uid'     => $node('Text', false, ['text' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 'core.currentUser.uid', 'maxLines' => 1], [], 'scope'),
    'bio'     => $node('Text', false, ['text' => '', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['bioText'], 'align' => 'center', 'binding' => 'core.currentUser.bio', 'visibleBinding' => 'core.currentUser.bio', 'maxLines' => 0], [], 'scope'),
    'email'   => $node('Text', false, ['text' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 'core.currentUser.email', 'visibleBinding' => 'core.currentUser.email', 'maxLines' => 1], [], 'scope'),
    'country' => $node('Text', false, ['text' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 'core.currentUser.country', 'visibleBinding' => 'core.currentUser.country', 'maxLines' => 0], [], 'scope'),
];

// settings — in-body title + tappable purple cards (tinted icon + label +
// chevron) over the purple AppShell, then a destructive logout. Transparent ROOT.
$mkSettingsTile = function (string $id, string $icon, string $tint, string $label, string $tapAction, array $tapParams) use ($node, $style, $C): array {
    return [
        $id           => $node('Container', true, array_merge($style, ['background' => $C['card'], 'radius' => 14, 'padding' => 14, 'borderWidth' => 1, 'borderColor' => $C['cardBorder'], 'gap' => 0, 'align' => 'stretch', 'onTapAction' => $tapAction, 'onTapParams' => $tapParams]), [$id . 'Row'], 'ROOT'),
        $id . 'Row'   => $node('Row', true, ['gap' => 12, 'align' => 'center'], [$id . 'Ic', $id . 'Lb', $id . 'Ch'], $id),
        $id . 'Ic'    => $node('Icon', false, ['name' => $icon, 'size' => 20, 'color' => $tint], [], $id . 'Row'),
        $id . 'Lb'    => $node('Text', false, ['text' => $label, 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['white'], 'align' => 'right', 'binding' => '', 'maxLines' => 1, 'flex' => 1], [], $id . 'Row'),
        $id . 'Ch'    => $node('Icon', false, ['name' => 'chevron_left', 'size' => 18, 'color' => $C['muted']], [], $id . 'Row'),
    ];
};

$settingsWidgets = array_merge(
    [
        'ROOT'   => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 16, 'gap' => 12, 'align' => 'stretch', 'flex' => 0]), ['sTitle', 'tLang', 'tPrivacy', 'tTerms', 'tContact', 'tAbout', 'tAccount', 'btnLogout'], null),
        'sTitle' => $node('Text', false, ['text' => 'الإعدادات', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'right', 'binding' => '', 'maxLines' => 1], [], 'ROOT'),
    ],
    $mkSettingsTile('tLang', 'language', '#26C6DA', 'اللغة', 'core.setLocale', ['code' => 'ar']),
    $mkSettingsTile('tPrivacy', 'privacy_tip', '#66BB6A', 'سياسة الخصوصية', 'core.navigate', ['route' => '/page/privacy', 'mode' => 'push']),
    $mkSettingsTile('tTerms', 'description', '#26A69A', 'شروط الاستخدام', 'core.navigate', ['route' => '/page/terms', 'mode' => 'push']),
    $mkSettingsTile('tContact', 'support_agent', '#42A5F5', 'تواصل معنا', 'core.navigate', ['route' => '/contact-us', 'mode' => 'push']),
    $mkSettingsTile('tAbout', 'info', '#7C4DFF', 'عن التطبيق', 'core.navigate', ['route' => '/page/about', 'mode' => 'push']),
    $mkSettingsTile('tAccount', 'person', '#5C6BC0', 'الحساب', 'core.navigate', ['route' => '/profile', 'mode' => 'push']),
    [
        'btnLogout' => $node('Button', false, array_merge($style, ['label' => 'تسجيل الخروج', 'background' => $C['card'], 'color' => $C['red'], 'radius' => 14, 'flex' => 0, 'onTapAction' => 'core.logout', 'onTapParams' => ['confirm' => true]]), [], 'ROOT'),
    ]
);

return [
    'key'     => 'core',
    'name'    => 'Core',
    'icon'    => 'settings',
    'screens' => ['intro', 'login', 'register', 'forgot_password', 'home', 'profile', 'settings'],

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
        // تغيير صورة الملف الشخصي: العميل بيحطّه كـ onTap على عنصر الصورة. الـ parser
        // في فلاتر بيفتح المعرض/الكاميرا، يرفع الصورة، ويحدّث المستخدم الحالي فورًا.
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
            'version'      => '1.2.0',
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
            'version'      => '1.2.0',
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
            'name'         => 'profile',
            'label'        => 'الملف الشخصي',
            'icon'         => '👤',
            'version'      => '1.2.0',
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
            'version'      => '1.2.0',
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
