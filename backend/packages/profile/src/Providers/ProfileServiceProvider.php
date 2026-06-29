<?php

namespace Utd\Profile\Providers;

use App\Contracts\MenuContributor;
use App\Modules\BaseModuleServiceProvider;
use App\Services\PackageRegistry;
use App\Support\UserProfileInfolistRegistry;
use Filament\Infolists\Infolist;
use Utd\Profile\Filament\ProfileInfolist;

/**
 * Profile package provider. Discovered by the base PackageServiceProvider via
 * this package's composer.json. BaseModuleServiceProvider auto-loads routes
 * (routes/api.php), migrations and translations, and registers capabilities —
 * all gated by the package being enabled.
 */
class ProfileServiceProvider extends BaseModuleServiceProvider implements MenuContributor
{
    public function packageSlug(): string
    {
        return 'profile';
    }

    public function boot(): void
    {
        parent::boot();

        // Contribute the Flutter `profile.*` UI strings to the backend translation
        // catalog (resources/lang/<locale>/profile.php) so they're served via
        // /api/translations + editable from the dashboard. Guarded for older bases.
        if (class_exists(\App\Services\TranslationGroupRegistry::class)) {
            app(\App\Services\TranslationGroupRegistry::class)
                ->register('profile', $this->packagePath() . '/Resources/lang');
        }

        // Register this package's UTD Studio manifest (the user_profile default
        // screen + its elements/object source). Guarded so the package still
        // boots on a base that predates the Studio infra. Registered regardless
        // of the dashboard wiring below so Studio can discover it.
        if (class_exists(\App\Support\UtdManifest::class)) {
            \App\Support\UtdManifest::registerPackage(
                require $this->packagePath() . '/config/utd_manifest.php'
            );
        }

        // Everything below is admin-dashboard wiring, only when this package is
        // enabled (parent::boot() handles routes/migrations/lang gating).
        if (! app(PackageRegistry::class)->isEnabled($this->packageSlug())) {
            return;
        }

        // Blade views for the rich profile card (profile::user-profile).
        $this->loadViewsFrom($this->packagePath() . '/src/Filament/views', 'profile');

        // Own the dashboard's user-profile VIEW: register our rich infolist so
        // UserResource renders it. The base falls back to its plain schema when
        // this package isn't installed. (Guarded so the package still works on a
        // base that predates the seam.)
        if (class_exists(UserProfileInfolistRegistry::class)) {
            app(UserProfileInfolistRegistry::class)->register(
                fn (Infolist $infolist): Infolist => ProfileInfolist::build($infolist),
            );
        }
    }

    public function packageManifest(): array
    {
        return [
            'name'    => 'Profile',
            'version' => '1.0.0',
            'is_core' => false,
        ];
    }

    // MenuContributor — a default menu entry (slug == Flutter UiContribution id).
    public function getPackage(): string
    {
        return $this->packageSlug();
    }

    public function getMenuItems(): array
    {
        return [[
            'slug'      => 'profile.view',
            'label_key' => 'profile.menu_profile',
            'slot'      => 'drawer',
            'icon'      => 'user',
            'order'     => 10,
            'target'    => 'app',
        ]];
    }
}
