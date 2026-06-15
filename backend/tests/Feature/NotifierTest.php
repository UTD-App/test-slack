<?php

namespace Tests\Feature;

use App\Facades\Notifier;
use App\Models\Notification;
use App\Models\NotificationPreference;
use App\Models\User;
use App\Services\Notifications\NotificationTypeRegistry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Lang;
use Tests\TestCase;

/**
 * Core behaviour of the high-level Notifier: language-neutral storage,
 * recipient-locale rendering for push, preference muting, and queued broadcast.
 */
class NotifierTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // A templated test type + its translations (en/ar).
        app(NotificationTypeRegistry::class)->register('test.greet', [
            'category' => 'test',
            'body_key' => 'notifications.test_greet',
            'channels' => ['database', 'push'],
            'route'    => '/profile/:user_id',
        ]);

        Lang::addLines(['notifications.test_greet' => ':name says hi'], 'en');
        Lang::addLines(['notifications.test_greet' => ':name يقول مرحبا'], 'ar');
    }

    public function test_send_stores_type_and_params_not_rendered_text(): void
    {
        $recipient = User::factory()->create();
        $actor     = User::factory()->create(['name' => 'Ali']);

        Notifier::send($recipient, 'test.greet',
            params: ['name' => 'Ali'], data: ['user_id' => $actor->id], actor: $actor);

        $row = Notification::where('notifiable_id', $recipient->id)->firstOrFail();

        $this->assertSame('test.greet', $row->type);
        $this->assertSame('test', $row->category);
        $this->assertSame(['name' => 'Ali'], $row->params);
        $this->assertSame(['user_id' => $actor->id], $row->data);
        $this->assertSame($actor->id, $row->actor_id);
        $this->assertNull($row->read_at);
        // The stored row must NOT contain rendered text in any column.
        $this->assertStringNotContainsString('says hi', json_encode($row->getAttributes()));
    }

    public function test_unknown_type_is_skipped_silently(): void
    {
        $recipient = User::factory()->create();

        Notifier::send($recipient, 'does.not.exist', params: ['x' => 1]);

        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_disabled_preference_mutes_the_category(): void
    {
        $recipient = User::factory()->create();

        NotificationPreference::create([
            'user_id'  => $recipient->id,
            'category' => 'test',
            'channel'  => null, // all channels
            'enabled'  => false,
        ]);

        Notifier::send($recipient, 'test.greet', params: ['name' => 'Ali']);

        $this->assertDatabaseCount('notifications', 0);
    }

    public function test_to_admins_stores_a_shared_admin_row_not_in_user_feed(): void
    {
        $user = User::factory()->create();

        Notifier::toAdmins('test.greet', params: ['name' => 'Reporter'], data: ['real_id' => 7]);

        // One admin-audience row, addressed to all admins (id 0).
        $admin = Notification::forAdmins()->firstOrFail();
        $this->assertSame('admin', $admin->notifiable_type);
        $this->assertSame(0, (int) $admin->notifiable_id);
        $this->assertSame(['real_id' => 7], $admin->data);

        // It must NOT leak into any user's in-app feed.
        $this->assertSame(0, Notification::forUser($user->id)->count());
    }

    public function test_broadcast_fans_out_to_every_user(): void
    {
        User::factory()->count(3)->create();

        // QUEUE_CONNECTION=sync in phpunit.xml → the job runs immediately.
        Notifier::broadcast('system.announcement', [
            'title' => ['en' => 'Hello', 'ar' => 'مرحبا'],
            'body'  => ['en' => 'Big news', 'ar' => 'خبر مهم'],
        ]);

        $this->assertDatabaseCount('notifications', 3);
    }
}
