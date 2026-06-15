<?php

namespace App\Support;

/**
 * Lets packages contribute tabs (Filament RelationManagers) to the User profile
 * (UserResource view page) WITHOUT the base depending on those packages.
 *
 * A package registers a RelationManager class string at boot (see e.g. the
 * Moment package's "reports filed" tab). UserResource::getRelations() returns
 * whatever has been registered, and Filament's ViewRecord renders them as tabs.
 *
 * Bound as a singleton in AppServiceProvider so the instance packages register
 * into is the same one UserResource reads from. Keyed by id → idempotent across
 * re-boots (e.g. Octane workers).
 */
class UserProfileTabRegistry
{
    /** @var array<string, array{class: class-string, order: int}> id => entry */
    protected array $tabs = [];

    /** Lower `order` shows first; equal orders keep registration order. */
    public function register(string $id, string $relationManagerClass, int $order = 0): void
    {
        $this->tabs[$id] = ['class' => $relationManagerClass, 'order' => $order];
    }

    /** @return array<int, class-string> ordered by `order` then registration. */
    public function all(): array
    {
        $tabs = $this->tabs;
        uasort($tabs, fn (array $a, array $b): int => $a['order'] <=> $b['order']);

        return array_values(array_map(fn (array $t): string => $t['class'], $tabs));
    }
}
