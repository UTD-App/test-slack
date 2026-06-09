<?php

namespace App\Observers;

use App\Models\Package;
use App\Services\MenuService;
use App\Services\PackageRegistry;

class PackageObserver
{
    public function __construct(
        protected PackageRegistry $packages,
        protected MenuService $menu,
    ) {
    }

    public function saved(Package $package): void
    {
        // enabling/disabling a package changes which menu items ship
        $this->packages->forgetCache();
        $this->menu->bumpVersion();
    }

    public function deleted(Package $package): void
    {
        $this->packages->forgetCache();
        $this->menu->bumpVersion();
    }
}
