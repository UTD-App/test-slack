<?php

namespace App\Services;

use App\Contracts\MenuContributor;
use App\Models\Config;
use App\Models\MenuItem;
use Illuminate\Support\Facades\Cache;

/**
 * Aggregates package-contributed default menu items, seeds them into the
 * `menu_items` table (admin edits preserved), and builds the versioned
 * payload delivered to the Flutter app. Mirrors the Stac/Translation
 * version-endpoint pattern.
 */
class MenuService
{
    /** `configs` row name holding the persisted version (source of truth). */
    public const VERSION_KEY = 'menu_version';

    /**
     * Dedicated cache key — deliberately NOT in the generic `config_*` space
     * used by Common::getConf(), so the two can't invalidate each other.
     */
    protected const CACHE_KEY = 'menu:version';

    /** @var array<string, MenuContributor> package => contributor */
    protected array $contributors = [];

    public function __construct(protected PackageRegistry $packages)
    {
    }

    public function register(MenuContributor $contributor): void
    {
        $this->contributors[$contributor->getPackage()] = $contributor;
    }

    /**
     * Idempotent seed of contributed defaults. Existing rows (and any admin
     * edits on them) are preserved — only missing slugs are inserted.
     */
    public function syncDefaults(): int
    {
        $created = 0;

        foreach ($this->contributors as $package => $contributor) {
            foreach ($contributor->getMenuItems() as $row) {
                if (empty($row['slug'])) {
                    continue;
                }

                $item = MenuItem::firstOrCreate(
                    ['slug' => $row['slug']],
                    [
                        'package'     => $package,
                        'label_key'   => $row['label_key'] ?? $row['slug'],
                        'slot'        => $row['slot'] ?? 'home',
                        'icon'        => $row['icon'] ?? null,
                        'active_icon' => $row['active_icon'] ?? null,
                        'route'       => $row['route'] ?? null,
                        'order'       => $row['order'] ?? 0,
                        'roles'       => $row['roles'] ?? null,
                        'target'      => $row['target'] ?? 'app',
                        'is_visible'  => true,
                    ],
                );

                if ($item->wasRecentlyCreated) {
                    $created++;
                }
            }
        }

        if ($created > 0) {
            $this->bumpVersion();
        }

        return $created;
    }

    /**
     * Final menu config delivered to the app: enabled packages only,
     * app/both target, ordered. Role filtering happens client-side.
     *
     * @return array<int, array<string, mixed>>
     */
    public function buildAppPayload(): array
    {
        return MenuItem::query()
            ->whereIn('package', $this->packages->enabledSlugs())
            ->whereIn('target', ['app', 'both'])
            ->orderBy('slot')
            ->orderBy('order')
            ->get(['slug', 'package', 'label_key', 'icon', 'active_icon', 'route', 'slot', 'order', 'is_visible', 'roles', 'target'])
            ->toArray();
    }

    public function version(): string
    {
        return (string) Cache::remember(self::CACHE_KEY, 3600, function () {
            return Config::where('name', self::VERSION_KEY)->value('value') ?? '0';
        });
    }

    public function bumpVersion(): void
    {
        // Strictly increasing — guards against two bumps within the same second.
        $current = (int) (Config::where('name', self::VERSION_KEY)->value('value') ?? 0);
        $next = max($current + 1, now()->timestamp);

        Config::updateOrCreate(
            ['name' => self::VERSION_KEY],
            ['value' => (string) $next],
        );

        Cache::forget(self::CACHE_KEY);
    }
}
