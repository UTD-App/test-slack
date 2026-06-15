<?php

namespace Tests\Feature;

use App\Models\Notification;
use App\Models\User;
use App\Services\Notifications\NotificationTypeRegistry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Lang;
use Tests\TestCase;

/**
 * The notification API, with the headline guarantee: the SAME stored row renders
 * in the reader's language (render-on-read), so switching locale re-localizes the
 * whole history.
 */
class NotificationApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        app(NotificationTypeRegistry::class)->register('test.greet', [
            'category' => 'test',
            'body_key' => 'notifications.test_greet',
            'channels' => ['database'],
            'route'    => '/profile/:user_id',
        ]);

        Lang::addLines(['notifications.test_greet' => ':name says hi'], 'en');
        Lang::addLines(['notifications.test_greet' => ':name يقول مرحبا'], 'ar');
    }

    private function auth(User $user): static
    {
        return $this->withHeader('Authorization', 'Bearer ' . $user->createToken('test')->plainTextToken);
    }

    public function test_feed_renders_each_row_in_the_request_locale(): void
    {
        $user = User::factory()->create();
        Notification::create([
            'notifiable_id' => $user->id,
            'type'          => 'test.greet',
            'category'      => 'test',
            'params'        => ['name' => 'Ali'],
            'data'          => ['user_id' => 99],
        ]);

        $this->auth($user)
            ->withHeader('X-localization', 'en')
            ->getJson('/api/notifications')
            ->assertStatus(200)
            ->assertJsonPath('data.items.0.body', 'Ali says hi')
            ->assertJsonPath('data.items.0.route', '/profile/99');

        // Same row, different language — proves we store keys+params, not text.
        $this->auth($user)
            ->withHeader('X-localization', 'ar')
            ->getJson('/api/notifications')
            ->assertStatus(200)
            ->assertJsonPath('data.items.0.body', 'Ali يقول مرحبا');
    }

    public function test_unread_count_and_mark_read(): void
    {
        $user = User::factory()->create();
        $n = Notification::create(['notifiable_id' => $user->id, 'type' => 'test.greet', 'category' => 'test', 'params' => ['name' => 'A']]);
        Notification::create(['notifiable_id' => $user->id, 'type' => 'test.greet', 'category' => 'test', 'params' => ['name' => 'B']]);

        $this->auth($user)->getJson('/api/notifications/unread-count')
            ->assertStatus(200)->assertJsonPath('data.unread_count', 2);

        $this->auth($user)->postJson("/api/notifications/{$n->id}/read")->assertStatus(200);

        $this->auth($user)->getJson('/api/notifications/unread-count')
            ->assertJsonPath('data.unread_count', 1);

        $this->auth($user)->postJson('/api/notifications/read-all')->assertStatus(200);
        $this->auth($user)->getJson('/api/notifications/unread-count')
            ->assertJsonPath('data.unread_count', 0);
    }

    public function test_unread_count_appears_in_my_data(): void
    {
        $user = User::factory()->create();
        Notification::create(['notifiable_id' => $user->id, 'type' => 'test.greet', 'category' => 'test', 'params' => ['name' => 'A']]);

        $this->auth($user)->getJson('/api/my-data')
            ->assertStatus(200)
            ->assertJsonPath('data.notifications.unread_count', 1);
    }

    public function test_device_token_registration_stores_token_and_locale(): void
    {
        $user = User::factory()->create();

        $this->auth($user)
            ->withHeader('X-localization', 'ar')
            ->postJson('/api/notifications/device-token', ['device_token' => 'fcm-xyz'])
            ->assertStatus(200);

        $user->refresh();
        $this->assertSame('fcm-xyz', $user->device_token);
        $this->assertSame('ar', $user->locale);
    }

    public function test_user_only_sees_own_notifications(): void
    {
        $me    = User::factory()->create();
        $other = User::factory()->create();
        Notification::create(['notifiable_id' => $other->id, 'type' => 'test.greet', 'category' => 'test', 'params' => ['name' => 'X']]);

        $this->auth($me)->getJson('/api/notifications')
            ->assertStatus(200)
            ->assertJsonPath('data.items', []);
    }
}
