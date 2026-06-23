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

    /**
     * Send the next request as a specific bearer token. Clears the resolved auth
     * guard first so a multi-user test doesn't reuse the previous request's
     * cached user (which would trip CheckLatestToken with a 505).
     */
    private function asToken(string $token): self
    {
        $this->app['auth']->forgetGuards();

        return $this->withHeader('Authorization', "Bearer {$token}");
    }

    /** S2 — a stranger cannot delete someone else's comment; the author can. */
    public function test_only_comment_author_or_moment_owner_can_delete_comment(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'has-comments']);

        [$authorA, $tokenA] = $this->actingUser();
        $this->asToken($tokenA)
            ->postJson("/api/moment/{$moment->id}/comment", ['comment' => 'mine'])
            ->assertStatus(200);
        $commentId = \Utd\Moment\Entities\MomentCommint::where('user_id', $authorA->id)->value('id');

        // A stranger (not author, not moment owner) is rejected with 403.
        [, $tokenB] = $this->actingUser();
        $this->asToken($tokenB)
            ->deleteJson("/api/moment/{$moment->id}/comment/{$commentId}")
            ->assertStatus(403);
        $this->assertDatabaseHas('moment_user_comments', ['id' => $commentId]);

        // The author can delete their own comment.
        $this->asToken($tokenA)
            ->deleteJson("/api/moment/{$moment->id}/comment/{$commentId}")
            ->assertStatus(200);
        $this->assertDatabaseMissing('moment_user_comments', ['id' => $commentId]);
    }

    /** S2 — the moment owner may moderate (delete) any comment on their moment. */
    public function test_moment_owner_can_delete_any_comment_on_their_moment(): void
    {
        [$owner, $ownerToken] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'mod']);

        [$commenter, $commenterToken] = $this->actingUser();
        $this->asToken($commenterToken)
            ->postJson("/api/moment/{$moment->id}/comment", ['comment' => 'hi'])
            ->assertStatus(200);
        $commentId = \Utd\Moment\Entities\MomentCommint::where('user_id', $commenter->id)->value('id');

        $this->asToken($ownerToken)
            ->deleteJson("/api/moment/{$moment->id}/comment/{$commentId}")
            ->assertStatus(200);
        $this->assertDatabaseMissing('moment_user_comments', ['id' => $commentId]);
    }
}
