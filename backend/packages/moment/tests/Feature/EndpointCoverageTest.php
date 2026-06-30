<?php

namespace Utd\Moment\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentComment;

/**
 * Endpoint coverage for the moment package: every route NOT already exercised by
 * MomentApiTest gets a focused test (auth / status / shape / one behaviour).
 * Routes already covered there: index, store, comment store, like store, report,
 * gift store. Covered here: userMoments, show, destroy, comment index, comment
 * react, comment report, comment destroy, like index, getGifts, userGift.
 */
class EndpointCoverageTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        return [$user, $token];
    }

    // ---------------------------------------------------------------------
    // GET moment/user/{user_id} — userMoments
    // ---------------------------------------------------------------------

    public function test_user_moments_returns_only_that_users_moments(): void
    {
        [$author] = $this->actingUser();
        [$other] = $this->actingUser();
        [, $token] = $this->actingUser();

        Moment::create(['user_id' => $author->id, 'description' => 'mine']);
        Moment::create(['user_id' => $other->id, 'description' => 'theirs']);

        $data = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/moment/user/{$author->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->json('data');

        $this->assertCount(1, $data);
        $this->assertSame('mine', $data[0]['description']);
    }

    public function test_user_moments_requires_auth(): void
    {
        $user = User::factory()->create();

        $this->getJson("/api/moment/user/{$user->id}")->assertStatus(401);
    }

    // ---------------------------------------------------------------------
    // GET moment/{id} — show
    // ---------------------------------------------------------------------

    public function test_show_returns_a_single_moment(): void
    {
        [$author] = $this->actingUser();
        $moment = Moment::create(['user_id' => $author->id, 'description' => 'one moment']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/moment/{$moment->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.id', $moment->id)
            ->assertJsonPath('data.description', 'one moment');
    }

    public function test_show_missing_moment_returns_404(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment/999999')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    // ---------------------------------------------------------------------
    // DELETE moment/{id} — destroy
    // ---------------------------------------------------------------------

    public function test_owner_can_delete_own_moment(): void
    {
        [$owner, $token] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'deletable']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/moment/{$moment->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseMissing('moment', ['id' => $moment->id]);
    }

    public function test_user_cannot_delete_other_users_moment(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'not yours']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/moment/{$moment->id}")
            ->assertStatus(403)
            ->assertJsonPath('status', false);

        $this->assertDatabaseHas('moment', ['id' => $moment->id]);
    }

    public function test_delete_missing_moment_returns_404(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson('/api/moment/999999')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    // ---------------------------------------------------------------------
    // GET moment/{id}/comment — comment index
    // ---------------------------------------------------------------------

    public function test_comment_index_lists_top_level_comments(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'has comments']);

        [$commenter, $token] = $this->actingUser();
        MomentComment::create([
            'user_id'   => $commenter->id,
            'moment_id' => $moment->id,
            'comment'   => 'top level',
        ]);

        $data = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/moment/{$moment->id}/comment")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->json('data');

        $this->assertCount(1, $data);
        $this->assertSame('top level', $data[0]['comment']);
    }

    public function test_comment_index_missing_moment_returns_404(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment/999999/comment')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    // ---------------------------------------------------------------------
    // POST moment/{id}/comment/{id}/like — react
    // ---------------------------------------------------------------------

    public function test_comment_react_creates_a_reaction(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'reactable']);
        $comment = MomentComment::create([
            'user_id'   => $owner->id,
            'moment_id' => $moment->id,
            'comment'   => 'react to me',
        ]);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment/{$comment->id}/like", ['reaction_type' => 'love'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('moment_comment_likes', [
            'comment_id'    => $comment->id,
            'reaction_type' => 'love',
        ]);
    }

    public function test_comment_react_toggles_off_on_repeat(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'toggle']);
        $comment = MomentComment::create([
            'user_id'   => $owner->id,
            'moment_id' => $moment->id,
            'comment'   => 'toggle me',
        ]);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment/{$comment->id}/like")
            ->assertStatus(200);
        $this->assertDatabaseHas('moment_comment_likes', ['comment_id' => $comment->id]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment/{$comment->id}/like")
            ->assertStatus(200);
        $this->assertDatabaseMissing('moment_comment_likes', ['comment_id' => $comment->id]);
    }

    public function test_comment_react_missing_comment_returns_404(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'no comment']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment/999999/like")
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    // ---------------------------------------------------------------------
    // POST moment/{id}/comment/{id}/report — comment report
    // ---------------------------------------------------------------------

    public function test_comment_report_creates_a_report_row(): void
    {
        [$author] = $this->actingUser();
        $moment = Moment::create(['user_id' => $author->id, 'description' => 'reportable']);
        $comment = MomentComment::create([
            'user_id'   => $author->id,
            'moment_id' => $moment->id,
            'comment'   => 'offensive',
        ]);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson(
                "/api/moment/{$moment->id}/comment/{$comment->id}/report",
                ['description' => 'spam', 'type' => 'abuse'],
            )
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('report_moment_comments', [
            'comment_id' => $comment->id,
            'moment_id'  => $moment->id,
            'type'       => 'abuse',
        ]);
    }

    public function test_comment_report_requires_description(): void
    {
        [$author] = $this->actingUser();
        $moment = Moment::create(['user_id' => $author->id, 'description' => 'm']);
        $comment = MomentComment::create([
            'user_id'   => $author->id,
            'moment_id' => $moment->id,
            'comment'   => 'c',
        ]);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment/{$comment->id}/report", ['type' => 'abuse'])
            ->assertStatus(200)
            ->assertJsonPath('status', false);
    }

    public function test_comment_report_duplicate_returns_409(): void
    {
        [$author] = $this->actingUser();
        $moment = Moment::create(['user_id' => $author->id, 'description' => 'm']);
        $comment = MomentComment::create([
            'user_id'   => $author->id,
            'moment_id' => $moment->id,
            'comment'   => 'c',
        ]);

        [, $token] = $this->actingUser();
        $body = ['description' => 'spam', 'type' => 'abuse'];

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment/{$comment->id}/report", $body)
            ->assertStatus(200);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/moment/{$moment->id}/comment/{$comment->id}/report", $body)
            ->assertStatus(409)
            ->assertJsonPath('status', false);
    }

    // ---------------------------------------------------------------------
    // DELETE moment/{id}/comment/{id} — comment destroy
    // ---------------------------------------------------------------------

    public function test_comment_author_can_delete_own_comment(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        [$commenter, $token] = $this->actingUser();
        $comment = MomentComment::create([
            'user_id'   => $commenter->id,
            'moment_id' => $moment->id,
            'comment'   => 'mine to delete',
        ]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/moment/{$moment->id}/comment/{$comment->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseMissing('moment_user_comments', ['id' => $comment->id]);
    }

    public function test_moment_owner_can_delete_any_comment(): void
    {
        [$owner, $token] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        [$commenter] = $this->actingUser();
        $comment = MomentComment::create([
            'user_id'   => $commenter->id,
            'moment_id' => $moment->id,
            'comment'   => 'on my moment',
        ]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/moment/{$moment->id}/comment/{$comment->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseMissing('moment_user_comments', ['id' => $comment->id]);
    }

    public function test_stranger_cannot_delete_comment(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        [$commenter] = $this->actingUser();
        $comment = MomentComment::create([
            'user_id'   => $commenter->id,
            'moment_id' => $moment->id,
            'comment'   => 'not yours',
        ]);

        [, $token] = $this->actingUser(); // neither moment owner nor comment author

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/moment/{$moment->id}/comment/{$comment->id}")
            ->assertStatus(403)
            ->assertJsonPath('status', false);

        $this->assertDatabaseHas('moment_user_comments', ['id' => $comment->id]);
    }

    // ---------------------------------------------------------------------
    // GET moment/{id}/like — like index
    // ---------------------------------------------------------------------

    public function test_like_index_lists_likers(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'liked']);

        [$liker, $token] = $this->actingUser();
        $moment->likes()->create(['user_id' => $liker->id]);

        $data = $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/moment/{$moment->id}/like")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->json('data');

        $this->assertCount(1, $data);
    }

    public function test_like_index_missing_moment_returns_404(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/moment/999999/like')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    // ---------------------------------------------------------------------
    // GET moments/{id}/gifts — getGifts
    // ---------------------------------------------------------------------

    public function test_get_gifts_returns_aggregated_gifts(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'giftable']);

        [, $token] = $this->actingUser();

        // Gifts package binds GiftDirectory in tests → endpoint is active (200);
        // a moment with no gifts yields an empty list.
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/moments/{$moment->id}/gifts")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data', []);
    }

    // ---------------------------------------------------------------------
    // GET moments/users/{id}/gifts — userGift
    // ---------------------------------------------------------------------

    public function test_user_gift_returns_gifters_list(): void
    {
        [$owner] = $this->actingUser();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'giftable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/moments/{$moment->id}/gifts")
            ->assertStatus(200);

        // The "who gifted" endpoint — empty when no gifts were sent.
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/moments/users/{$moment->id}/gifts")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data', []);
    }
}
