<?php

namespace Tests\Feature\Unit;

use App\Contracts\NotificationChannel;
use App\Models\User;
use App\Services\Notifications\ChannelRegistry;
use App\Services\Notifications\NotificationTypeRegistry;
use App\Support\Notifications\NotificationType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * In-memory notification catalogues. Notifier behaviour (send/mute/broadcast)
 * and basic channel resolution are covered in NotifierTest / NotificationChannelTest;
 * here we fill the registry gaps: type metadata mapping, has/get/all, categories,
 * and the channel registry lookup helpers.
 */
class NotificationRegistriesTest extends TestCase
{
    use RefreshDatabase;

    // ── NotificationTypeRegistry ──────────────────────────────────────────────

    public function test_register_maps_meta_into_a_notification_type(): void
    {
        $registry = new NotificationTypeRegistry();
        $registry->register('social.follow', [
            'body_key' => 'notifications.follow',
            'title_key' => 'notifications.follow_title',
            'category' => 'social',
            'channels' => ['database', 'push'],
            'icon' => 'user-plus',
            'route' => '/profile/:user_id',
        ]);

        $type = $registry->get('social.follow');

        $this->assertInstanceOf(NotificationType::class, $type);
        $this->assertSame('social.follow', $type->key);
        $this->assertSame('notifications.follow', $type->bodyKey);
        $this->assertSame('notifications.follow_title', $type->titleKey);
        $this->assertSame('social', $type->category);
        $this->assertSame(['database', 'push'], $type->channels);
        $this->assertSame('user-plus', $type->icon);
        $this->assertSame('/profile/:user_id', $type->route);
    }

    public function test_register_applies_defaults_for_omitted_meta(): void
    {
        $registry = new NotificationTypeRegistry();
        $registry->register('bare.type', []); // everything defaulted

        $type = $registry->get('bare.type');

        $this->assertSame('bare.type', $type->bodyKey); // body_key defaults to key
        $this->assertNull($type->titleKey);
        $this->assertSame('system', $type->category);
        $this->assertSame(['database', 'push'], $type->channels);
    }

    public function test_has_and_get_for_unknown_type(): void
    {
        $registry = new NotificationTypeRegistry();

        $this->assertFalse($registry->has('nope'));
        $this->assertNull($registry->get('nope'));
    }

    public function test_register_overrides_existing_type(): void
    {
        $registry = new NotificationTypeRegistry();
        $registry->register('t', ['category' => 'social']);
        $registry->register('t', ['category' => 'finance']);

        $this->assertSame('finance', $registry->get('t')->category);
        $this->assertCount(1, $registry->all());
    }

    public function test_categories_are_distinct(): void
    {
        $registry = new NotificationTypeRegistry();
        $registry->register('a', ['category' => 'social']);
        $registry->register('b', ['category' => 'social']);
        $registry->register('c', ['category' => 'finance']);
        $registry->register('d', []); // defaults to system

        $categories = $registry->categories();

        sort($categories);
        $this->assertSame(['finance', 'social', 'system'], $categories);
    }

    public function test_all_returns_every_registered_type(): void
    {
        $registry = new NotificationTypeRegistry();
        $registry->register('a', []);
        $registry->register('b', []);

        $this->assertSame(['a', 'b'], array_keys($registry->all()));
    }

    // ── ChannelRegistry (gaps not covered by NotificationChannelTest) ──────────

    private function channel(string $key): NotificationChannel
    {
        return new class($key) implements NotificationChannel {
            public function __construct(private string $key) {}
            public function key(): string { return $this->key; }
            public function deliver(User $recipient, NotificationType $type, array $payload): void {}
        };
    }

    public function test_channel_registry_has_get_keys(): void
    {
        $registry = new ChannelRegistry();
        $registry->register($this->channel('database'));
        $registry->register($this->channel('push'));

        $this->assertTrue($registry->has('database'));
        $this->assertFalse($registry->has('sms'));
        $this->assertSame('push', $registry->get('push')?->key());
        $this->assertNull($registry->get('sms'));
        $this->assertSame(['database', 'push'], $registry->keys());
    }

    public function test_channel_resolve_preserves_requested_order_and_skips_unregistered(): void
    {
        $registry = new ChannelRegistry();
        $registry->register($this->channel('push'));
        $registry->register($this->channel('database'));

        $resolved = $registry->resolve(['database', 'sms', 'push']);

        $this->assertSame(['database', 'push'], array_map(fn ($c) => $c->key(), $resolved));
    }

    public function test_channel_resolve_empty_when_none_registered(): void
    {
        $registry = new ChannelRegistry();

        $this->assertSame([], $registry->resolve(['database', 'push']));
    }
}
