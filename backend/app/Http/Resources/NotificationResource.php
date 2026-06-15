<?php

namespace App\Http\Resources;

use App\Services\Notifications\NotificationManager;
use App\Services\Notifications\NotificationTypeRegistry;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Serializes a notification for the app, rendering title/body ON READ in the
 * CURRENT request locale (set by the Localization middleware from X-localization).
 * The stored row holds only type + params, so switching the UI language
 * re-localizes the whole feed — including old notifications.
 */
class NotificationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $registry = app(NotificationTypeRegistry::class);
        $type     = $registry->get($this->type);

        $rendered = $type
            ? app(NotificationManager::class)->render($type, $this->params ?? [], app()->getLocale())
            : ['title' => '', 'body' => $this->type];

        return [
            'id'         => $this->id,
            'type'       => $this->type,
            'category'   => $this->category,
            'title'      => $rendered['title'],
            'body'       => $rendered['body'],
            'icon'       => $type?->icon,
            'route'      => $this->resolveRoute($type?->route),
            'data'       => $this->data ?? [],
            'image_url'  => $this->image_url,
            'actor'      => $this->actorPayload(),
            'is_read'    => $this->read_at !== null,
            'read_at'    => optional($this->read_at)?->toIso8601String(),
            'created_at' => optional($this->created_at)?->toIso8601String(),
        ];
    }

    /** Fill ':placeholder' segments of the deep-link template from the row's data. */
    protected function resolveRoute(?string $route): ?string
    {
        if (! $route) {
            return null;
        }

        foreach (($this->data ?? []) as $key => $value) {
            if (is_scalar($value)) {
                $route = str_replace(':' . $key, (string) $value, $route);
            }
        }

        return $route;
    }

    /** @return array<string,mixed>|null */
    protected function actorPayload(): ?array
    {
        $actor = $this->whenLoaded('actor');

        if (! $actor || ! is_object($actor)) {
            return null;
        }

        return [
            'id'     => $actor->id,
            'name'   => $actor->name,
            'uuid'   => $actor->uuid ?? null,
            'avatar' => $actor->avatar ?? null,
        ];
    }
}
