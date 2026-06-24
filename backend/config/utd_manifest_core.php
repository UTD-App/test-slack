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

    // ── Auth trio (intro/login/register) — the brighter violet "auth" theme ──
    // (mirrors ColorManager.authBgGradient / pinkCtaGradient / frosted* tokens).
    'authFrom'    => '#6A4AE0', // authBgGradient start (top-left)
    'authTo'      => '#2A1556', // authBgGradient end (bottom-right)
    'authBg'      => '#3A2A7E', // solid fallback if the transform drops the gradient
    'pinkFrom'    => '#F22A8C', // pinkCtaGradient start
    'pinkTo'      => '#FF5BA6', // pinkCtaGradient end
    'frost'       => '#1AFFFFFF', // frostedFill  (white @ 10%)
    'frostBorder' => '#33FFFFFF', // frostedBorder (white @ 20%)
    'outline'     => '#8CFFFFFF', // outlined CTA border (white @ 55%)
    'pillText'    => '#463394', // active language-segment text (on the white pill)
];

// Reusable tappable menu card (tinted icon + label + chevron), parented to ROOT.
$mkTile = function (string $id, string $icon, string $tint, string $label, string $tapAction, array $tapParams, string $labelKey = '') use ($node, $style, $C): array {
    return [
        $id         => $node('Container', true, array_merge($style, ['background' => $C['card'], 'radius' => 14, 'padding' => 14, 'borderWidth' => 1, 'borderColor' => $C['cardBorder'], 'gap' => 0, 'align' => 'stretch', 'onTapAction' => $tapAction, 'onTapParams' => $tapParams]), [$id . 'Row'], 'ROOT'),
        $id . 'Row' => $node('Row', true, ['gap' => 12, 'align' => 'center'], [$id . 'Ic', $id . 'Lb', $id . 'Ch'], $id),
        $id . 'Ic'  => $node('Icon', false, ['name' => $icon, 'size' => 20, 'color' => $tint], [], $id . 'Row'),
        $id . 'Lb'  => $node('Text', false, ['text' => $label, 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['white'], 'align' => 'right', 'binding' => $labelKey !== '' ? "t.{$labelKey}" : '', 'maxLines' => 1, 'flex' => 1], [], $id . 'Row'),
        $id . 'Ch'  => $node('Icon', false, ['name' => 'chevron_left_rounded', 'size' => 18, 'color' => $C['muted']], [], $id . 'Row'),
    ];
};

// ── AUTH TRIO (intro / login / register) — server-driven mirrors of the native
// `authentication` package screens (the brighter-violet "auth" theme). Composed
// from primitives only: gradient ROOT (solid `authBg` fallback), gradient/outlined
// CTA = a Container (gradient/border) wrapping a centered Text + onTap (the Button
// primitive has no gradient), the eagle logo bound to `core.app.logo`, and the
// input fields wrapped in a `Form` so `core.login`/`core.register` can read them.
// FIDELITY NOTE: utdTextField can't do white text / leading icons / a password-eye,
// so the fields use a legible LIGHT fill (`field`) — the exact frosted/icon look
// needs a field-renderer enhancement (deferred). ──────────────────────────────

