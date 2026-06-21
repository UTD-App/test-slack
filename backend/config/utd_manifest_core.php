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
 * `action_elements` are the source of truth for actions:
 *   - `produces`       → the Stac `actionType` emitted on the client (e.g. core.login)
 *   - `default_shape`  → suggested editor widget (button | input | switch | list)
 *   - `params`         → the fields the action consumes, so Studio can render the
 *                        right inputs generically. param `type`:
 *                          field_ref  → dropdown of textFormField ids on the screen
 *                          route      → screen picker
 *                          string|bool→ literal input
 *
 * Element keys map 1:1 to what the Flutter `core.currentUser` object source
 * exposes (see flutter/lib/shared/stac/core_stac_sources.dart).
 *
 * `default_screens` ships ready-to-edit Craft trees (login / home / profile /
 * settings) so UTD Studio seeds a working core app on first Sync. Shape matches
 * what the editor saves (version.widgets) — see utdStack docs/default-screens-sync.
 *
 * DESIGN: these trees mirror the REAL native screens as closely as the Stac
 * primitives allow, so that what UTD Studio shows (and pushes back to the app)
 * matches the app's own design — a designer pulling these into the app sees no
 * visual change. The native theme is the "Lumia" dark purple / pink-accent
 * palette (auth + profile + settings on deep purple; home on light surface).
 * Gradients/frosted-glass/level-badges are bespoke Flutter flourishes that
 * primitives can't express — they are approximated with the dominant SOLID
 * colour (the only fill proven to survive the Craft→Stac transform).
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
// Gradients aren't proven to render through the Studio transform, so each token
// is the dominant solid colour of its native gradient/token.
$C = [
    'bg'         => '#3A2A7E', // deep purple screen (≈ authBgGradient mid #4226A6→#2A1556)
    'bgProfile'  => '#4A2E8C', // profile screen (≈ lumiaBgGradient mid #583C9E)
    'card'       => '#5B4399', // card surface (≈ lumiaCardGradient #6E50B2→#513B98)
    'cardBorder' => '#8E72D2', // lumiaCardBorder
    'accent'     => '#BE4AFF', // lumiaAccent
    'accentLt'   => '#D9A0FF', // lumiaAccentLight (links)
    'pink'       => '#EC4899', // pinkCtaGradient (primary CTA)
    'red'        => '#FF5A6E', // destructive (logout / delete)
    'white'      => '#FFFFFF',
    'muted'      => '#CDBFEE', // lumiaTextSecondary
    'bioText'    => '#E3D8FB',
    'field'      => '#ECE7FB', // light input fill → default dark field text stays legible
    // Home rides the light surface (native home is ColorScheme.surface, not the
    // purple gradient), so it keeps light fills + dark text.
    'homeBg'     => '#FFFFFF',
    'homeText'   => '#0F172A',
    'homeMuted'  => '#64748B',
    'homeField'  => '#F1F5F9',
];

