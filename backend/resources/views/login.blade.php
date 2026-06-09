<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}" dir="{{ app()->getLocale() === 'ar' ? 'rtl' : 'ltr' }}">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <title>{{ config('admin.title') }} | {{ trans('admin.login') }}</title>
    <meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@300;400;700&display=swap" rel="stylesheet">

    @if(!is_null($favicon = Admin::favicon()))
        <link rel="shortcut icon" href="{{$favicon}}">
    @endif
    <link rel="stylesheet" href="{{ asset('css/login.css') }}">
    <style>
        :root {
            --primary-color: {{ config('themes.primaryColor') ?: '#2563eb' }};
            --secondary-color: {{ config('themes.secondaryColor') ?: '#1f2937' }};
            --text-primary-color: {{ config('themes.textPrimaryColor') ?: '#ffffff' }};
            --text-secondary-color: {{ config('themes.textSecondaryColor') ?: '#9ca3af' }};
            --box-background-color: {{ config('themes.boxBackgroundColor') ?: '#ffffff' }};
            --table-background-color: {{ config('themes.tableBackGroundColor') ?: '#f9fafb' }};
            --background-image: {{ config('themes.backgroundImage') ?: 'none' }};
            --brand_background-image: url({{ getImagePath(config('themes.brandBackgroundImage')) ?: '' }});
            --second-alpha: rgba(31, 41, 55, 0.1);
            --primary-hover-alpha: rgba(37, 99, 235, 0.1);
            --scroll-second-color: rgba(255, 255, 255, 0.8);
            --scroll-first-color: rgba(37, 99, 235, 0.2);

            --inverse-color: #ffffff;
            --inverse-box-color: #1f2937;
            --success-button: linear-gradient(135deg, #10b981 0%, #059669 100%);
            --primary-button: linear-gradient(135deg, #2563eb 0%, #1d4ed8 100%);

            --white: #ffffff;
            --off-white: #faf9f6;
            --gray-800: #1f2937;
            --gray-700: #374151;
            --gray-50: #f9fafb;
            --gray-200: #e5e7eb;
            --gray-300: #d1d5db;
            --gray-900: #111827;

            --sidebar-width: 280px;
            --header-height: 70px;
            --border-radius: 12px;
            --shadow-sm: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
            --shadow-md: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
            --shadow-lg: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
            --transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);

            --gradient-primary: linear-gradient(90deg, var(--secondary-color) 0%, var(--primary-color) 100%);
            --gradient-vertical-primary: linear-gradient(180deg, var(--primary-color) 0%, var(--secondary-color) 100%);
        }
    </style>
</head>

<body class="login-body" data-loading-text="{{ app()->getLocale() === 'ar' ? 'جاري تسجيل الدخول...' : 'Signing in...' }}">
@php
    $logo = App\Models\Setting::where('key', 'app_logo')->first();
    $logo_url = $logo?->value;
    $logo_src = empty($logo) ? asset('images/app-logo.png') : getImagePath($logo_url);
    $isAr = app()->getLocale() === 'ar';
    $t = function (string $key, string $fallback) {
        $fullKey = 'dashboard.' . $key;
        $value = __($fullKey);
        return $value === $fullKey ? $fallback : $value;
    };
    $strings = [
        'welcome_title'   => $t('login.title', $isAr ? 'مرحباً بك!' : 'Welcome back!'),
        'welcome_sub'     => $t('login.subtitle', $isAr ? 'سجل دخولك للوصول إلى لوحة التحكم الخاصة بك' : 'Sign in to access your dashboard'),
        'feature_secure'  => $t('login.features.secure', $isAr ? 'تسجيل دخول آمن ومشفّر' : 'Secure, encrypted login'),
        'feature_fast'    => $t('login.features.fast', $isAr ? 'وصول سريع لجميع الميزات' : 'Fast access to all features'),
        'feature_global'  => $t('login.features.global', $isAr ? 'إدارة شاملة من أي مكان' : 'Manage everything from anywhere'),
        'form_title'      => $t('login.form_title', $isAr ? 'تسجيل الدخول' : 'Sign in'),
        'form_sub'        => $t('login.form_subtitle', $isAr ? 'أدخل بياناتك للوصول إلى حسابك' : 'Enter your details to continue'),
        'forgot'          => $t('login.forgot', $isAr ? 'نسيت كلمة المرور؟' : 'Forgot password?'),
        'reset'           => $t('login.reset', $isAr ? 'إعادة تعيين كلمة المرور' : 'Reset your password'),
        'or'              => $t('login.or', $isAr ? 'أو' : 'OR'),
        'loading'         => $t('login.loading', $isAr ? 'جاري تسجيل الدخول...' : 'Signing in...'),
    ];
@endphp

    <div class="bg-animation">
        <div class="shape shape1"></div>
        <div class="shape shape2"></div>
        <div class="shape shape3"></div>
    </div>

    <div class="login-container">
        <div class="branding-side">
            <div class="logo-container">
                <div class="logo-icon">
                    <img src="{{ $logo_src }}" alt="{{ config('app.name') }}">
                </div>
                <h1 class="brand-title">{{ $strings['welcome_title'] }}</h1>
                <p class="brand-subtitle">{{ $strings['welcome_sub'] }}</p>
            </div>

            <div class="features">
                <div class="feature-item">
                    <span class="feature-icon">🔒</span>
                    <span>{{ $strings['feature_secure'] }}</span>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">⚡</span>
                    <span>{{ $strings['feature_fast'] }}</span>
                </div>
                <div class="feature-item">
                    <span class="feature-icon">🌐</span>
                    <span>{{ $strings['feature_global'] }}</span>
                </div>
            </div>
        </div>

        <div class="form-side">
            <div class="form-header">
                <h2 class="form-title">{{ $strings['form_title'] }}</h2>
                <p class="form-subtitle">{{ $strings['form_sub'] }}</p>
            </div>

            @if($errors->any())
                <div class="alert">
                    <span>⚠️</span>
                    <div>
                        @foreach($errors->all() as $message)
                            <div>{{ $message }}</div>
                        @endforeach
                    </div>
                </div>
            @endif

            <form action="{{ admin_url('login') }}" method="post" id="loginForm">
                <div class="form-group">
                    <label class="form-label" for="username">{{ trans('admin.username') }}</label>
                    <div class="input-wrapper">
                        <input
                            id="username"
                            type="text"
                            class="form-input"
                            name="username"
                            placeholder="{{ trans('admin.username') }}"
                            value="{{ old('username') }}"
                            required
                        >
                        <span class="input-icon">👤</span>
                    </div>
                    @if($errors->has('username'))
                        @foreach($errors->get('username') as $message)
                            <div class="error-text">{{ $message }}</div>
                        @endforeach
                    @endif
                    <input type="hidden" name="url" value="{{ @$test }}">
                </div>

                <div class="form-group">
                    <label class="form-label" for="passwordInput">{{ trans('admin.password') }}</label>
                    <div class="input-wrapper">
                        <input
                            id="passwordInput"
                            type="password"
                            class="form-input"
                            name="password"
                            placeholder="{{ trans('admin.password') }}"
                            required
                        >
                        <span class="input-icon">🔒</span>
                        <button type="button" class="password-toggle" data-toggle="password" aria-label="Toggle password">👁️</button>
                    </div>
                    @if($errors->has('password'))
                        @foreach($errors->get('password') as $message)
                            <div class="error-text">{{ $message }}</div>
                        @endforeach
                    @endif
                </div>

                <div class="form-options">
                    @if(config('admin.auth.remember'))
                        <label class="checkbox-wrapper" for="remember">
                            <input type="checkbox" id="remember" name="remember" value="1" {{ (!old('username') || old('remember')) ? 'checked' : '' }}>
                            <span>{{ __('dashboard.login.remember') }}</span>
                        </label>
                    @endif
                    <a href="#" class="forgot-link">{{ $strings['forgot'] }}</a>
                </div>

                <input type="hidden" name="_token" value="{{ csrf_token() }}">
                <button type="submit" class="login-btn">
                    <span>{{ trans('admin.login') }}</span>
                    <span>→</span>
                </button>


                <div class="language-selector">
                    <button type="button" class="lang-btn {{ $current === 'ar' ? 'active' : '' }}" data-locale="ar">العربية</button>
                    <button type="button" class="lang-btn {{ $current === 'en' ? 'active' : '' }}" data-locale="en">English</button>
                </div>


            </form>
        </div>
    </div>

    <div class="rights text-center">{{ __('dashboard.login.rights') . config('app.name') }}</div>

<script>
    (function () {
        const csrfToken = document.querySelector('input[name="_token"]')?.value;
        const passwordInput = document.getElementById('passwordInput');
        const toggleBtn = document.querySelector('[data-toggle="password"]');

        if (toggleBtn && passwordInput) {
            toggleBtn.addEventListener('click', function () {
                const isHidden = passwordInput.type === 'password';
                passwordInput.type = isHidden ? 'text' : 'password';
                this.textContent = isHidden ? '🙈' : '👁️';
            });
        }

        const form = document.getElementById('loginForm');
        if (form) {
            const submitBtn = form.querySelector('.login-btn');
            form.addEventListener('submit', function () {
                if (!submitBtn) return;
                submitBtn.disabled = true;
                const loadingText = document.body.dataset.loadingText || '{{ $strings['loading'] }}';
                submitBtn.innerHTML = '<span>' + loadingText + '</span><span>⏳</span>';
            });
        }

        const langButtons = document.querySelectorAll('.lang-btn');
        langButtons.forEach(function (btn) {
            btn.addEventListener('click', function () {
                const locale = this.dataset.locale;
                if (!locale || locale === '{{ $current }}' || !csrfToken) {
                    return;
                }

                fetch("{{ admin_url('/locale') }}", {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                        'X-CSRF-TOKEN': csrfToken
                    },
                    body: new URLSearchParams({ locale: locale })
                }).then(function () {
                    window.location.reload();
                });
            });
        });
    })();
</script>
</body>
</html>
