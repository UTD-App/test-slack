<?php

namespace Utd\Moment\Tests\Feature;

use App\Contracts\FollowProvider;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Moment\Entities\Moment;

class MomentApiTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        return [$user, $token];
    }

    public function test_user_can_create_a_text_moment(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/moment', ['contacts' => 'Hello world'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('moment', ['description' => 'Hello world']);
    }

    public function test_empty_moment_is_rejected(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/moment', ['contacts' => ''])
            ->assertStatus(200)
            ->assertJsonPath('status', false);
    }

    public function test_feed_lists_moments(): void
    {
        [$user, $token] = $this->actingUser();
        Moment::create(['user_id' => $user->id, 'description' => 'first']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment?type=4')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.0.description', 'first');
    }

    public function test_user_can_like_and_unlike(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'likeable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/like")
            ->assertStatus(200);
        $this->assertDatabaseHas('moment_user_likes', ['moment_id' => $moment->id]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/like")
            ->assertStatus(200);
        $this->assertDatabaseMissing('moment_user_likes', ['moment_id' => $moment->id]);
    }

    public function test_user_can_comment(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'commentable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment", ['comment' => 'nice!'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('moment_user_comments', ['moment_id' => $moment->id, 'comment' => 'nice!']);
    }

    public function test_user_can_report_a_moment(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'reportable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/report", ['description' => 'spam', 'type' => 'abuse'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('report_moments', ['moment_id' => $moment->id, 'type' => 'abuse']);
    }

    public function test_gift_endpoint_is_active_when_gifts_installed(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'giftable']);

        [, $token] = $this->actingUser();

        // The Gifts package binds GiftSender, so the endpoint is no longer 503.
        // An unknown gift id is processed and rejected with 402 (not 503).
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/gift", ['gift_id' => 999999, 'num' => 1])
            ->assertStatus(402)
            ->assertJsonPath('status', false);
    }

    public function test_feed_floats_unliked_moments_above_liked_ones(): void
    {
        [$viewer, $token] = $this->actingUser();
        [$author] = $this->actingUser();

        $older = Moment::create(['user_id' => $author->id, 'description' => 'A-old']);
        $newer = Moment::create(['user_id' => $author->id, 'description' => 'B-new']);

        // Viewer already liked the NEWER moment → it should sink below the
        // un-liked older one (Eagle parity: liked moments float down).
        $newer->likes()->create(['user_id' => $viewer->id]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment?type=4')
            ->assertStatus(200)
            ->assertJsonPath('data.0.description', 'A-old');
    }

    public function test_following_feed_filters_by_follow_provider_when_bound(): void
    {
        [, $token] = $this->actingUser();
        [$followed] = $this->actingUser();
        [$stranger] = $this->actingUser();

        Moment::create(['user_id' => $followed->id, 'description' => 'from-followed']);
        Moment::create(['user_id' => $stranger->id, 'description' => 'from-stranger']);

        app()->bind(FollowProvider::class, fn () => new class($followed->id) implements FollowProvider {
            public function __construct(private int $id) {}
            public function followingIds(int $userId): array { return [$this->id]; }
        });

        $data = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment?type=3')
            ->assertStatus(200)
            ->json('data');

        $this->assertCount(1, $data);
        $this->assertEquals('from-followed', $data[0]['description']);
    }

    public function test_following_feed_falls_back_to_full_feed_without_provider(): void
    {
        [, $token] = $this->actingUser();
        [$author] = $this->actingUser();
        Moment::create(['user_id' => $author->id, 'description' => 'anything']);

        $data = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment?type=3')
            ->assertStatus(200)
            ->json('data');

        $this->assertGreaterThanOrEqual(1, count($data));
    }

    public function test_moment_routes_require_auth(): void
    {
        $this->getJson('/api/moment?type=4')->assertStatus(401);
    }
}
