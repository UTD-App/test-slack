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

    public function test_empty_comment_is_rejected_not_500(): void
    {
        // The comment column is NOT-NULL VARCHAR(255); an empty/missing body must
        // return a clean error (status:false, 200) — not a raw SQL 500.
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'commentable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment", ['comment' => '   '])
            ->assertStatus(200)
            ->assertJsonPath('status', false);

        $this->assertDatabaseMissing('moment_user_comments', ['moment_id' => $moment->id]);
    }

    public function test_overlong_comment_is_rejected_not_500(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'commentable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment", ['comment' => str_repeat('a', 300)])
            ->assertStatus(200)
            ->assertJsonPath('status', false);

        $this->assertDatabaseMissing('moment_user_comments', ['moment_id' => $moment->id]);
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

    /**
     * Type-2 (liked) feed must return the MOMENTS the viewer liked — shaped like
     * MomentResource (a `description`, an `is_like` flag) — not the raw
     * MomentLikes rows. Previously getLikedMoments returned MomentLikes models,
     * which MomentResource::collection mis-rendered.
     */
    public function test_liked_feed_returns_liked_moments_in_resource_shape(): void
    {
        [$viewer, $token] = $this->actingUser();
        [$author] = $this->actingUser();

        $liked = Moment::create(['user_id' => $author->id, 'description' => 'liked-one']);
        $unliked = Moment::create(['user_id' => $author->id, 'description' => 'not-liked']);

        $liked->likes()->create(['user_id' => $viewer->id]);

        $data = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment?type=2')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->json('data');

        // Only the liked moment is returned, with the moment payload shape.
        $this->assertCount(1, $data);
        $this->assertSame($liked->id, $data[0]['id']);
        $this->assertSame('liked-one', $data[0]['description']);
        $this->assertTrue($data[0]['is_like']);
        $this->assertArrayHasKey('like_num', $data[0]);
        $this->assertArrayHasKey('user', $data[0]);

        $descriptions = array_column($data, 'description');
        $this->assertNotContains('not-liked', $descriptions);
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

    /**
     * A8 — the feed must return the author's avatar as an ABSOLUTE URL. A raw
     * stored path (avatars/x.jpg) would 404 against /storage on cloud setups.
     */
    public function test_feed_resolves_author_avatar_to_absolute_url(): void
    {
        [, $token] = $this->actingUser();
        [$author] = $this->actingUser();
        $author->profile()->updateOrCreate(['user_id' => $author->id], ['avatar' => 'avatars/qa.jpg']);
        Moment::create(['user_id' => $author->id, 'description' => 'with-avatar']);

        $image = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment?type=4')
            ->assertStatus(200)
            ->json('data.0.user.image');

        $this->assertNotSame('avatars/qa.jpg', $image, 'avatar must not be a raw path');
        $this->assertStringStartsWith('http', $image);
        $this->assertStringContainsString('avatars/qa.jpg', $image);
    }

    /** A8 — an avatar that is already an absolute URL is passed through unchanged. */
    public function test_feed_passes_through_absolute_avatar_url(): void
    {
        [, $token] = $this->actingUser();
        [$author] = $this->actingUser();
        $author->profile()->updateOrCreate(
            ['user_id' => $author->id],
            ['avatar' => 'https://cdn.example.com/a.jpg'],
        );
        Moment::create(['user_id' => $author->id, 'description' => 'http-avatar']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment?type=4')
            ->assertStatus(200)
            ->assertJsonPath('data.0.user.image', 'https://cdn.example.com/a.jpg');
    }
}
