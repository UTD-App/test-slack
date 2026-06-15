<?php

namespace App\Services\Notifications;

use App\Contracts\NotificationChannel;

/**
 * Holds the delivery channels the Notifier fans out to. The Base registers
 * `database` (always) and `push` (toggleable) in
 * {@see \App\Providers\NotificationServiceProvider}; channel plugins (realtime,
 * email, sms) register themselves here from their own providers.
 */
class ChannelRegistry
{
    /** @var array<string, NotificationChannel> */
    protected array $channels = [];

    public function register(NotificationChannel $channel): void
    {
        $this->channels[$channel->key()] = $channel;
    }

    public function has(string $key): bool
    {
        return isset($this->channels[$key]);
    }

    public function get(string $key): ?NotificationChannel
    {
        return $this->channels[$key] ?? null;
    }

    /** @return array<int, string> */
    public function keys(): array
    {
        return array_keys($this->channels);
    }

    /**
     * The channels a notification should actually go to: the type's requested
     * channels intersected with the ones currently registered (so a type that
     * asks for 'push' silently degrades when no push channel is installed).
     *
     * @param  array<int, string>  $requested
     * @return array<int, NotificationChannel>
     */
    public function resolve(array $requested): array
    {
        $resolved = [];
        foreach ($requested as $key) {
            if (isset($this->channels[$key])) {
                $resolved[] = $this->channels[$key];
            }
        }

        return $resolved;
    }
}
