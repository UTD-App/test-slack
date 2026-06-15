<?php

namespace Tests\Feature;

use App\Contracts\NotificationChannel;
use App\Contracts\NotificationSender;
use App\Models\Notification;
use App\Models\User;
use App\Notifications\Channels\DatabaseChannel;
use App\Notifications\Channels\PushChannel;
use App\Services\Notifications\ChannelRegistry;
use App\Support\Notifications\NotificationMessage;
use App\Support\Notifications\NotificationType;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationChannelTest extends TestCase
{
    use RefreshDatabase;

    private function type(array $channels = ['database', 'push']): NotificationType
    {
        return new NotificationType(
            key: 'test.greet',
            bodyKey: 'notifications.test_greet',
            category: 'test',
            channels: $channels,
            route: '/profile/:user_id',
        );
    }

    public function test_database_channel_writes_a_row(): void
    {
        $user = User::factory()->create();

        (new DatabaseChannel())->deliver($user, $this->type(), [
            'params'   => ['name' => 'Ali'],
            'data'     => ['user_id' => 5],
            'actor_id' => 5,
            'title'    => 'ignored',
            'body'     => 'ignored',
        ]);

        $row = Notification::where('notifiable_id', $user->id)->firstOrFail();
        $this->assertSame('test.greet', $row->type);
        $this->assertSame(['name' => 'Ali'], $row->params);
    }

    public function test_push_channel_delegates_to_sender_when_token_present(): void
    {
        $sender = $this->fakeSender();

        $user = User::factory()->create(['device_token' => 'fcm-123']);
        (new PushChannel($sender))->deliver($user, $this->type(), [
            'data'  => ['user_id' => 5],
            'title' => 'Hi',
            'body'  => 'Ali says hi',
        ]);

        $this->assertCount(1, $sender->sent);
        $this->assertSame('Ali says hi', $sender->sent[0]->body);
        // Type + deep-link route are injected into the push data payload.
        $this->assertSame('test.greet', $sender->sent[0]->data['type']);
        $this->assertSame('/profile/:user_id', $sender->sent[0]->data['route']);
    }

    public function test_push_channel_skips_when_no_token(): void
    {
        $sender = $this->fakeSender();

        $user = User::factory()->create(['device_token' => null]);
        (new PushChannel($sender))->deliver($user, $this->type(), ['title' => 'Hi', 'body' => 'x']);

        $this->assertCount(0, $sender->sent);
    }

    public function test_channel_registry_resolves_only_registered_channels(): void
    {
        $registry = new ChannelRegistry();
        $registry->register(new DatabaseChannel());

        // Requesting database+push but only database is registered → push degrades away.
        $resolved = $registry->resolve(['database', 'push']);

        $this->assertCount(1, $resolved);
        $this->assertSame('database', $resolved[0]->key());
    }

    private function fakeSender(): NotificationSender
    {
        return new class implements NotificationSender {
            /** @var array<int, NotificationMessage> */
            public array $sent = [];

            public function send(User $user, NotificationMessage $message): bool
            {
                $this->sent[] = $message;

                return true;
            }

            public function sendToTokens(array $tokens, NotificationMessage $message): void
            {
            }

            public function sendToTopic(string $topic, NotificationMessage $message): bool
            {
                return true;
            }
        };
    }
}
