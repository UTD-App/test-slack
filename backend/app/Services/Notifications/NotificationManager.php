<?php

namespace App\Services\Notifications;

use App\Jobs\SendNotificationJob;
use App\Models\NotificationPreference;
use App\Models\User;
use App\Support\Notifications\NotificationType;
use Illuminate\Support\Facades\Log;

/**
 * The high-level notification entry point ("Notifier"). Any package calls this
 * to notify a user by TYPE — the manager looks up the type metadata, honours the
 * recipient's preferences, renders the text in the recipient's locale, and fans
 * the notification out to every resolved channel (database/push/…).
 *
 * Distinct from the low-level {@see \App\Contracts\NotificationSender} (raw push,
 * no storage), which the push channel wraps. Resolved via the 'utd.notifier'
 * binding and the {@see \App\Facades\Notifier} facade.
 */
class NotificationManager
{
    public function __construct(
        protected NotificationTypeRegistry $types,
        protected ChannelRegistry $channels,
    ) {
    }

    /**
     * Notify one user.
     *
     * @param  array<string,mixed>  $params  translation variables (e.g. ['name' => 'Ali'])
     * @param  array<string,mixed>  $data    deep-link payload (e.g. ['user_id' => 42])
     */
    public function send(
        User $recipient,
        string $typeKey,
        array $params = [],
        array $data = [],
        ?User $actor = null,
        ?string $imageUrl = null,
    ): void {
        if (! config('notifications.enabled', true)) {
            return;
        }

        $type = $this->types->get($typeKey);
        if (! $type) {
            Log::warning("Notifier: unknown notification type [{$typeKey}] — skipped.");

            return;
        }

        $rendered = $this->render($type, $params, $this->recipientLocale($recipient));

        $payload = [
            'params'    => $params,
            'data'      => $data,
            'actor_id'  => $actor?->id,
            'image_url' => $imageUrl,
            'title'     => $rendered['title'],
            'body'      => $rendered['body'],
        ];

        foreach ($this->channels->resolve($type->channels) as $channel) {
            if ($this->isMuted($recipient->id, $type->category, $channel->key())) {
                continue;
            }

            try {
                $channel->deliver($recipient, $type, $payload);
            } catch (\Throwable $e) {
                Log::warning("Notifier: channel [{$channel->key()}] failed for type [{$typeKey}]", [
                    'recipient' => $recipient->id,
                    'error'     => $e->getMessage(),
                ]);
            }
        }
    }

    /**
     * Notify many users (synchronous loop — for small sets such as a follower
     * list already in memory). Use {@see broadcast()} for large/all-users fan-out.
     *
     * @param  iterable<User>       $recipients
     * @param  array<string,mixed>  $params
     * @param  array<string,mixed>  $data
     */
    public function sendMany(
        iterable $recipients,
        string $typeKey,
        array $params = [],
        array $data = [],
        ?User $actor = null,
        ?string $imageUrl = null,
    ): void {
        foreach ($recipients as $recipient) {
            $this->send($recipient, $typeKey, $params, $data, $actor, $imageUrl);
        }
    }

    /**
     * Fan a notification out to all users (or a list of ids) on the queue, in
     * chunks. Powers admin announcements (the old `official_messages`). NOTE:
     * writing one in-app row per user is O(users) — intended for genuine
     * broadcasts, not per-event notifications.
     *
     * @param  array<string,mixed>     $params
     * @param  array<string,mixed>     $data
     * @param  array<int,int>|null     $userIds  null = every user
     */
    public function broadcast(string $typeKey, array $params = [], array $data = [], ?array $userIds = null): void
    {
        SendNotificationJob::dispatch($typeKey, $params, $data, $userIds);
    }

    /**
     * Notify the admin dashboard (not a user). Stores ONE shared admin row that
     * the dashboard widget surfaces to every admin — the modern path for reports
     * and other moderation events. No push/preferences (it's a web dashboard
     * queue); the type still drives the rendered text + category.
     *
     * @param  array<string,mixed>  $params
     * @param  array<string,mixed>  $data
     */
    public function toAdmins(string $typeKey, array $params = [], array $data = [], ?User $actor = null): void
    {
        if (! config('notifications.enabled', true)) {
            return;
        }

        $type = $this->types->get($typeKey);
        if (! $type) {
            Log::warning("Notifier: unknown notification type [{$typeKey}] — skipped (toAdmins).");

            return;
        }

        \App\Models\Notification::create([
            'notifiable_type' => \App\Models\Notification::AUDIENCE_ADMIN,
            'notifiable_id'   => 0, // 0 = all admins
            'type'            => $type->key,
            'category'        => $type->category,
            'params'          => $params,
            'data'            => $data,
            'actor_id'        => $actor?->id,
        ]);
    }

    /**
     * Render a type's title/body in $locale with $params. Two shapes are supported:
     *
     *  - Templated (social.follow, …): $params are scalar translation variables and
     *    the text comes from the translation keys (`__(:name followed you)`).
     *  - Free-text (admin announcements): $params['title'|'body'] are per-locale
     *    maps (['en' => …, 'ar' => …]) — we pick the recipient/request locale.
     *
     * Returns the raw key when a translation is missing (Laravel's __ fallback)
     * so nothing breaks.
     *
     * @param  array<string,mixed>  $params
     * @return array{title:string, body:string}
     */
    public function render(NotificationType $type, array $params, string $locale): array
    {
        if ((isset($params['body']) && is_array($params['body'])) || (isset($params['title']) && is_array($params['title']))) {
            return [
                'title' => $this->pickLocalized($params['title'] ?? [], $locale),
                'body'  => $this->pickLocalized($params['body'] ?? [], $locale),
            ];
        }

        $body  = __($type->bodyKey, $params, $locale);
        $title = $type->titleKey ? __($type->titleKey, $params, $locale) : '';

        return [
            'title' => is_string($title) ? $title : (string) $type->titleKey,
            'body'  => is_string($body) ? $body : $type->bodyKey,
        ];
    }

    /**
     * Pick a value from a per-locale map, falling back to the app default locale
     * then the first available value.
     *
     * @param  mixed  $map
     */
    protected function pickLocalized($map, string $locale): string
    {
        if (is_string($map)) {
            return $map;
        }

        if (! is_array($map) || $map === []) {
            return '';
        }

        return (string) ($map[$locale]
            ?? $map[config('app.locale', 'en')]
            ?? reset($map));
    }

    protected function recipientLocale(User $recipient): string
    {
        return $recipient->locale
            ?: config('notifications.push_locale_fallback', config('app.locale', 'en'));
    }

    /**
     * A (category[, channel]) pair is muted only if the user has an explicit
     * disabled preference for it. Absence = enabled (default-on).
     */
    protected function isMuted(int $userId, string $category, string $channel): bool
    {
        return NotificationPreference::query()
            ->where('user_id', $userId)
            ->where('category', $category)
            ->where(fn ($q) => $q->whereNull('channel')->orWhere('channel', $channel))
            ->where('enabled', false)
            ->exists();
    }
}