// intro — welcome / first-run (logo + tagline + Create-Account / Sign-in card).
$introWidgets = [
    // ROOT transparent — the full-bleed gradient now lives on `chrome.background`
    // so it fills the WHOLE screen (a flex:0 gradient Container only covers its
    // own content height → flat colour below). Top spacing keeps the hero off the
    // status bar / camera cutout (appBar is disabled).
    // padT 48 clears the status bar / camera cutout (chrome.background gradient
    // makes the body extend behind the status bar; Craft has no SafeArea node, so
    // we pad the content down — the gradient stays full-bleed behind it).
    'ROOT'        => $node('Container', true, array_merge($style, ['background' => '#00000000', 'padMode' => 'sides', 'padL' => 22, 'padT' => 48, 'padR' => 22, 'padB' => 22, 'gap' => 20, 'align' => 'stretch', 'flex' => 0]), ['langRow', 'hero', 'card', 'footer'], null),

    // Language pill (EN active / ع) — top-end. Tapping switches the app locale.
    // (Active highlight is static — there's no locale binding to drive it.)
    'langRow'     => $node('Row', true, ['justify' => 'flex-end', 'align' => 'center'], ['pill'], 'ROOT'),
    'pill'        => $node('Row', true, array_merge($style, ['background' => $C['frost'], 'radius' => 30, 'padding' => 4, 'borderWidth' => 1, 'borderColor' => $C['frostBorder'], 'gap' => 2, 'align' => 'center']), ['segEn', 'segAr'], 'langRow'),
    'segEn'       => $node('Container', true, array_merge($style, ['background' => $C['white'], 'radius' => 22, 'padding' => 8, 'align' => 'center', 'onTapAction' => 'core.setLocale', 'onTapParams' => ['code' => 'en']]), ['segEnT'], 'pill'),
    'segEnT'      => $node('Text', false, ['text' => 'EN', 'fontSize' => 13, 'fontWeight' => 700, 'color' => $C['pillText'], 'align' => 'center', 'binding' => '', 'maxLines' => 1], [], 'segEn'),
    'segAr'       => $node('Container', true, array_merge($style, ['background' => '#00000000', 'radius' => 22, 'padding' => 8, 'align' => 'center', 'onTapAction' => 'core.setLocale', 'onTapParams' => ['code' => 'ar']]), ['segArT'], 'pill'),
    'segArT'      => $node('Text', false, ['text' => 'ع', 'fontSize' => 13, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => '', 'maxLines' => 1], [], 'segAr'),

    // Hero — logo in a clean white circular badge + tagline. The white disc makes
    // a logo-on-white asset read as a deliberate round badge (not a white square).
    'hero'        => $node('Container', true, ['background' => '#00000000', 'padMode' => 'sides', 'padL' => 8, 'padT' => 24, 'padR' => 8, 'padB' => 8, 'gap' => 16, 'align' => 'center', 'flex' => 0], ['logoBadge', 'tagline'], 'ROOT'),
    'logoBadge'   => $node('Container', true, array_merge($style, ['width' => 116, 'height' => 116, 'radius' => 58, 'background' => $C['white'], 'padding' => 16, 'align' => 'center', 'valign' => 'center', 'flex' => 0]), ['logoScope'], 'hero'),
    'logoScope'   => $node('Scope', true, ['source' => 'core.app'], ['logoImg'], 'logoBadge'),
    'logoImg'     => $node('Image', false, ['src' => '', 'binding' => 'core.app.logo', 'width' => 80, 'height' => 80, 'fit' => 'contain'], [], 'logoScope'),
    'tagline'     => $node('Text', false, ['text' => 'العب · بث · تواصل', 'fontSize' => 15, 'fontWeight' => 500, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.screens.intro.tagline', 'maxLines' => 1], [], 'hero'),

    // Frosted CTA card.
    'card'        => $node('Container', true, array_merge($style, ['background' => $C['frost'], 'borderWidth' => 1, 'borderColor' => $C['frostBorder'], 'radius' => 28, 'padding' => 20, 'gap' => 14, 'align' => 'stretch', 'flex' => 0]), ['btnCreate', 'btnSignin'], 'ROOT'),
    'btnCreate'   => $node('Container', true, array_merge($style, ['gradient' => 1, 'gradFrom' => $C['pinkFrom'], 'gradTo' => $C['pinkTo'], 'gradDir' => 'to right', 'background' => $C['pink'], 'radius' => 30, 'padding' => 16, 'align' => 'center', 'flex' => 0, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/register', 'mode' => 'push']]), ['btnCreateT'], 'card'),
    // i18n EXAMPLE: bind label to a translation key (`t.<group>.<key>`). The app
    // localises it to the current language from the dashboard catalog; the literal
    // `text` stays as the fallback when the key is missing. Editable from Studio
    // (write-back) or the dashboard. Bindings survive the Craft→Stac transform.
    'btnCreateT'  => $node('Text', false, ['text' => 'إنشاء حساب', 'binding' => 't.app.create_account', 'fontSize' => 16, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'btnCreate'),
    'btnSignin'   => $node('Container', true, array_merge($style, ['background' => '#00000000', 'borderWidth' => 1, 'borderColor' => $C['outline'], 'radius' => 30, 'padding' => 16, 'align' => 'center', 'flex' => 0, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/login', 'mode' => 'push']]), ['btnSigninT'], 'card'),
    'btnSigninT'  => $node('Text', false, ['text' => 'تسجيل الدخول بالبريد الإلكتروني', 'binding' => 't.app.sign_in_email', 'fontSize' => 15, 'fontWeight' => 600, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'btnSignin'),

    // Footer — terms · privacy links.
    'footer'      => $node('Container', true, ['background' => '#00000000', 'padding' => 4, 'gap' => 4, 'align' => 'center', 'flex' => 0], ['ftrText', 'ftrLinks'], 'ROOT'),
    'ftrText'     => $node('Text', false, ['text' => 'بالتسجيل، أنت توافق على', 'fontSize' => 12, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.screens.intro.terms_prefix', 'maxLines' => 0], [], 'footer'),
    'ftrLinks'    => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['ftrTerms', 'ftrDot', 'ftrPrivacy'], 'footer'),
    'ftrTerms'    => $node('Text', false, ['text' => 'شروط الخدمة', 'fontSize' => 12, 'fontWeight' => 600, 'color' => $C['accentLt'], 'align' => 'center', 'binding' => 't.app.terms_of_service', 'maxLines' => 1, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/page/terms', 'mode' => 'push']], [], 'ftrLinks'),
    'ftrDot'      => $node('Text', false, ['text' => '·', 'fontSize' => 12, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => '', 'maxLines' => 1], [], 'ftrLinks'),
    'ftrPrivacy'  => $node('Text', false, ['text' => 'سياسة الخصوصية', 'fontSize' => 12, 'fontWeight' => 600, 'color' => $C['accentLt'], 'align' => 'center', 'binding' => 't.app.privacy_policy', 'maxLines' => 1, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/page/privacy', 'mode' => 'push']], [], 'ftrLinks'),
];

// login — back + circular frosted logo + greeting + form + register CTA + footer.
$loginWidgets = [
    // ROOT transparent — full-bleed gradient via `chrome.background` (fills the
    // whole screen; a flex:0 gradient Container only covers its content).
    'ROOT'       => $node('Container', true, array_merge($style, ['background' => '#00000000', 'padMode' => 'sides', 'padL' => 22, 'padT' => 48, 'padR' => 22, 'padB' => 22, 'gap' => 18, 'align' => 'stretch', 'flex' => 0]), ['lTop', 'lHero', 'lForm', 'regRow', 'lFooter'], null),

    'lTop'       => $node('Row', true, ['justify' => 'flex-start', 'align' => 'center'], ['lBack'], 'ROOT'),
    'lBack'      => $node('Icon', false, ['name' => 'arrow_back_ios_new', 'size' => 20, 'color' => $C['white'], 'onTapAction' => 'core.back'], [], 'lTop'),

    // Hero — circular frosted logo disc + greeting + subtitle.
    'lHero'      => $node('Container', true, ['background' => '#00000000', 'padding' => 4, 'gap' => 10, 'align' => 'center', 'flex' => 0], ['lLogoDisc', 'lGreet', 'lSub'], 'ROOT'),
    'lLogoDisc'  => $node('Container', true, array_merge($style, ['width' => 96, 'height' => 96, 'radius' => 48, 'background' => $C['white'], 'padding' => 16, 'align' => 'center', 'valign' => 'center']), ['lLogoScope'], 'lHero'),
    'lLogoScope' => $node('Scope', true, ['source' => 'core.app'], ['lLogoImg'], 'lLogoDisc'),
    'lLogoImg'   => $node('Image', false, ['src' => '', 'binding' => 'core.app.logo', 'width' => 64, 'height' => 64, 'fit' => 'contain'], [], 'lLogoScope'),
    'lGreet'     => $node('Text', false, ['text' => 'مرحباً 👋', 'fontSize' => 30, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.screens.login.greeting', 'maxLines' => 1], [], 'lHero'),
    'lSub'       => $node('Text', false, ['text' => 'أدخل بريدك الإلكتروني للمتابعة', 'fontSize' => 15, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.screens.login.subtitle', 'maxLines' => 0], [], 'lHero'),

    // Form — email + password + recover link + login button.
    'lForm'      => $node('Form', true, [], ['lCol'], 'ROOT'),
    'lCol'       => $node('Container', true, ['background' => '#00000000', 'gap' => 14, 'align' => 'stretch', 'flex' => 0], ['lEmail', 'lPass', 'recoverRow', 'btnLogin'], 'lForm'),
    'lEmail'     => $node('TextField', false, ['fieldId' => 'email', 'placeholder' => 'أدخل عنوان بريدك الإلكتروني', 'tHint' => 'app.enter_email', 'live' => true, 'keyboard' => 'email', 'fillColor' => $C['frost'], 'textColor' => $C['white'], 'borderColor' => $C['frostBorder'], 'prefixIcon' => 'alternate_email', 'prefixIconColor' => $C['accentLt'], 'radius' => 16, 'flex' => 0], [], 'lCol'),
    'lPass'      => $node('TextField', false, ['fieldId' => 'password', 'placeholder' => 'كلمة المرور', 'tHint' => 'app.password', 'live' => true, 'obscure' => true, 'fillColor' => $C['frost'], 'textColor' => $C['white'], 'borderColor' => $C['frostBorder'], 'prefixIcon' => 'lock_outline_rounded', 'prefixIconColor' => $C['accentLt'], 'radius' => 16, 'flex' => 0], [], 'lCol'),
    'recoverRow' => $node('Row', true, ['justify' => 'flex-end', 'align' => 'center'], ['recover'], 'lCol'),
    'recover'    => $node('Text', false, ['text' => 'استعادة كلمة المرور', 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['accentLt'], 'align' => 'center', 'binding' => 't.screens.login.forgot', 'maxLines' => 1, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/recover-password', 'mode' => 'push']], [], 'recoverRow'),
    'btnLogin'   => $node('Container', true, array_merge($style, ['gradient' => 1, 'gradFrom' => $C['pinkFrom'], 'gradTo' => $C['pinkTo'], 'gradDir' => 'to right', 'background' => $C['pink'], 'radius' => 30, 'padding' => 16, 'align' => 'center', 'flex' => 0, 'onTapAction' => 'core.login', 'onTapParams' => ['emailField' => 'email', 'passwordField' => 'password', 'successRoute' => '/']]), ['btnLoginT'], 'lCol'),
    'btnLoginT'  => $node('Text', false, ['text' => 'تسجيل الدخول', 'fontSize' => 16, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.app.login', 'maxLines' => 1], [], 'btnLogin'),

    // Register CTA row.
    'regRow'     => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['regText', 'regBtn'], 'ROOT'),
    'regText'    => $node('Text', false, ['text' => 'لم تسجل بعد؟', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.screens.login.no_account', 'maxLines' => 1], [], 'regRow'),
    'regBtn'     => $node('Text', false, ['text' => 'سجل الآن', 'fontSize' => 14, 'fontWeight' => 700, 'color' => $C['accentLt'], 'align' => 'center', 'binding' => 't.screens.login.register_now', 'maxLines' => 1, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/register', 'mode' => 'push']], [], 'regRow'),

    // Footer — user agreement + privacy.
    'lFooter'     => $node('Container', true, ['background' => '#00000000', 'padding' => 4, 'gap' => 4, 'align' => 'center', 'flex' => 0], ['lFtrText', 'lFtrLinks'], 'ROOT'),
    'lFtrText'    => $node('Text', false, ['text' => 'بتسجيل الدخول أنت توافق على', 'fontSize' => 12, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.screens.login.terms_prefix', 'maxLines' => 0], [], 'lFooter'),
    'lFtrLinks'   => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['lFtrUa', 'lFtrAnd', 'lFtrPrivacy'], 'lFooter'),
    'lFtrUa'      => $node('Text', false, ['text' => 'اتفاقية المستخدم', 'fontSize' => 12, 'fontWeight' => 600, 'color' => $C['accentLt'], 'align' => 'center', 'binding' => 't.app.user_agreement', 'maxLines' => 1, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/page/terms', 'mode' => 'push']], [], 'lFtrLinks'),
    'lFtrAnd'     => $node('Text', false, ['text' => 'و', 'fontSize' => 12, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.app.and', 'maxLines' => 1], [], 'lFtrLinks'),
    'lFtrPrivacy' => $node('Text', false, ['text' => 'سياسة الخصوصية', 'fontSize' => 12, 'fontWeight' => 600, 'color' => $C['accentLt'], 'align' => 'center', 'binding' => 't.app.privacy_policy', 'maxLines' => 1, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/page/privacy', 'mode' => 'push']], [], 'lFtrLinks'),
];

// register — back + title + HERO (logo badge + heading + subtitle) + email/password
// form + Next + "already have an account?" link. Mirrors the login screen so the
// two auth forms read as a pair (the old register was just title + 2 fields + a
// button with a big empty void). Gradient via `chrome.background` (ROOT transparent).
$registerWidgets = [
    'ROOT'    => $node('Container', true, array_merge($style, ['background' => '#00000000', 'padMode' => 'sides', 'padL' => 22, 'padT' => 48, 'padR' => 22, 'padB' => 22, 'gap' => 18, 'align' => 'stretch', 'flex' => 0]), ['rTop', 'rHero', 'rForm', 'rAlready'], null),

    'rTop'    => $node('Row', true, ['gap' => 8, 'align' => 'center'], ['rBack', 'rTitle'], 'ROOT'),
    'rBack'   => $node('Icon', false, ['name' => 'arrow_back_ios_new', 'size' => 20, 'color' => $C['white'], 'onTapAction' => 'core.back'], [], 'rTop'),
    'rTitle'  => $node('Text', false, ['text' => 'التسجيل', 'fontSize' => 16, 'fontWeight' => 600, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.app.register', 'maxLines' => 1, 'flex' => 1], [], 'rTop'),

    // Hero — white logo badge + heading + subtitle.
    'rHero'      => $node('Container', true, ['background' => '#00000000', 'padMode' => 'sides', 'padL' => 8, 'padT' => 8, 'padR' => 8, 'padB' => 4, 'gap' => 10, 'align' => 'center', 'flex' => 0], ['rLogoBadge', 'rHeading', 'rSub'], 'ROOT'),
    'rLogoBadge' => $node('Container', true, array_merge($style, ['width' => 92, 'height' => 92, 'radius' => 46, 'background' => $C['white'], 'padding' => 14, 'align' => 'center', 'valign' => 'center', 'flex' => 0]), ['rLogoScope'], 'rHero'),
    'rLogoScope' => $node('Scope', true, ['source' => 'core.app'], ['rLogoImg'], 'rLogoBadge'),
    'rLogoImg'   => $node('Image', false, ['src' => '', 'binding' => 'core.app.logo', 'width' => 64, 'height' => 64, 'fit' => 'contain'], [], 'rLogoScope'),
    'rHeading'   => $node('Text', false, ['text' => 'إنشاء حساب', 'fontSize' => 26, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.app.create_account', 'maxLines' => 1], [], 'rHero'),
    'rSub'       => $node('Text', false, ['text' => 'أنشئ حسابك في خطوات بسيطة', 'fontSize' => 15, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.screens.register.subtitle', 'maxLines' => 0], [], 'rHero'),

    // Form — email + password (frosted pill with leading icons, like login) + Next.
    'rForm'  => $node('Form', true, [], ['rCol'], 'ROOT'),
    'rCol'   => $node('Container', true, ['background' => '#00000000', 'gap' => 14, 'align' => 'stretch', 'flex' => 0], ['rEmail', 'rPass', 'rNext'], 'rForm'),
    'rEmail' => $node('TextField', false, ['fieldId' => 'email', 'placeholder' => 'البريد الإلكتروني', 'tHint' => 'app.email', 'live' => true, 'keyboard' => 'email', 'fillColor' => $C['frost'], 'textColor' => $C['white'], 'borderColor' => $C['frostBorder'], 'prefixIcon' => 'alternate_email', 'prefixIconColor' => $C['accentLt'], 'radius' => 16, 'flex' => 0], [], 'rCol'),
    'rPass'  => $node('TextField', false, ['fieldId' => 'password', 'placeholder' => 'كلمة المرور', 'tHint' => 'app.password', 'live' => true, 'obscure' => true, 'fillColor' => $C['frost'], 'textColor' => $C['white'], 'borderColor' => $C['frostBorder'], 'prefixIcon' => 'lock_outline_rounded', 'prefixIconColor' => $C['accentLt'], 'radius' => 16, 'flex' => 0], [], 'rCol'),
    'rNext'  => $node('Container', true, array_merge($style, ['gradient' => 1, 'gradFrom' => $C['pinkFrom'], 'gradTo' => $C['pinkTo'], 'gradDir' => 'to right', 'background' => $C['pink'], 'radius' => 30, 'padding' => 16, 'align' => 'center', 'flex' => 0, 'onTapAction' => 'core.register', 'onTapParams' => ['emailField' => 'email', 'passwordField' => 'password']]), ['rNextT'], 'rCol'),
    'rNextT' => $node('Text', false, ['text' => 'التالي', 'fontSize' => 16, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.app.next', 'maxLines' => 1], [], 'rNext'),

    // Already have an account → sign in.
    'rAlready'    => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['rAlreadyT', 'rAlreadyBtn'], 'ROOT'),
    'rAlreadyT'   => $node('Text', false, ['text' => 'لديك حساب بالفعل؟', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.screens.register.have_account', 'maxLines' => 1], [], 'rAlready'),
    'rAlreadyBtn' => $node('Text', false, ['text' => 'تسجيل الدخول', 'fontSize' => 14, 'fontWeight' => 700, 'color' => $C['accentLt'], 'align' => 'center', 'binding' => 't.app.login', 'maxLines' => 1, 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/login', 'mode' => 'push']], [], 'rAlready'),
];

// home — title row + search + welcome card. Transparent ROOT.
$homeWidgets = [
    'ROOT'      => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 16, 'gap' => 16, 'align' => 'stretch', 'flex' => 0]), ['topRow', 'search', 'card'], null),
    'topRow'    => $node('Row', true, ['gap' => 8, 'align' => 'center'], ['appName', 'bell'], 'ROOT'),
    'appName'   => $node('Text', false, ['text' => 'الرئيسية', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'right', 'binding' => 't.app.home', 'maxLines' => 1, 'flex' => 1], [], 'topRow'),
    'bell'      => $node('Icon', false, ['name' => 'notifications_none', 'size' => 24, 'color' => $C['white'], 'onTapAction' => 'core.navigate', 'onTapParams' => ['route' => '/notifications', 'mode' => 'push']], [], 'topRow'),
    'search'    => $node('TextField', false, ['fieldId' => 'home_search', 'placeholder' => 'بحث', 'tHint' => 'app.search', 'live' => false, 'fillColor' => $C['field'], 'radius' => 16, 'flex' => 0], [], 'ROOT'),
    'card'      => $node('Container', true, array_merge($style, ['background' => $C['card'], 'radius' => 16, 'padding' => 22, 'borderWidth' => 1, 'borderColor' => $C['cardBorder'], 'gap' => 10, 'align' => 'center']), ['cardIcon', 'cardTitle', 'cardSub'], 'ROOT'),
    'cardIcon'  => $node('Icon', false, ['name' => 'auto_awesome', 'size' => 30, 'color' => $C['accentLt']], [], 'card'),
    'cardTitle' => $node('Text', false, ['text' => 'أهلاً بك في تطبيقك', 'fontSize' => 16, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.screens.home.welcome_title', 'maxLines' => 0], [], 'card'),
    'cardSub'   => $node('Text', false, ['text' => 'ابدأ استكشاف كل المميزات', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.screens.home.welcome_subtitle', 'maxLines' => 0], [], 'card'),
];

// profile — RICH "Me" landing, COMPOSED from Studio primitives only (§5 of
// PACKAGE-DEFAULT-SCREENS.md), NO custom widget → Studio-safe (every
// type.resolvedName is in the locked resolver set; every binding is declared in
// core.currentUser):
//   • gradient avatar ring  = circular gradient Container (radius = ½ size)
//                             wrapping a circular Image (the doc's ring recipe).
//   • camera badge          = a Stack child with `pos:'bottom-right'` overlapping
//                             the avatar (pos is honoured only on a Stack child).
//   • name+flag+pencil / uid / bio+pencil + tappable menu cards.
$profileWidgets = array_merge(
    [
        'ROOT'        => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 16, 'gap' => 14, 'align' => 'stretch', 'flex' => 0]), ['topBar', 'scope', 'mSettings'], null),

        // Edit + refresh buttons at the top (justify flex-start → Start, which in
        // the RTL app is physically TOP-RIGHT), mirroring the native Me-landing
        // top bar. `core.editProfile` opens the name/bio edit sheet; `core.refresh`
        // re-fetches the live user source (+ a "تم التحديث" toast). Both actions
        // already ship in the Flutter app (appCoreActionParsers) and are declared
        // in `action_elements` below.
        'topBar'         => $node('Row', true, ['gap' => 8, 'justify' => 'flex-start', 'align' => 'center'], ['editBtn', 'refreshBtn'], 'ROOT'),
        'editBtn'        => $node('Container', true, array_merge($style, ['width' => 40, 'height' => 40, 'radius' => 20, 'background' => $C['frost'], 'borderWidth' => 1, 'borderColor' => $C['frostBorder'], 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'onTapAction' => 'core.editProfile']), ['editBtnIcon'], 'topBar'),
        'editBtnIcon'    => $node('Icon', false, ['name' => 'edit_rounded', 'size' => 20, 'color' => $C['white']], [], 'editBtn'),
        'refreshBtn'     => $node('Container', true, array_merge($style, ['width' => 40, 'height' => 40, 'radius' => 20, 'background' => $C['frost'], 'borderWidth' => 1, 'borderColor' => $C['frostBorder'], 'align' => 'center', 'valign' => 'center', 'flex' => 0, 'onTapAction' => 'core.refresh']), ['refreshBtnIcon'], 'topBar'),
        'refreshBtnIcon' => $node('Icon', false, ['name' => 'refresh_rounded', 'size' => 20, 'color' => $C['white']], [], 'refreshBtn'),

        'scope'       => $node('Scope', true, ['source' => 'core.currentUser'], ['header'], 'ROOT'),
        'header'      => $node('Container', true, ['background' => '#00000000', 'padding' => 8, 'gap' => 10, 'align' => 'center', 'flex' => 0], ['avatarBox', 'nameRow', 'uidRow', 'badgeRow', 'bioRow'], 'scope'),

        // Avatar: a FIXED-SIZE box → gradient ring + circular image + an
        // overlapping camera badge. The Stack MUST be wrapped in a 124×124
        // Container: a Stack has no width/height of its own (the Stac stack
        // parser ignores them), so the badge's `pos` (which Studio transforms
        // into a non-positioned `Align`) would expand the Stack to the full
        // screen width and fling the camera FAR from the circle. The fixed box
        // bounds the Align so the badge sits ON the ring edge.
        'avatarBox'   => $node('Container', true, ['width' => 124, 'height' => 124, 'align' => 'center', 'valign' => 'center'], ['avatarStack'], 'header'),
        'avatarStack' => $node('Stack', true, [], ['ring', 'camBtn'], 'avatarBox'),
        // Tapping the avatar (anywhere but the camera badge) opens MY full
        // profile as a Studio-designed screen (user_profile, editable in UTD
        // Studio) presented as a full dialog — the camera badge keeps changeAvatar.
        'ring'        => $node('Container', true, array_merge($style, ['width' => 124, 'height' => 124, 'radius' => 62, 'gradient' => 1, 'gradFrom' => $C['accent'], 'gradTo' => $C['pink'], 'gradDir' => 'to bottom right', 'padding' => 4, 'align' => 'center', 'valign' => 'center', 'onTapAction' => 'core.openDialog', 'onTapParams' => ['screen' => 'user_profile', 'style' => 'full']]), ['avatarImg'], 'avatarStack'),
        'avatarImg'   => $node('Image', false, ['src' => '', 'binding' => 'core.currentUser.avatar', 'width' => 116, 'height' => 116, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0], [], 'ring'),
        // pos:'top-left' → Studio maps left→Start, so in the RTL app Start=RIGHT
        // → the badge renders physically TOP-RIGHT, snug on the ring (matches the
        // LTP design). (Studio's LTR web preview mirrors it to top-left — the app
        // is the source of truth.)
        'camBtn'      => $node('Container', true, array_merge($style, ['width' => 34, 'height' => 34, 'radius' => 17, 'background' => $C['pink'], 'borderWidth' => 2, 'borderColor' => $C['white'], 'align' => 'center', 'valign' => 'center', 'pos' => 'top-left', 'onTapAction' => 'core.changeAvatar', 'onTapParams' => ['source' => 'gallery']]), ['camIcon'], 'avatarStack'),
        'camIcon'     => $node('Icon', false, ['name' => 'photo_camera_rounded', 'size' => 16, 'color' => $C['white']], [], 'camBtn'),

        // Name + flag + gender sign + edit pencil.
        'nameRow'     => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['name', 'flag', 'maleSign', 'femaleSign', 'namePencil'], 'header'),
        'name'        => $node('Text', false, ['text' => 'الملف الشخصي', 'binding' => 'core.currentUser.name', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
        'flag'        => $node('Image', false, ['src' => '', 'binding' => 'core.currentUser.flag', 'visibleBinding' => 'core.currentUser.flag', 'width' => 24, 'height' => 16, 'fit' => 'cover', 'radius' => 3], [], 'nameRow'),
        // Gender shown as a colored sign. UTD Studio's Craft→Stac transform DROPS
        // `visibleBinding`, so a gated Icon can't be hidden — instead bind a Text to
        // a per-gender source field that is the symbol for the matching gender and
        // an EMPTY string otherwise (an empty bound Text renders nothing). So only
        // the user's gender shows, in its own colour.
        'maleSign'    => $node('Text', false, ['text' => '', 'binding' => 'core.currentUser.maleSign', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#42A5F5', 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
        'femaleSign'  => $node('Text', false, ['text' => '', 'binding' => 'core.currentUser.femaleSign', 'fontSize' => 20, 'fontWeight' => 700, 'color' => '#EC407A', 'align' => 'center', 'maxLines' => 1], [], 'nameRow'),
        'namePencil'  => $node('Icon', false, ['name' => 'edit_rounded', 'size' => 16, 'color' => $C['accentLt'], 'onTapAction' => 'core.editProfile'], [], 'nameRow'),

        // UID + copy glyph. Tapping copy fires core.copy → copies the signed-in
        // user's uid to the clipboard (+ a "تم النسخ" toast), matching the native
        // Me-landing "ID: …" copy row.
        'uidRow'      => $node('Row', true, ['gap' => 4, 'justify' => 'center', 'align' => 'center', 'visibleBinding' => 'core.currentUser.uid'], ['uidLabel', 'uid', 'copyIcon'], 'header'),
        'uidLabel'    => $node('Text', false, ['text' => 'ID:', 'binding' => '', 'fontSize' => 13, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'uidRow'),
        'uid'         => $node('Text', false, ['text' => '', 'binding' => 'core.currentUser.uid', 'fontSize' => 13, 'fontWeight' => 600, 'color' => $C['muted'], 'align' => 'center', 'maxLines' => 1], [], 'uidRow'),
        'copyIcon'    => $node('Icon', false, ['name' => 'content_copy_rounded', 'size' => 14, 'color' => $C['muted'], 'onTapAction' => 'core.copy', 'onTapParams' => ['field' => 'uid']], [], 'uidRow'),

        // Level badges (wealth + charm) — graceful-empty: each is a bound Text
        // that stays '' until the backend (gifts/levels package) sends the level,
        // mirroring the native ProfileIdentity level chips. (The Craft→Stac
        // transform drops visibleBinding, so an empty bound Text — not a gated
        // pill — is how an absent badge stays hidden, like the gender signs.)
        'badgeRow'    => $node('Row', true, ['gap' => 8, 'justify' => 'center', 'align' => 'center'], ['wealthBadge', 'charmBadge'], 'header'),
        'wealthBadge' => $node('Text', false, ['text' => '', 'binding' => 'core.currentUser.wealthBadge', 'fontSize' => 12, 'fontWeight' => 700, 'color' => $C['accentLt'], 'align' => 'center', 'maxLines' => 1], [], 'badgeRow'),
        'charmBadge'  => $node('Text', false, ['text' => '', 'binding' => 'core.currentUser.charmBadge', 'fontSize' => 12, 'fontWeight' => 700, 'color' => '#FFB300', 'align' => 'center', 'maxLines' => 1], [], 'badgeRow'),

        // Bio + edit pencil.
        'bioRow'      => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['bio', 'bioPencil'], 'header'),
        'bio'         => $node('Text', false, ['text' => '', 'binding' => 'core.currentUser.bio', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['bioText'], 'align' => 'center', 'maxLines' => 0], [], 'bioRow'),
        'bioPencil'   => $node('Icon', false, ['name' => 'edit_rounded', 'size' => 14, 'color' => $C['accentLt'], 'onTapAction' => 'core.editProfile'], [], 'bioRow'),
    ],
    $mkTile('mSettings', 'settings_rounded', '#42A5F5', 'الإعدادات', 'core.navigate', ['route' => '/settings', 'mode' => 'push'], 'app.settings')
);

// settings — polished list matching the native design: an in-body app bar
// (back + title), then GROUPED frosted cards where each row is a TINTED ICON BOX
// + label + chevron. (Block List is intentionally omitted — it needs the block
// package, which isn't built yet.)
//
// Row helper: tinted icon box + label + chevron, tappable, parented to its card.
$mkSetRow = function (string $id, string $icon, string $tint, string $tintBg, string $label, string $tap, array $params, string $parent) use ($node, $C): array {
    return [
        $id        => $node('Container', true, ['background' => '#00000000', 'padMode' => 'sides', 'padL' => 12, 'padT' => 12, 'padR' => 12, 'padB' => 12, 'align' => 'stretch', 'flex' => 0, 'onTapAction' => $tap, 'onTapParams' => $params], [$id . 'R'], $parent),
        $id . 'R'  => $node('Row', true, ['gap' => 12, 'align' => 'center'], [$id . 'Bx', $id . 'Lb', $id . 'Ch'], $id),
        $id . 'Bx' => $node('Container', true, ['width' => 38, 'height' => 38, 'radius' => 11, 'background' => $tintBg, 'align' => 'center', 'valign' => 'center', 'flex' => 0], [$id . 'Ic'], $id . 'R'),
        $id . 'Ic' => $node('Icon', false, ['name' => $icon, 'size' => 20, 'color' => $tint], [], $id . 'Bx'),
        $id . 'Lb' => $node('Text', false, ['text' => $label, 'binding' => '', 'fontSize' => 15, 'fontWeight' => 500, 'color' => $C['white'], 'align' => 'right', 'maxLines' => 1, 'flex' => 1], [], $id . 'R'),
        $id . 'Ch' => $node('Icon', false, ['name' => 'chevron_left_rounded', 'size' => 20, 'color' => $C['muted']], [], $id . 'R'),
    ];
};
$divRow = fn (string $id, string $parent) => [$id => $node('Divider', false, ['color' => '#22FFFFFF', 'thickness' => 1], [], $parent)];
$cardBg = '#1FFFFFFF'; // frosted white (~12%) over the purple shell
$cardBd = '#2EFFFFFF';

$settingsWidgets = array_merge(
    [
        'ROOT'       => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 16, 'gap' => 16, 'align' => 'stretch', 'flex' => 0]), ['hdr', 'langCard', 'grpCard', 'logoutCard'], null),

        // In-body app bar: back + title.
        'hdr'        => $node('Row', true, ['gap' => 12, 'align' => 'center'], ['hdrBack', 'hdrTitle'], 'ROOT'),
        'hdrBack'    => $node('Icon', false, ['name' => 'arrow_back_rounded', 'size' => 24, 'color' => $C['white'], 'onTapAction' => 'core.back'], [], 'hdr'),
        'hdrTitle'   => $node('Text', false, ['text' => 'الإعدادات', 'binding' => 't.app.settings', 'fontSize' => 22, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'right', 'maxLines' => 1, 'flex' => 1], [], 'hdr'),

        // Language — standalone frosted card.
        'langCard'   => $node('Container', true, array_merge($style, ['background' => $cardBg, 'borderWidth' => 1, 'borderColor' => $cardBd, 'radius' => 16, 'padding' => 4, 'align' => 'stretch', 'flex' => 0]), ['rLang'], 'ROOT'),

        // Grouped frosted card (rows + dividers).
        'grpCard'    => $node('Container', true, array_merge($style, ['background' => $cardBg, 'borderWidth' => 1, 'borderColor' => $cardBd, 'radius' => 16, 'padding' => 4, 'align' => 'stretch', 'flex' => 0]), ['rPriv', 'd1', 'rTerms', 'd2', 'rContact', 'd3', 'rAbout', 'd4', 'rDelete'], 'ROOT'),

        // Logout — standalone frosted card (destructive).
        'logoutCard' => $node('Container', true, array_merge($style, ['background' => $cardBg, 'borderWidth' => 1, 'borderColor' => $cardBd, 'radius' => 16, 'padMode' => 'sides', 'padL' => 14, 'padT' => 15, 'padR' => 14, 'padB' => 15, 'align' => 'center', 'flex' => 0, 'onTapAction' => 'core.logout', 'onTapParams' => ['confirm' => true]]), ['logoutT'], 'ROOT'),
        'logoutT'    => $node('Text', false, ['text' => 'تسجيل الخروج', 'binding' => 't.app.logout', 'fontSize' => 15, 'fontWeight' => 700, 'color' => $C['red'], 'align' => 'center', 'maxLines' => 1], [], 'logoutCard'),
    ],
    $mkSetRow('rLang', 'language_rounded', '#26C6DA', '#3326C6DA', 'اللغة', 'core.navigate', ['route' => '/language-screen', 'mode' => 'push'], 'langCard'),
    $mkSetRow('rPriv', 'shield_rounded', '#66BB6A', '#3366BB6A', 'سياسة الخصوصية', 'core.navigate', ['route' => '/page/privacy', 'mode' => 'push'], 'grpCard'),
    $divRow('d1', 'grpCard'),
    $mkSetRow('rTerms', 'description_rounded', '#26A69A', '#3326A69A', 'شروط الاستخدام', 'core.navigate', ['route' => '/page/terms', 'mode' => 'push'], 'grpCard'),
    $divRow('d2', 'grpCard'),
    $mkSetRow('rContact', 'support_agent_rounded', '#42A5F5', '#3342A5F5', 'تواصل معنا', 'core.navigate', ['route' => '/contact-us', 'mode' => 'push'], 'grpCard'),
    $divRow('d3', 'grpCard'),
    $mkSetRow('rAbout', 'info_rounded', '#7C4DFF', '#337C4DFF', 'عن التطبيق', 'core.navigate', ['route' => '/page/about', 'mode' => 'push'], 'grpCard'),
    $divRow('d4', 'grpCard'),
    $mkSetRow('rDelete', 'delete_outline_rounded', '#FF5A6E', '#33FF5A6E', 'حذف الحساب', 'core.navigate', ['route' => '/delete', 'mode' => 'push'], 'grpCard'),
);

// audio — bottom-nav tab placeholder for the audio-room feature (Eng-Hazem is
// building the real package). Marked nav=true so the tab shows in the shell; the
// screen is a themed "coming soon" until the audio-room package ships its own
// nav screen, at which point this can be removed.
$audioWidgets = [
    'ROOT'   => $node('Container', true, array_merge($style, ['background' => $C['screen'], 'padding' => 24, 'gap' => 12, 'align' => 'center', 'flex' => 0]), ['aIcon', 'aTitle', 'aSub'], null),
    'aIcon'  => $node('Icon', false, ['name' => 'graphic_eq', 'size' => 64, 'color' => $C['accentLt']], [], 'ROOT'),
    'aTitle' => $node('Text', false, ['text' => 'الغرف الصوتية', 'fontSize' => 20, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.app.audio_rooms', 'maxLines' => 1], [], 'ROOT'),
    'aSub'   => $node('Text', false, ['text' => 'قريباً 🎧', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'center', 'binding' => 't.app.coming_soon', 'maxLines' => 0], [], 'ROOT'),
];

// add_information — server-driven onboarding (complete profile): avatar upload +
// full name + gender selector + age wheel + submit. Decomposed into primitives
// (custom node types crash the Studio editor); the stateful bits use custom
// actions (core.selectGender / core.pickAge / core.completeProfile) + the
// `core.onboarding` draft source. Gender selection + chosen age render via bound
// Text (the maleSign/femaleSign empty-driven trick — visibleBinding is dropped).
$addInfoWidgets = [
    'ROOT'   => $node('Container', true, array_merge($style, ['background' => '#00000000', 'padMode' => 'sides', 'padL' => 22, 'padT' => 48, 'padR' => 22, 'padB' => 22, 'gap' => 16, 'align' => 'stretch', 'flex' => 0]), ['aiHero', 'aiForm'], null),

    // Hero — title + subtitle.
    'aiHero'  => $node('Container', true, ['background' => '#00000000', 'gap' => 6, 'align' => 'stretch', 'flex' => 0], ['aiTitle', 'aiSub'], 'ROOT'),
    'aiTitle' => $node('Text', false, ['text' => 'مرحباً 👋', 'fontSize' => 30, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'right', 'binding' => 't.screens.add_info.title', 'maxLines' => 1], [], 'aiHero'),
    'aiSub'   => $node('Text', false, ['text' => 'أكمل ملفك الشخصي للبدء', 'fontSize' => 14, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'right', 'binding' => 't.screens.add_info.subtitle', 'maxLines' => 0], [], 'aiHero'),

    // Form so core.completeProfile reads the name field via the form scope.
    'aiForm'  => $node('Form', true, [], ['aiCol'], 'ROOT'),
    'aiCol'   => $node('Container', true, ['background' => '#00000000', 'gap' => 14, 'align' => 'stretch', 'flex' => 0], ['avatarCard', 'nameLabel', 'nameField', 'genderLabel', 'genderRow', 'ageLbl', 'ageCard', 'submitBtn'], 'aiForm'),

    // Avatar upload card: "رفع صورة" (right) + tappable avatar w/ camera badge (left).
    'avatarCard'  => $node('Container', true, array_merge($style, ['background' => $C['frost'], 'radius' => 14, 'padMode' => 'sides', 'padL' => 16, 'padT' => 14, 'padR' => 16, 'padB' => 14, 'borderWidth' => 1, 'borderColor' => $C['frostBorder'], 'align' => 'stretch', 'flex' => 0]), ['avatarRow'], 'aiCol'),
    'avatarRow'   => $node('Row', true, ['gap' => 12, 'align' => 'center'], ['avatarLbl', 'avatarBox'], 'avatarCard'),
    'avatarLbl'   => $node('Text', false, ['text' => 'رفع صورة', 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['muted'], 'align' => 'right', 'binding' => 't.app.upload_picture', 'maxLines' => 1, 'flex' => 1], [], 'avatarRow'),
    'avatarBox'   => $node('Container', true, ['width' => 56, 'height' => 56, 'align' => 'center', 'valign' => 'center', 'flex' => 0], ['avatarStack'], 'avatarRow'),
    'avatarStack' => $node('Stack', true, [], ['avatarScope', 'avCamBtn'], 'avatarBox'),
    'avatarScope' => $node('Scope', true, ['source' => 'core.currentUser'], ['avatarImg'], 'avatarStack'),
    'avatarImg'   => $node('Image', false, ['src' => '', 'binding' => 'core.currentUser.avatar', 'width' => 56, 'height' => 56, 'fit' => 'cover', 'shape' => 'circle', 'radius' => 0, 'onTapAction' => 'core.changeAvatar', 'onTapParams' => ['source' => 'gallery']], [], 'avatarScope'),
    'avCamBtn'    => $node('Container', true, array_merge($style, ['width' => 22, 'height' => 22, 'radius' => 11, 'background' => $C['pink'], 'borderWidth' => 2, 'borderColor' => $C['white'], 'align' => 'center', 'valign' => 'center', 'pos' => 'bottom-left', 'flex' => 0, 'onTapAction' => 'core.changeAvatar', 'onTapParams' => ['source' => 'gallery']]), ['avCamIcon'], 'avatarStack'),
    'avCamIcon'   => $node('Icon', false, ['name' => 'photo_camera_rounded', 'size' => 12, 'color' => $C['white']], [], 'avCamBtn'),

    // Full name.
    'nameLabel' => $node('Text', false, ['text' => 'الاسم الكامل', 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['muted'], 'align' => 'right', 'binding' => 't.app.full_name', 'maxLines' => 1], [], 'aiCol'),
    'nameField' => $node('TextField', false, ['fieldId' => 'name', 'placeholder' => 'الاسم الكامل', 'tHint' => 'app.full_name', 'live' => true, 'fillColor' => $C['frost'], 'textColor' => $C['white'], 'borderColor' => $C['frostBorder'], 'radius' => 14, 'flex' => 0], [], 'aiCol'),

    // Gender — two tappable cards (ذكر right / أنثى left); bound check = selection.
    'genderLabel' => $node('Text', false, ['text' => 'جنسك', 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['muted'], 'align' => 'right', 'binding' => 't.app.your_gender', 'maxLines' => 1], [], 'aiCol'),
    'genderRow'   => $node('Row', true, ['gap' => 12, 'align' => 'center'], ['maleCard', 'femaleCard'], 'aiCol'),
    'maleCard'    => $node('Container', true, array_merge($style, ['background' => $C['frost'], 'radius' => 14, 'padMode' => 'sides', 'padL' => 14, 'padT' => 16, 'padR' => 14, 'padB' => 16, 'borderWidth' => 1, 'borderColor' => $C['frostBorder'], 'align' => 'center', 'flex' => 1, 'onTapAction' => 'core.selectGender', 'onTapParams' => ['gender' => 'male']]), ['maleInner'], 'genderRow'),
    'maleInner'   => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['maleCheck', 'maleLbl', 'maleIcon'], 'maleCard'),
    'maleCheck'   => $node('Text', false, ['text' => '', 'binding' => 'core.onboarding.genderMaleCheck', 'fontSize' => 16, 'fontWeight' => 700, 'color' => '#42A5F5', 'align' => 'center', 'maxLines' => 1], [], 'maleInner'),
    'maleLbl'     => $node('Text', false, ['text' => 'ذكر', 'fontSize' => 15, 'fontWeight' => 600, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.app.male', 'maxLines' => 1], [], 'maleInner'),
    'maleIcon'    => $node('Icon', false, ['name' => 'male', 'size' => 18, 'color' => '#42A5F5'], [], 'maleInner'),
    'femaleCard'  => $node('Container', true, array_merge($style, ['background' => $C['frost'], 'radius' => 14, 'padMode' => 'sides', 'padL' => 14, 'padT' => 16, 'padR' => 14, 'padB' => 16, 'borderWidth' => 1, 'borderColor' => $C['frostBorder'], 'align' => 'center', 'flex' => 1, 'onTapAction' => 'core.selectGender', 'onTapParams' => ['gender' => 'female']]), ['femaleInner'], 'genderRow'),
    'femaleInner' => $node('Row', true, ['gap' => 6, 'justify' => 'center', 'align' => 'center'], ['femaleCheck', 'femaleLbl', 'femaleIcon'], 'femaleCard'),
    'femaleCheck' => $node('Text', false, ['text' => '', 'binding' => 'core.onboarding.genderFemaleCheck', 'fontSize' => 16, 'fontWeight' => 700, 'color' => '#EC407A', 'align' => 'center', 'maxLines' => 1], [], 'femaleInner'),
    'femaleLbl'   => $node('Text', false, ['text' => 'أنثى', 'fontSize' => 15, 'fontWeight' => 600, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.app.female', 'maxLines' => 1], [], 'femaleInner'),
    'femaleIcon'  => $node('Icon', false, ['name' => 'female', 'size' => 18, 'color' => '#EC407A'], [], 'femaleInner'),

    // Age — tappable card → wheel; bound age + empty-driven placeholder + chevron.
    'ageLbl'      => $node('Text', false, ['text' => 'عمرك', 'fontSize' => 14, 'fontWeight' => 500, 'color' => $C['muted'], 'align' => 'right', 'binding' => 't.app.your_age', 'maxLines' => 1], [], 'aiCol'),
    'ageCard'     => $node('Container', true, array_merge($style, ['background' => $C['frost'], 'radius' => 14, 'padMode' => 'sides', 'padL' => 16, 'padT' => 16, 'padR' => 16, 'padB' => 16, 'borderWidth' => 1, 'borderColor' => $C['frostBorder'], 'align' => 'stretch', 'flex' => 0, 'onTapAction' => 'core.pickAge']), ['ageRow'], 'aiCol'),
    'ageRow'      => $node('Row', true, ['gap' => 8, 'align' => 'center'], ['ageTextWrap', 'ageChevron'], 'ageCard'),
    'ageTextWrap' => $node('Row', true, ['gap' => 0, 'justify' => 'flex-start', 'align' => 'center', 'flex' => 1], ['ageValue', 'agePlaceholder'], 'ageRow'),
    'ageValue'    => $node('Text', false, ['text' => '', 'binding' => 'core.onboarding.ageLabel', 'fontSize' => 15, 'fontWeight' => 600, 'color' => $C['white'], 'align' => 'right', 'maxLines' => 1], [], 'ageTextWrap'),
    'agePlaceholder' => $node('Text', false, ['text' => '', 'binding' => 'core.onboarding.ageEmptyLabel', 'fontSize' => 15, 'fontWeight' => 400, 'color' => $C['muted'], 'align' => 'right', 'maxLines' => 1], [], 'ageTextWrap'),
    'ageChevron'  => $node('Icon', false, ['name' => 'expand_more_rounded', 'size' => 22, 'color' => $C['muted']], [], 'ageRow'),

    // Submit (pink gradient CTA) → core.completeProfile (reads name + draft).
    'submitBtn' => $node('Container', true, array_merge($style, ['gradient' => 1, 'gradFrom' => $C['pinkFrom'], 'gradTo' => $C['pinkTo'], 'gradDir' => 'to right', 'background' => $C['pink'], 'radius' => 30, 'padding' => 16, 'align' => 'center', 'flex' => 0, 'onTapAction' => 'core.completeProfile', 'onTapParams' => ['nameField' => 'name']]), ['submitT'], 'aiCol'),
    'submitT'   => $node('Text', false, ['text' => 'إرسال', 'fontSize' => 16, 'fontWeight' => 700, 'color' => $C['white'], 'align' => 'center', 'binding' => 't.app.submit', 'maxLines' => 1], [], 'submitBtn'),
];

return [
    'key'     => 'core',
    'name'    => 'Core',
    'icon'    => 'settings',
    'screens' => ['intro', 'login', 'register', 'add_information', 'forgot_password', 'home', 'audio', 'profile', 'settings'],

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
        ['key' => 'isMale',   'label' => 'ذكر؟',  'type' => 'string', 'screen' => 'profile'],
        ['key' => 'isFemale', 'label' => 'أنثى؟', 'type' => 'string', 'screen' => 'profile'],
        ['key' => 'maleSign',   'label' => 'رمز ذكر',  'type' => 'string', 'screen' => 'profile'],
        ['key' => 'femaleSign', 'label' => 'رمز أنثى', 'type' => 'string', 'screen' => 'profile'],
        ['key' => 'wealthBadge', 'label' => 'شارة الثراء',   'type' => 'string', 'screen' => 'profile'],
        ['key' => 'charmBadge',  'label' => 'شارة الجاذبية', 'type' => 'string', 'screen' => 'profile'],
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
                ['key' => 'isMale',   'label' => 'ذكر؟',  'type' => 'string'],
                ['key' => 'isFemale', 'label' => 'أنثى؟', 'type' => 'string'],
                ['key' => 'maleSign',   'label' => 'رمز ذكر',  'type' => 'string'],
                ['key' => 'femaleSign', 'label' => 'رمز أنثى', 'type' => 'string'],
                ['key' => 'wealthBadge', 'label' => 'شارة الثراء',   'type' => 'string'],
                ['key' => 'charmBadge',  'label' => 'شارة الجاذبية', 'type' => 'string'],
            ],
        ],
        // App-level branding (logo / name / tagline) for server-driven screens
        // such as the splash. Resolved on the client by `registerCoreAppSource()`
        // (flutter/lib/studio_glue/sources/core_stac_sources.dart). The VALUES are
        // owned by the base/web admin (Config: app_logo / app_name / app_tagline);
        // the Studio only reads these attributes for its binding picker.
        [
            'key'      => 'core.app',
            'label'    => 'بيانات التطبيق',
            'provides' => [
                ['key' => 'logo',    'label' => 'الشعار',     'type' => 'image_url'],
                ['key' => 'name',    'label' => 'اسم التطبيق', 'type' => 'string'],
                ['key' => 'tagline', 'label' => 'الشعار النصّي', 'type' => 'string'],
            ],
        ],
        // Onboarding draft (add_information screen): the in-progress gender/age
        // picks. Resolved on the client by `registerCoreOnboardingSource()`
        // (flutter/lib/studio_glue/sources/core_stac_sources.dart) from the
        // CacheManager draft; the *Check fields are empty-driven selection marks.
        [
            'key'      => 'core.onboarding',
            'label'    => 'مسوّدة إكمال الملف',
            'provides' => [
                ['key' => 'genderMaleCheck',   'label' => 'علامة ذكر',     'type' => 'string'],
                ['key' => 'genderFemaleCheck', 'label' => 'علامة أنثى',    'type' => 'string'],
                ['key' => 'ageLabel',          'label' => 'العمر',         'type' => 'string'],
                ['key' => 'ageEmptyLabel',     'label' => 'نص نائب للعمر', 'type' => 'string'],
                ['key' => 'gender',            'label' => 'الجنس',         'type' => 'string'],
                ['key' => 'birthday',          'label' => 'تاريخ الميلاد', 'type' => 'string'],
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

        // ── add_information (onboarding) ──
        [
            'key' => 'select_gender', 'label' => 'اختيار الجنس',
            'produces' => 'core.selectGender', 'default_shape' => 'button', 'screen' => 'add_information',
            'params' => [
                ['key' => 'gender', 'label' => 'الجنس (male/female)', 'type' => 'string'],
            ],
        ],
        [
            'key' => 'pick_age', 'label' => 'اختيار العمر',
            'produces' => 'core.pickAge', 'default_shape' => 'button', 'screen' => 'add_information',
        ],
        [
            'key' => 'complete_profile', 'label' => 'إرسال (إكمال الملف)',
            'produces' => 'core.completeProfile', 'default_shape' => 'button', 'screen' => 'add_information',
            'params' => [
                ['key' => 'nameField', 'label' => 'حقل الاسم', 'type' => 'field_ref'],
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
        // فتح صفحة البروفايل الكامل (غلاف + عدّادات) — العميل بيحطّه كـ onTap على الصورة.
        [
            'key' => 'open_profile', 'label' => 'فتح البروفايل الكامل',
            'produces' => 'core.openProfile', 'default_shape' => 'image', 'screen' => 'profile',
            'params' => [
                ['key' => 'userId', 'label' => 'معرّف المستخدم (فاضي = أنا)', 'type' => 'int'],
            ],
        ],
        // فتح مودال تعديل الاسم/النبذة في مكانه (بدل الانتقال لصفحة) — onTap على القلم.
        [
            'key' => 'edit_profile', 'label' => 'تعديل الملف (مودال)',
            'produces' => 'core.editProfile', 'default_shape' => 'button', 'screen' => 'profile',
        ],
        // تحديث: إعادة جلب بيانات المستخدم الحيّة (مع توست "تم التحديث") — زر أعلى البروفايل.
        [
            'key' => 'refresh', 'label' => 'تحديث',
            'produces' => 'core.refresh', 'default_shape' => 'button', 'screen' => 'profile',
        ],
        // نسخ: نسخ قيمة (المعرّف الأبدي افتراضيًا) للحافظة + توست "تم النسخ".
        [
            'key' => 'copy', 'label' => 'نسخ',
            'produces' => 'core.copy', 'default_shape' => 'button', 'screen' => 'profile',
            'params' => [
                ['key' => 'field', 'label' => 'الحقل (uid افتراضيًا)', 'type' => 'string'],
                ['key' => 'value', 'label' => 'قيمة ثابتة (اختياري)', 'type' => 'string'],
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
        // الرجوع للخلف (يدعمه محرّك الـ SDK: core.back).
        [
            'key' => 'back', 'label' => 'رجوع',
            'produces' => 'core.back', 'default_shape' => 'button', 'screen' => '*',
            'params' => [
                ['key' => 'fallback', 'label' => 'لو مفيش رجوع روح لـ', 'type' => 'route'],
            ],
        ],
        // ── dialogs (any screen) — يدعمها محرّك الـ SDK ──
        // فتح شاشة UTD Studio كـ dialog/sheet/full فوق الشاشة الحالية (مش navigation).
        [
            'key' => 'open_dialog', 'label' => 'فتح نافذة (Dialog)',
            'produces' => 'core.openDialog', 'default_shape' => 'button', 'screen' => '*',
            'params' => [
                ['key' => 'screen',            'label' => 'الشاشة',                  'type' => 'route'],
                ['key' => 'style',             'label' => 'النمط (center/sheet/full)', 'type' => 'string'],
                ['key' => 'height',            'label' => 'الارتفاع % (للـ sheet)',    'type' => 'int'],
                ['key' => 'expandable',        'label' => 'قابلة للتمدد (sheet)',      'type' => 'bool'],
                ['key' => 'barrierDismissible', 'label' => 'تُغلق باللمس بالخارج',      'type' => 'bool'],
            ],
        ],
        [
            'key' => 'close_dialog', 'label' => 'إغلاق النافذة',
            'produces' => 'core.closeDialog', 'default_shape' => 'button', 'screen' => '*',
        ],
    ],

    // ── Ready-to-edit default screen layouts (seeded by UTD Studio on Sync) ──
    'default_screens' => [
        [
            'name'         => 'intro',
            'label'        => 'الترحيب',
            'icon'         => '👋',
            'version'      => '1.2.1',
            'nav'          => false,
            'navIcon'      => 'waving_hand',
            'order'        => 0,
            'role'         => 'onboarding.intro',
            'requiresAuth' => false,
            'showOnce'     => true,
            'opens'        => null,
            // Full-bleed auth gradient fills the WHOLE screen (behind the content),
            // so a short page no longer leaves a flat-colour gap below.
            'chrome'       => [
                'appBar'     => ['enabled' => false, 'title' => 'الترحيب', 'bg' => $C['authBg'], 'actions' => []],
                'background'  => ['type' => 'gradient', 'gradFrom' => $C['authFrom'], 'gradTo' => $C['authTo'], 'gradDir' => 'to bottom right'],
            ],
            'widgets'      => $introWidgets,
        ],
        [
            'name'         => 'login',
            'label'        => 'تسجيل الدخول',
            'icon'         => '🔑',
            'version'      => '2.3.1',
            'nav'          => false,
            'navIcon'      => 'person',
            'order'        => 1,
            'role'         => 'auth.login',
            'requiresAuth' => false,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => [
                'appBar'     => ['enabled' => false, 'title' => 'تسجيل الدخول', 'bg' => $C['authBg'], 'actions' => []],
                'background'  => ['type' => 'gradient', 'gradFrom' => $C['authFrom'], 'gradTo' => $C['authTo'], 'gradDir' => 'to bottom right'],
            ],
            'widgets'      => $loginWidgets,
        ],
        [
            'name'         => 'register',
            'label'        => 'إنشاء حساب',
            'icon'         => '📝',
            'version'      => '1.3.1',
            'nav'          => false,
            'navIcon'      => 'person_add',
            'order'        => 3,
            'role'         => 'auth.register',
            'requiresAuth' => false,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => [
                'appBar'     => ['enabled' => false, 'title' => 'إنشاء حساب', 'bg' => $C['authBg'], 'actions' => []],
                'background'  => ['type' => 'gradient', 'gradFrom' => $C['authFrom'], 'gradTo' => $C['authTo'], 'gradDir' => 'to bottom right'],
            ],
            'widgets'      => $registerWidgets,
        ],
        [
            'name'         => 'add_information',
            'label'        => 'إكمال الملف',
            'icon'         => '🧩',
            'version'      => '1.0.0',
            'nav'          => false,
            'navIcon'      => 'badge',
            'order'        => 4,
            'role'         => 'onboarding.add_info',
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => [
                'appBar'     => ['enabled' => false, 'title' => 'إكمال الملف', 'bg' => $C['authBg'], 'actions' => []],
                'background'  => ['type' => 'gradient', 'gradFrom' => $C['authFrom'], 'gradTo' => $C['authTo'], 'gradDir' => 'to bottom right'],
            ],
            'widgets'      => $addInfoWidgets,
        ],
        [
            'name'         => 'home',
            'label'        => 'الرئيسية',
            'icon'         => '🏠',
            'version'      => '1.7.0',
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
            'version'      => '1.7.0',
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
            'version'      => '1.11.0',
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
            'version'      => '1.7.2',
            // Removed from the bottom nav (owner's request) — it's opened from the
            // profile's "الإعدادات" card (core.navigate → /settings) instead.
            'nav'          => false,
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
