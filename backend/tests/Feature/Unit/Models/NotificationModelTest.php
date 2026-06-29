<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationModelTest extends TestCase
{
    use RefreshDatabase;

    private function make(array $overrides = []): Notification
    {
        return Notification::create(array_merge([
            'notifiable_type' => Notification::AUDIENCE_USER,
            'notifiable_id'   => 1,
            'type'            => 'social.follow',
            'category'        => 'social',
        ], $overrides));
    }

    public function test_audience_constants(): void
    {
        $this->assertSame('user', Notification::AUDIENCE_USER);
        $this->assertSame('admin', Notification::AUDIENCE_ADMIN);
    }

    public function test_params_and_data_cast_to_array(): void
    {
        $n = $this->make(['params' => ['name' => 'Ali'], 'data' => ['user_id' => 42]]);
        $n->refresh();

        $this->assertSame(['name' => 'Ali'], $n->params);
        $this->assertSame(['user_id' => 42], $n->data);
    }

    public function test_read_at_cast_to_datetime(): void
    {
        $n = $this->make(['read_at' => now()]);
        $this->assertInstanceOf(\Illuminate\Support\Carbon::class, $n->refresh()->read_at);
    }

    public function test_is_read(): void
    {
        $this->assertFalse($this->make(['read_at' => null])->isRead());
        $this->assertTrue($this->make(['read_at' => now()])->isRead());
    }

    public function test_scope_unread(): void
    {
        $this->make(['read_at' => null]);
        $this->make(['read_at' => now()]);

        $this->assertSame(1, Notification::unread()->count());
    }

    public function test_scope_for_user(): void
    {
        $this->make(['notifiable_id' => 1]);
        $this->make(['notifiable_id' => 2]);
        $this->make(['notifiable_type' => Notification::AUDIENCE_ADMIN, 'notifiable_id' => 1]);

        $rows = Notification::forUser(1)->get();
        $this->assertCount(1, $rows);
        $this->assertSame(1, $rows->first()->notifiable_id);
        $this->assertSame('user', $rows->first()->notifiable_type);
    }

    public function test_scope_for_admins(): void
    {
        $this->make(['notifiable_type' => Notification::AUDIENCE_ADMIN]);
        $this->make(['notifiable_type' => Notification::AUDIENCE_USER]);

        $this->assertSame(1, Notification::forAdmins()->count());
    }

    public function test_actor_and_notifiable_relationships(): void
    {
        $recipient = User::factory()->create();
        $actor = User::factory()->create();
        $n = $this->make(['notifiable_id' => $recipient->id, 'actor_id' => $actor->id]);

        $this->assertTrue($n->notifiable->is($recipient));
        $this->assertTrue($n->actor->is($actor));
    }
}
