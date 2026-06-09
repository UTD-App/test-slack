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

// login — email/password + core.login submit (successRoute → home '/')
$loginWidgets = [
    'ROOT'   => $node('Container', true, array_merge(['background' => '#ffffff', 'padding' => 24, 'gap' => 16, 'align' => 'stretch', 'flex' => 0], $style), ['t1', 't2', 'fEmail', 'fPass', 'btn'], null),
    't1'     => $node('Text', false, ['text' => 'أهلاً بك 👋', 'fontSize' => 24, 'fontWeight' => 600, 'color' => '#0F172A', 'align' => 'right', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
    't2'     => $node('Text', false, ['text' => 'سجّل دخولك للمتابعة', 'fontSize' => 16, 'fontWeight' => 400, 'color' => '#64748B', 'align' => 'right', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
    'fEmail' => $node('TextField', false, ['fieldId' => 'email', 'placeholder' => 'البريد الإلكتروني', 'live' => true, 'keyboard' => 'email', 'fillColor' => '#f1f5f9', 'radius' => 10, 'flex' => 0], [], 'ROOT'),
    'fPass'  => $node('TextField', false, ['fieldId' => 'password', 'placeholder' => 'كلمة المرور', 'live' => true, 'obscure' => true, 'fillColor' => '#f1f5f9', 'radius' => 10, 'flex' => 0], [], 'ROOT'),
    'btn'    => $node('Button', false, array_merge(['label' => 'دخول', 'background' => '#2563eb', 'color' => '#ffffff', 'radius' => 12, 'flex' => 0, 'onTapAction' => 'core.login', 'onTapParams' => ['emailField' => 'email', 'passwordField' => 'password', 'successRoute' => '/']], ['onTapTarget' => '']), [], 'ROOT'),
];

// home — simple landing (client redesigns freely)
$homeWidgets = [
    'ROOT' => $node('Container', true, array_merge(['background' => '#ffffff', 'padding' => 24, 'gap' => 12, 'align' => 'center', 'flex' => 0], $style), ['h1', 'h2'], null),
    'h1'   => $node('Text', false, ['text' => 'الرئيسية', 'fontSize' => 24, 'fontWeight' => 700, 'color' => '#0F172A', 'align' => 'center', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
    'h2'   => $node('Text', false, ['text' => 'أهلاً بك في تطبيقك', 'fontSize' => 15, 'fontWeight' => 400, 'color' => '#64748B', 'align' => 'center', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
];

// profile — avatar + name + email bound to core.currentUser (Scope)
$profileWidgets = [
    'ROOT'   => $node('Container', true, array_merge(['background' => '#ffffff', 'padding' => 24, 'gap' => 16, 'align' => 'center', 'flex' => 0], $style), ['scope'], null),
    'scope'  => $node('Scope', true, ['source' => 'core.currentUser'], ['avatar', 'name', 'email'], 'ROOT'),
    'avatar' => $node('Image', false, ['src' => '', 'width' => 120, 'height' => 120, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0, 'binding' => 'core.currentUser.avatar', 'onTapAction' => 'core.changeAvatar', 'onTapTarget' => '', 'onTapParams' => ['source' => 'gallery']], [], 'scope'),
    'name'   => $node('Text', false, ['text' => 'الاسم', 'fontSize' => 20, 'fontWeight' => 600, 'color' => '#0F172A', 'align' => 'center', 'binding' => 'core.currentUser.name', 'maxLines' => 0], [], 'scope'),
    'email'  => $node('Text', false, ['text' => 'name@email.com', 'fontSize' => 14, 'fontWeight' => 400, 'color' => '#64748B', 'align' => 'center', 'binding' => 'core.currentUser.email', 'maxLines' => 0], [], 'scope'),
];

// settings — logout (core.logout)
$settingsWidgets = [
    'ROOT'      => $node('Container', true, array_merge(['background' => '#ffffff', 'padding' => 16, 'gap' => 12, 'align' => 'stretch', 'flex' => 0], $style), ['sTitle', 'btnLogout'], null),
    'sTitle'    => $node('Text', false, ['text' => 'الإعدادات', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#0F172A', 'align' => 'right', 'binding' => '', 'maxLines' => 0], [], 'ROOT'),
    'btnLogout' => $node('Button', false, array_merge(['label' => 'تسجيل الخروج', 'background' => '#ef4444', 'color' => '#ffffff', 'radius' => 12, 'flex' => 0, 'onTapAction' => 'core.logout', 'onTapParams' => ['confirm' => true]], ['onTapTarget' => '']), [], 'ROOT'),
];

return [
    'key'     => 'core',
    'name'    => 'Core',
    'icon'    => 'settings',
    'screens' => ['intro', 'login', 'register', 'forgot_password', 'home', 'profile', 'settings'],

    // Display bindings (profile screen ⇄ current user)
    'elements' => [
        ['key' => 'name',   'label' => 'الاسم',        'type' => 'string',    'screen' => 'profile'],
        ['key' => 'email',  'label' => 'البريد',       'type' => 'string',    'screen' => 'profile'],
        ['key' => 'bio',    'label' => 'نبذة',         'type' => 'string',    'screen' => 'profile'],
        ['key' => 'avatar', 'label' => 'الصورة',       'type' => 'image_url', 'screen' => 'profile'],
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
                ['key' => 'name',   'label' => 'الاسم',  'type' => 'string'],
                ['key' => 'email',  'label' => 'البريد', 'type' => 'string'],
                ['key' => 'bio',    'label' => 'نبذة',   'type' => 'string'],
                ['key' => 'avatar', 'label' => 'الصورة', 'type' => 'image_url'],
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
            'chrome'       => ['appBar' => ['enabled' => false, 'title' => 'تسجيل الدخول', 'bg' => '#ffffff', 'actions' => []]],
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
            'chrome'       => ['appBar' => ['enabled' => true, 'title' => 'الرئيسية', 'bg' => '#2563eb', 'actions' => []]],
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
            'chrome'       => ['appBar' => ['enabled' => true, 'title' => 'الملف الشخصي', 'bg' => '#ffffff', 'actions' => []]],
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
            'chrome'       => ['appBar' => ['enabled' => true, 'title' => 'الإعدادات', 'bg' => '#ffffff', 'actions' => []]],
            'widgets'      => $settingsWidgets,
        ],
    ],
];
