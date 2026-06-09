<?php

namespace App\Support;

/**
 * In-memory registry for the UTD Studio integration manifest.
 *
 * Each installed package registers its design-time contract here from its own
 * ServiceProvider::boot() — so a package's elements live INSIDE the package,
 * never in the base project. UTD Studio reads the aggregated result via
 * GET /api/utd/manifest (X-UTD-Secret) to know which packages/elements exist.
 *
 * Example (from a package ServiceProvider):
 *   UtdManifest::registerPackage([
 *     'key'      => 'chat',
 *     'name'     => 'Chat',
 *     'icon'     => 'chat_bubble',
 *     'screens'  => ['conversations', 'conversation'],
 *     'elements' => [
 *       ['key' => 'name', 'label' => 'اسم المحادثة', 'type' => 'string', 'screen' => 'conversations'],
 *     ],
 *     'action_elements'    => [...],
 *     'conversation_flags' => [...],
 *   ]);
 */
class UtdManifest
{
    /** @var array<string, array> keyed by package key to avoid duplicates */
    protected static array $packages = [];

    public static function registerPackage(array $manifest): void
    {
        if (empty($manifest['key'])) {
            return;
        }

        static::$packages[$manifest['key']] = array_merge([
            'name'               => ucfirst($manifest['key']),
            'icon'               => null,
            'screens'            => [],
            'elements'           => [],
            'action_elements'    => [],
            'conversation_flags' => [],
            'default_screens'    => [],
        ], $manifest);
    }

    /** @return array<int, array> list of registered packages (contract shape) */
    public static function all(): array
    {
        return array_values(static::$packages);
    }

    public static function get(string $key): ?array
    {
        return static::$packages[$key] ?? null;
    }

    /** Mostly for tests. */
    public static function flush(): void
    {
        static::$packages = [];
    }
}
