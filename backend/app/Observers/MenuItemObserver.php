<?php

namespace App\Observers;

use App\Models\MenuItem;
use App\Services\MenuService;

class MenuItemObserver
{
    public function __construct(protected MenuService $menu)
    {
    }

    public function saved(MenuItem $item): void
    {
        $this->menu->bumpVersion();
    }

    public function deleted(MenuItem $item): void
    {
        $this->menu->bumpVersion();
    }
}
