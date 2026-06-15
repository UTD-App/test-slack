<?php

namespace App\Support\Notifications;

/**
 * Immutable metadata for one notification type, registered once by the owning
 * package (or the Base for core types) via
 * {@see \App\Services\Notifications\NotificationTypeRegistry::register()}.
 *
 * The text keys are translation keys (e.g. 'social::notifications.follow'),
 * NOT rendered text — they are resolved per-recipient/per-request with the
 * notification's params. `route` is a Flutter deep-link template whose
 * ':placeholders' are filled from the notification's `data` on tap.
 */
class NotificationType
{
    public function __construct(
        public readonly string $key,                  // e.g. 'social.follow'
        public readonly string $bodyKey,              // translation key for the body
        public readonly ?string $titleKey = null,     // translation key for the title (optional)
        public readonly string $category = 'system',  // social / finance / system …
        public readonly array $channels = ['database', 'push'],
        public readonly ?string $icon = null,         // UI hint, e.g. 'user-plus'
        public readonly ?string $route = null,        // deep-link template, e.g. '/profile/:user_id'
    ) {
    }

    /**
     * @param  array<string,mixed>  $meta
     */
    public static function fromArray(string $key, array $meta): self
    {
        return new self(
            key: $key,
            bodyKey: $meta['body_key'] ?? $key,
            titleKey: $meta['title_key'] ?? null,
            category: $meta['category'] ?? 'system',
            channels: $meta['channels'] ?? ['database', 'push'],
            icon: $meta['icon'] ?? null,
            route: $meta['route'] ?? null,
        );
    }
}
