<?php

namespace App\Services\Notifications;

use App\Support\Notifications\NotificationType;

/**
 * In-memory catalogue of every notification type the running app knows about.
 * Each package registers its types once in its provider boot() (Base registers
 * the core types). The registry powers rendering (which translation key + which
 * channels for a given type), the admin broadcast composer, and the preferences
 * UI (categories to mute). Resolved via the singleton bound in
 * {@see \App\Providers\NotificationServiceProvider}.
 */
class NotificationTypeRegistry
{
    /** @var array<string, NotificationType> */
    protected array $types = [];

    /**
     * Register (or override) a type.
     *
     * @param  array<string,mixed>  $meta  body_key, title_key?, category?, channels?, icon?, route?
     */
    public function register(string $key, array $meta): void
    {
        $this->types[$key] = NotificationType::fromArray($key, $meta);
    }

    public function has(string $key): bool
    {
        return isset($this->types[$key]);
    }

    public function get(string $key): ?NotificationType
    {
        return $this->types[$key] ?? null;
    }

    /** @return array<string, NotificationType> */
    public function all(): array
    {
        return $this->types;
    }

    /**
     * Distinct categories across all registered types — for the preferences UI.
     *
     * @return array<int, string>
     */
    public function categories(): array
    {
        return array_values(array_unique(array_map(
            fn (NotificationType $t) => $t->category,
            $this->types,
        )));
    }
}
