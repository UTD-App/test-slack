<?php

namespace App\Providers;

use App\Contracts\NotificationSender;
use App\Facades\EmailTemplates;
use App\Models\EmailTemplate;
use App\Models\MenuItem;
use App\Models\Package;
use App\Models\User;
use App\Observers\MenuItemObserver;
use App\Observers\PackageObserver;
use App\Services\FirebaseConfigService;
use App\Support\Notifications\NotificationMessage;
use App\Services\MenuService;
use App\Services\PackageRegistry;
use App\Services\ProfileContributorRegistry;
use App\Services\RoleService;
use App\Services\SettingService;
use App\Services\StorageConfigService;
use App\Services\TranslationLoader;
use App\Services\UserDataService;
use App\Services\UserSettingService;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Force HTTPS only in production; local dev runs over plain HTTP
        // (php artisan serve), so forcing https there breaks redirects/assets.
        if ($this->app->environment('production')) {
            URL::forceScheme('https');
        }

        $this->app->singleton(UserDataService::class);
        $this->app->singleton(RoleService::class);
        $this->app->singleton(UserSettingService::class);
        $this->app->singleton(StorageConfigService::class);
        $this->app->singleton(FirebaseConfigService::class);
        $this->app->singleton(\App\Services\MailConfigService::class);
        $this->app->singleton(TranslationLoader::class);

        // Auto-translate engines + the active driver (config-selected, default
        // gemini) behind the App\Contracts\Translator contract so every call site
        // is engine-agnostic.
        $this->app->singleton(\App\Services\Translation\GoogleTranslateService::class);
        $this->app->singleton(\App\Services\Translation\GeminiTranslateService::class);
        $this->app->singleton(\App\Contracts\Translator::class, function ($app) {
            return $app->make(config('services.translator.driver') === 'google'
                ? \App\Services\Translation\GoogleTranslateService::class
                : \App\Services\Translation\GeminiTranslateService::class);
        });

        // Catalogue of translatable dynamic-content sources (pages + any a
        // package registers) — powers the per-language "Content translations" page.
        $this->app->singleton(\App\Services\TranslatableContentRegistry::class);

        // Catalogue of package UI translation groups (gifts/profile/…). The single
        // seam that makes the backend the source of truth for every UI string:
        // packages register their lang group here and TranslationLoader merges it.
        $this->app->singleton(\App\Services\TranslationGroupRegistry::class);

        // Package reception SDK
        $this->app->singleton(PackageRegistry::class);
        $this->app->singleton(MenuService::class);
        $this->app->singleton(SettingService::class);
        $this->app->singleton(\App\Services\AdminPermissionRegistry::class);
        $this->app->singleton(ProfileContributorRegistry::class);
        $this->app->singleton(\App\Support\UserProfileTabRegistry::class);
        $this->app->singleton(\App\Support\UserProfileInfolistRegistry::class);

        // Catalogue of admin-editable email templates (password_reset_otp + any
        // type a package registers). Powers App\Mail\TemplatedMail + the admin
        // Email Templates resource.
        $this->app->singleton(\App\Services\Mail\EmailTemplateRegistry::class);

        // Admin audit trail.
        $this->app->singleton(\App\Services\AuditLogger::class);
        $this->app->singleton('utd.audit', fn ($app) => $app->make(\App\Services\AuditLogger::class));

        // Telescope is the server-problem viewer (exceptions, failed requests,
        // failed jobs, error-level logs, slow queries). Register it in ALL
        // environments — not just local — so admins can open /telescope on the
        // live server too. Access is locked down to logged-in admins by the
        // viewTelescope gate (TelescopeServiceProvider), and in non-local only
        // problem entries are stored. Set TELESCOPE_ENABLED=false to turn it off.
        if (config('telescope.enabled', true) && class_exists(\Laravel\Telescope\Telescope::class)) {
            $this->app->register(\Laravel\Telescope\TelescopeServiceProvider::class);
            $this->app->register(TelescopeServiceProvider::class);
        }
    }

    public function boot(): void
    {
        // Filament/Livewire temporary uploads must use an always-writable LOCAL
        // disk. If left unset they fall back to the default filesystem disk, which
        // StorageConfigService may point at a read-only/unconfigured cloud bucket
        // (GCS) — making every admin file upload hang on "awaiting size".
        config(['livewire.temporary_file_upload.disk' => 'local']);

        try {
            app(StorageConfigService::class)->configure();
            app(FirebaseConfigService::class)->configure();
            app(\App\Services\MailConfigService::class)->configure();
        } catch (\Throwable) {
            // DB not ready yet (e.g. during migrations) — fall back to .env
        }

        // Register the Base email-template types. The default subject comes from
        // the otp-email-* translations; the default HTML body is derived from the
        // existing emails.otp_code blade (rendered per-locale) so the design lives
        // in ONE place. Admins override these per-locale in the Email Templates UI;
        // packages register their own types in their provider boot().
        EmailTemplates::register('password_reset_otp', [
            'label'        => fn () => __('admin.email_tpl_password_reset_otp'),
            'description'  => fn () => __('admin.email_tpl_password_reset_otp_desc'),
            'placeholders' => [
                'code'     => 'admin.email_ph_code',
                'app_name' => 'admin.email_ph_app_name',
                'year'     => 'admin.email_ph_year',
            ],
            'default_subject' => fn (string $locale) => __('otp-email-subject', [], $locale),
            'default_body'    => fn (string $locale) => EmailTemplate::renderBladeInLocale(
                'emails.otp_code',
                ['code' => '{{code}}'],
                $locale,
            ),
        ]);

        // Register the base translatable-content source (content Pages). Packages
        // register their own sources the same way; each becomes a tab on the
        // per-language "Content translations" page. getUrl() stays lazy (closure).
        \App\Facades\TranslatableContent::register('pages', [
            'label'     => fn () => __('admin.pages'),
            'model'     => \App\Models\Page::class,
            'fields'    => ['title' => false, 'body' => true],
            'itemLabel' => fn (\App\Models\Page $p) => $p->key,
            'editUrl'   => fn (\App\Models\Page $p) => \App\Filament\Resources\PageResource::getUrl('edit', ['record' => $p]),
        ]);

        // Register the CORE UTD Studio manifest (auth/home/profile/settings default
        // screens + their elements/actions). Packages register their own manifest
        // the same way from their provider boot(). UTD Studio reads the aggregate
        // via GET /api/utd/manifest.
        if (class_exists(\App\Support\UtdManifest::class)) {
            \App\Support\UtdManifest::registerPackage(require config_path('utd_manifest_core.php'));
        }

        Package::observe(PackageObserver::class);
        MenuItem::observe(MenuItemObserver::class);

        // Force-logout a user the instant they're suspended (status flipped to 0):
        // push a 'banned' data message; the app clears its session on receipt.
        // Covers every ban path (UserResource ban, comment ban, …) in one place.
        User::updated(function (User $user): void {
            if ($user->wasChanged('status') && ! $user->status && app()->bound(NotificationSender::class)) {
                try {
                    app(NotificationSender::class)->send($user, NotificationMessage::make(
                        'Account suspended',
                        'Your account has been suspended.',
                        ['type' => 'banned', 'action' => 'logout'],
                    ));
                } catch (\Throwable) {
                    // A push failure must never block the ban itself.
                }
            }
        });
    }
}
