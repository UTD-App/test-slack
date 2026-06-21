<?php

namespace App\Providers\Filament;

use App\Filament\Pages\EditProfile;
use App\Http\Middleware\SetAdminLocale;
use App\Models\Config;
use Filament\Http\Middleware\Authenticate;
use Filament\Http\Middleware\AuthenticateSession;
use Filament\Http\Middleware\DisableBladeIconComponents;
use Filament\Http\Middleware\DispatchServingFilamentEvent;
use Filament\Navigation\MenuItem;
use Filament\Pages;
use Filament\Panel;
use Filament\PanelProvider;
use Filament\Support\Colors\Color;
use Filament\View\PanelsRenderHook;
use Filament\Widgets;
use Illuminate\Cookie\Middleware\AddQueuedCookiesToResponse;
use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken;
use Illuminate\Routing\Middleware\SubstituteBindings;
use Illuminate\Session\Middleware\StartSession;
use Illuminate\View\Middleware\ShareErrorsFromSession;

class AdminPanelProvider extends PanelProvider
{
    public function panel(Panel $panel): Panel
    {
        $panel = $panel
            ->default()
            ->id('admin')
            ->path('admin')
            ->login()
            ->authGuard('admin')
            ->colors([
                'primary' => Color::Blue,
            ])
            // Brand name comes from the admin-editable App Settings `app_name`
            // (cached config map), falling back to APP_NAME. Evaluated lazily per
            // request, so changing it in App Settings updates the panel header.
            ->brandName(function (): string {
                try {
                    $name = Config::map()['app_name'] ?? config('app.name');
                } catch (\Throwable) {
                    $name = config('app.name');
                }

                return trim(($name ?: config('app.name')) . ' — ' . __('admin.admin_brand_suffix'));
            })
            ->favicon(asset('images/favicon.ico'))
            ->darkMode(false)
            ->userMenuItems([
                MenuItem::make()
                    ->label(__('admin.my_profile'))
                    ->icon('heroicon-o-user-circle')
                    ->url(fn() => EditProfile::getUrl()),
            ])
            ->renderHook(
                PanelsRenderHook::GLOBAL_SEARCH_BEFORE,
                fn() => view('filament.components.top-bar-actions')
            )
            ->renderHook(
                PanelsRenderHook::AUTH_LOGIN_FORM_AFTER,
                fn() => view('filament.components.login-language-switcher')
            )
            ->renderHook(
                PanelsRenderHook::PAGE_HEADER_ACTIONS_BEFORE,
                function () {
                    $isRtl = app()->getLocale() === 'ar' || __('filament-panels::layout.direction') === 'rtl';
                    // In RTL: arrow points right (→) = M13.5 19.5 21 12m0 0-7.5-7.5M21 12H3
                    // In LTR: arrow points left  (←) = M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18
                    $arrowPath = $isRtl
                        ? 'M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3'
                        : 'M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18';
                    return '<button onclick="history.back()"
                        class="fi-btn fi-btn-size-sm fi-color-gray fi-btn-color-gray inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-semibold shadow-sm ring-1 ring-gray-950/10 dark:ring-white/20 bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
                        <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="' . $arrowPath . '" />
                        </svg>
                    </button>';
                }
            )
            ->renderHook(
                PanelsRenderHook::BODY_END,
                fn() => '<script>
                    // Scroll to top on Livewire navigation
                    document.addEventListener("livewire:navigated", () => window.scrollTo({top: 0, behavior: "smooth"}));

                    // Inject back button next to breadcrumbs — works for both RTL and LTR
                    function injectBackButton() {
                        if (window.history.length <= 1) return;
                        const existing = document.getElementById("utd-back-btn");
                        if (existing) return;
                        const breadcrumbs = document.querySelector(".fi-breadcrumbs");
                        if (!breadcrumbs) return;
                        const isRtl = document.documentElement.dir === "rtl";
                        const btn = document.createElement("button");
                        btn.id = "utd-back-btn";
                        btn.onclick = () => history.back();
                        btn.className = "inline-flex items-center justify-center h-8 w-8 rounded-lg text-gray-500 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-400 transition-colors";
                        btn.innerHTML = isRtl
                            ? `<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3"/></svg>`
                            : `<svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18"/></svg>`;
                        const wrapper = document.createElement("div");
                        wrapper.className = "flex items-center gap-2";
                        breadcrumbs.parentNode.insertBefore(wrapper, breadcrumbs);
                        wrapper.appendChild(btn);
                        wrapper.appendChild(breadcrumbs);
                    }
                    document.addEventListener("livewire:navigated", injectBackButton);
                    document.addEventListener("DOMContentLoaded", injectBackButton);
                    setTimeout(injectBackButton, 300);
                </script>'
            )
            ->discoverResources(in: app_path('Filament/Resources'), for: 'App\\Filament\\Resources')
            ->discoverPages(in: app_path('Filament/Pages'), for: 'App\\Filament\\Pages')
            ->pages([
                Pages\Dashboard::class,
            ])
            ->discoverWidgets(in: app_path('Filament/Widgets'), for: 'App\\Filament\\Widgets')
            ->widgets([
                Widgets\AccountWidget::class,
                \App\Filament\Widgets\StatsOverviewWidget::class,
            ])
            ->middleware([
                EncryptCookies::class,
                AddQueuedCookiesToResponse::class,
                StartSession::class,
                AuthenticateSession::class,
                ShareErrorsFromSession::class,
                VerifyCsrfToken::class,
                SubstituteBindings::class,
                DisableBladeIconComponents::class,
                DispatchServingFilamentEvent::class,
                SetAdminLocale::class,
            ])
            ->authMiddleware([
                Authenticate::class,
            ]);

        $this->discoverPackagePanels($panel);

        return $panel;
    }

