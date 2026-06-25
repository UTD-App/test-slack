<?php

namespace App\Support\Notifications;

/**
 * A channel-agnostic notification payload.
 */
class NotificationMessage
{
    public function __construct(
        public readonly string $title,
        public readonly string $body,
        public readonly array $data = [],
        public readonly ?string $imageUrl = null,
    ) {
    }

    public static function make(string $title, string $body, array $data = [], ?string $imageUrl = null): self
    {
        return new self($title, $body, $data, $imageUrl);
    }
}
