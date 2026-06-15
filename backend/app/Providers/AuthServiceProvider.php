<?php

namespace App\Providers;

use App\Models\AdminUser;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;
use Illuminate\Support\Facades\Gate;

class AuthServiceProvider extends ServiceProvider
{
    /**
     * The policy mappings for the application.
     *
     * @var array<class-string, class-string>
     */
    protected $policies = [
        // 'App\Models\Model' => 'App\Policies\ModelPolicy',
    ];

    /**
     * Register any authentication / authorization services.
     *
     * @return void
     */
    public function boot()
    {
        $this->registerPolicies();

        // Single authorization primitive for the admin dashboard: any ability that
        // is a known admin-permission key resolves through the admin's effective
        // permissions, so $user->can('users.ban'), @can, and Filament's can*() all
        // work. super_admin bypasses everything. Non-admin users / non-permission
        // abilities (e.g. Telescope's 'viewTelescope') are left to other gates.
        Gate::before(function ($user, string $ability): ?bool {
            if (! $user instanceof AdminUser) {
                return null;
            }
            if ($user->isSuperAdmin()) {
                return true;
            }
            if ($user->isKnownPermission($ability)) {
                return $user->hasPermission($ability);
            }
            return null;
        });
    }
}