    /**
     * Discover Filament resources/pages/widgets contributed by ENABLED assembled
     * packages under backend/packages/<name>/src/Filament/*. Each package's
     * namespace is read from its OWN composer.json (PSR-4) — no package is named
     * here. No-op when no packages are installed.
     */
    protected function discoverPackagePanels(Panel $panel): void
    {
        $dir = base_path('packages');

        if (! is_dir($dir)) {
            return;
        }

        $registry = app(\App\Services\PackageRegistry::class);

        foreach (glob($dir . '/*', GLOB_ONLYDIR) ?: [] as $packagePath) {
            $composerFile = $packagePath . '/composer.json';

            if (! is_file($composerFile)) {
                continue;
            }

            $manifest = json_decode((string) file_get_contents($composerFile), true);
            $psr4     = $manifest['autoload']['psr-4'] ?? [];

            if (! is_array($psr4) || $psr4 === []) {
                continue;
            }

            $slug = \Illuminate\Support\Str::kebab(basename($packagePath));

            if (! $registry->isEnabled($slug)) {
                continue;
            }

            $baseNamespace = rtrim((string) array_key_first($psr4), '\\');
            $srcPath       = $packagePath . '/' . trim((string) reset($psr4), '/');

            // One broken package must not abort discovery of the panel / other packages.
            try {
                if (is_dir($srcPath . '/Filament/Resources')) {
                    $panel->discoverResources(in: $srcPath . '/Filament/Resources', for: $baseNamespace . '\\Filament\\Resources');
                }

                if (is_dir($srcPath . '/Filament/Pages')) {
                    $panel->discoverPages(in: $srcPath . '/Filament/Pages', for: $baseNamespace . '\\Filament\\Pages');
                }

                if (is_dir($srcPath . '/Filament/Widgets')) {
                    $panel->discoverWidgets(in: $srcPath . '/Filament/Widgets', for: $baseNamespace . '\\Filament\\Widgets');
                }
            } catch (\Throwable $e) {
                \Illuminate\Support\Facades\Log::error("Failed to discover package Filament panels [{$slug}]: {$e->getMessage()}");
            }
        }
    }
}
