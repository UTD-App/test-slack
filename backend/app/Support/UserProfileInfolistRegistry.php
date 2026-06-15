<?php

namespace App\Support;

use Closure;
use Filament\Infolists\Infolist;

/**
 * Lets a package (the Profile package) supply the infolist — the "view" schema —
 * for the User profile page (UserResource view) WITHOUT the base depending on it.
 *
 * The Profile package registers a builder Closure at boot (gated by the package
 * being enabled). {@see \App\Filament\Resources\UserResource::infolist()} uses it
 * when present, otherwise falls back to the base default schema. This mirrors
 * {@see UserProfileTabRegistry} (which does the same for the profile tabs).
 *
 * Bound as a singleton in AppServiceProvider so the instance a package writes to
 * is the same one UserResource reads from. Last registration wins.
 */
class UserProfileInfolistRegistry
{
    /** @var (Closure(Infolist): Infolist)|null */
    protected ?Closure $builder = null;

    /** @param Closure(Infolist): Infolist $builder */
    public function register(Closure $builder): void
    {
        $this->builder = $builder;
    }

    public function has(): bool
    {
        return $this->builder !== null;
    }

    /** @return (Closure(Infolist): Infolist)|null */
    public function resolve(): ?Closure
    {
        return $this->builder;
    }
}