// login — email/password + core.login submit (successRoute → home '/') +
// recover-password and register links. Deep-purple screen, pink CTA pill,
// accent-light links — mirrors the real auth design.
$loginWidgets = [
    'ROOT'    => $node('Container', true, array_merge($style, ['background' => $C['bg'], 'padding' => 22, 'gap' => 16, 'align' => 'stretch', 'flex' => 0]), ['t1', 't2', 'fEmail', 'fPass', 'recover', 'btn', 'regRow'], null),
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

// home — top row (title + notifications) + search + welcome. Native home rides
// the LIGHT surface (not the purple gradient), so it stays light with dark text.
$homeWidgets = [
    'ROOT'    => $node('Container', true, array_merge($style, ['background' => $C['homeBg'], 'padding' => 16, 'gap' => 14, 'align' => 'stretch', 'flex' => 0]), ['topRow', 'search', 'welcome'], null),
    'topRow'  => $node('Row', true, ['gap' => 8, 'align' => 'center'], ['appName', 'bell'], 'ROOT'),
    'appName' => $node('Text', false, ['text' => 'الرئيسية', 'fontSize' => 20, 'fontWeight' => 700, 'color' => $C['homeText'], 'align' => 'right', 'binding' => '', 'maxLines' => 1, 'flex' => 1], [], 'topRow'),
    'bell'    => $node('Icon', false, ['name' => 'notifications_none', 'size' => 24, 'color' => $C['homeMuted'], 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/notifications', 'mode' => 'push']], [], 'topRow'),
    'search'  => $node('TextField', false, ['fieldId' => 'home_search', 'placeholder' => 'بحث', 'live' => false, 'fillColor' => $C['homeField'], 'radius' => 14, 'flex' => 0], [], 'ROOT'),
    'welcome' => $node('Text', false, ['text' => 'أهلاً بك في تطبيقك', 'fontSize' => 15, 'fontWeight' => 400, 'color' => $C['homeMuted'], 'align' => 'right', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
];

// profile — CENTERED identity block on the deep-purple screen: circular avatar
// (tap → change), name + country flag, UID, bio, country — bound to
// core.currentUser (Scope). Mirrors the native "Me" landing (no cover banner;
// the gradient ring / level badges are bespoke Flutter and stay there).
$profileWidgets = [
    'ROOT'    => $node('Container', true, array_merge($style, ['background' => $C['bgProfile'], 'padding' => 20, 'gap' => 10, 'align' => 'center', 'flex' => 0]), ['scope'], null),
    'scope'   => $node('Scope', true, ['source' => 'core.currentUser'], ['avatar', 'nameRow', 'uid', 'bio', 'country'], 'ROOT'),
    'avatar'  => $node('Image', false, ['src' => '', 'width' => 96, 'height' => 96, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0, 'binding' => 'core.currentUser.avatar', 'onTapAction' => 'core.changeAvatar', 'onTapTarget' => '', 'onTapParams' => ['source' => 'gallery']], [], 'scope'),
    'nameRow' => $node('Row', true, ['gap' => 6, 'align' => 'center'], ['name', 'flag'], 'scope'),
    'name'    => $node('Text', false, ['text' => 'الاسم', 'fontSize' => 20, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 'core.currentUser.name', 'maxLines' => 1], [], 'nameRow'),
    'flag'    => $node('Image', false, ['src' => '', 'width' => 22, 'height' => 15, 'fit' => 'cover', 'radius' => 3, 'binding' => 'core.currentUser.flag', 'visibleBinding' => 'core.currentUser.flag'], [], 'nameRow'),
    'uid'     => $node('Text', false, ['text' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 'core.currentUser.uid', 'maxLines' => 1], [], 'scope'),
    'bio'     => $node('Text', false, ['text' => '', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['bioText'], 'align' => 'center', 'binding' => 'core.currentUser.bio', 'visibleBinding' => 'core.currentUser.bio', 'maxLines' => 0], [], 'scope'),
    'country' => $node('Text', false, ['text' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 'core.currentUser.country', 'visibleBinding' => 'core.currentUser.country', 'maxLines' => 0], [], 'scope'),
];

// settings — purple cards, each a tappable row (tinted icon + label + chevron)
// over the deep-purple screen, then a destructive logout card. Mirrors the
// native settings list (lumiaCardGradient cards with per-row icon tints).
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
        'ROOT' => $node('Container', true, array_merge($style, ['background' => $C['bg'], 'padding' => 16, 'gap' => 12, 'align' => 'stretch', 'flex' => 0]), ['tLang', 'tPrivacy', 'tAbout', 'tAccount', 'btnLogout'], null),
    ],
    $mkSettingsTile('tLang', 'language', '#26C6DA', 'اللغة', 'core.setLocale', ['code' => 'ar']),
    $mkSettingsTile('tPrivacy', 'privacy_tip', '#66BB6A', 'سياسة الخصوصية', 'core.navigate', ['route' => '/page/privacy', 'mode' => 'push']),
    $mkSettingsTile('tAbout', 'info', '#7C4DFF', 'عن التطبيق', 'core.navigate', ['route' => '/page/about', 'mode' => 'push']),
    $mkSettingsTile('tAccount', 'person', '#42A5F5', 'الحساب', 'core.navigate', ['route' => '/profile', 'mode' => 'push']),
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

    // Single-object source: the signed-in user. A `Scope` (utdObject) bound to
    // `core.currentUser` lets the designer drop a profile area and bind its
    // children (name/email/bio/avatar) to the live user. Resolved on the client
    // by `registerCoreStacSources()` (flutter/lib/shared/stac/core_stac_sources.dart).
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
            'version'      => '1.0.0',
            'nav'          => false,
            'navIcon'      => 'person',
            'order'        => 1,
            'role'         => 'auth.login',
            'requiresAuth' => false,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'تسجيل الدخول', 'bg' => $C['bg'], 'actions' => []]],
            'widgets'      => $loginWidgets,
        ],
        [
            'name'         => 'home',
            'label'        => 'الرئيسية',
            'icon'         => '🏠',
            'version'      => '1.0.0',
            'nav'          => true,
            'navIcon'      => 'home',
            'order'        => 2,
            'role'         => 'app.home',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'الرئيسية', 'bg' => $C['homeBg'], 'actions' => []]],
            'widgets'      => $homeWidgets,
        ],
        [
            'name'         => 'profile',
            'label'        => 'الملف الشخصي',
            'icon'         => '👤',
            'version'      => '1.0.0',
            'nav'          => true,
            'navIcon'      => 'person',
            'order'        => 30,
            'role'         => 'auth.profile',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'الملف الشخصي', 'bg' => $C['bgProfile'], 'actions' => []]],
            'widgets'      => $profileWidgets,
        ],
        [
            'name'         => 'settings',
            'label'        => 'الإعدادات',
            'icon'         => '⚙️',
            'version'      => '1.0.0',
            'nav'          => true,
            'navIcon'      => 'settings',
            'order'        => 40,
            'role'         => 'app.settings',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => true, 'title' => 'الإعدادات', 'bg' => $C['bg'], 'actions' => []]],
            'widgets'      => $settingsWidgets,
        ],
    ],
];
