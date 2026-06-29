<?php

namespace Utd\Reels\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealUserComment;

/**
 * Facebook-style reactions + rich comments (replies, comment reactions, comment
 * reports) on reels — ported from the moments package.
 */
class ReelsReactionsTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        return [$user, $token];
    }

    private function reel(): Real
    {
        [$owner] = $this->actingUser();

        return Real::create(['user_id' => $owner->id, 'url' => 'videos/x.mp4', 'description' => 'r']);
    }

    public function test_react_to_a_reel_stores_the_type_and_counter(): void
    {
        $real = $this->reel();
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like", ['reaction_type' => 'love'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('real_user_likes', ['real_id' => $real->id, 'reaction_type' => 'love']);
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'like_num' => 1]);
    }

    public function test_feed_exposes_my_reaction_and_breakdown(): void
    {
        $real = $this->reel();
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like", ['reaction_type' => 'haha']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/reals')
            ->assertStatus(200)
            ->assertJsonPath('data.0.my_reaction', 'haha')
            ->assertJsonPath('data.0.reactions.haha', 1)
            ->assertJsonPath('data.0.likes_count', 1);
    }

    public function test_same_reaction_again_toggles_off(): void
    {
        $real = $this->reel();
        [, $token] = $this->actingUser();

        $react = fn () => $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like", ['reaction_type' => 'love']);

        $react()->assertStatus(200);
        $react()->assertStatus(200);

        $this->assertDatabaseMissing('real_user_likes', ['real_id' => $real->id]);
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'like_num' => 0]);
    }

    public function test_switching_reaction_keeps_one_row_and_counter(): void
    {
        $real = $this->reel();
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like", ['reaction_type' => 'love']);
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like", ['reaction_type' => 'angry']);

        $this->assertSame(1, $real->likes()->count());
        $this->assertDatabaseHas('real_user_likes', ['real_id' => $real->id, 'reaction_type' => 'angry']);
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'like_num' => 1]);
    }

    public function test_reply_is_nested_under_its_parent(): void
    {
        $real = $this->reel();
        [, $token] = $this->actingUser();

        $parent = RealUserComment::create(['user_id' => $real->user_id, 'real_id' => $real->id, 'comment' => 'parent']);
        $real->increment('comment_num');

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/comment", ['comment' => 'a reply', 'parent_id' => $parent->id])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('real_user_comments', ['real_id' => $real->id, 'comment' => 'a reply', 'parent_id' => $parent->id]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/reals/{$real->id}/comment")
            ->assertStatus(200)
            ->assertJsonPath('data.0.comment', 'parent')
            ->assertJsonPath('data.0.replies.0.comment', 'a reply');

        // Replies count toward the denormalized counter too.
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'comment_num' => 2]);
    }

    public function test_reply_to_a_reply_flattens_to_one_level(): void
    {
        $real = $this->reel();
        [, $token] = $this->actingUser();

        $parent = RealUserComment::create(['user_id' => $real->user_id, 'real_id' => $real->id, 'comment' => 'parent']);
        $reply = RealUserComment::create(['user_id' => $real->user_id, 'real_id' => $real->id, 'comment' => 'reply', 'parent_id' => $parent->id]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/comment", ['comment' => 'deep', 'parent_id' => $reply->id])
            ->assertStatus(200);

        // The new comment's parent is normalized back up to the top-level parent.
        $this->assertDatabaseHas('real_user_comments', ['comment' => 'deep', 'parent_id' => $parent->id]);
    }

    public function test_react_to_a_comment(): void
    {
        $real = $this->reel();
        [, $token] = $this->actingUser();

        $comment = RealUserComment::create(['user_id' => $real->user_id, 'real_id' => $real->id, 'comment' => 'c']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/comment/{$comment->id}/like", ['reaction_type' => 'love'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('real_comment_likes', ['comment_id' => $comment->id, 'reaction_type' => 'love']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/reals/{$real->id}/comment")
            ->assertStatus(200)
            ->assertJsonPath('data.0.like_num', 1)
            ->assertJsonPath('data.0.my_reaction', 'love')
            ->assertJsonPath('data.0.reactions.love', 1);
    }

    public function test_report_a_comment_then_duplicate_is_rejected(): void
    {
        $real = $this->reel();
        [, $token] = $this->actingUser();

        $comment = RealUserComment::create(['user_id' => $real->user_id, 'real_id' => $real->id, 'comment' => 'c']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/comment/{$comment->id}/report", ['description' => 'bad', 'type' => 'abuse'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('report_real_comments', ['comment_id' => $comment->id, 'type' => 'abuse']);

        // Second report by the same user is rejected (409 Conflict — duplicate).
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/comment/{$comment->id}/report", ['description' => 'again', 'type' => 'spam'])
            ->assertStatus(409)
            ->assertJsonPath('status', false);
    }

    public function test_deleting_a_top_level_comment_cascades_replies_and_counter(): void
    {
        $real = $this->reel();
        // The reel owner deletes (allowed). Author also allowed.
        $ownerToken = $real->user->createToken('t')->plainTextToken;

        $parent = RealUserComment::create(['user_id' => $real->user_id, 'real_id' => $real->id, 'comment' => 'parent']);
        RealUserComment::create(['user_id' => $real->user_id, 'real_id' => $real->id, 'comment' => 'reply', 'parent_id' => $parent->id]);
        $real->update(['comment_num' => 2]);

        $this->withHeader('Authorization', "Bearer {$ownerToken}")
            ->deleteJson("/api/reals/{$real->id}/comment/{$parent->id}")
            ->assertStatus(200);

        $this->assertDatabaseMissing('real_user_comments', ['real_id' => $real->id]);
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'comment_num' => 0]);
    }

    public function test_a_stranger_cannot_delete_a_comment(): void
    {
        $real = $this->reel();
        $comment = RealUserComment::create(['user_id' => $real->user_id, 'real_id' => $real->id, 'comment' => 'c']);

        // A third user who is neither the comment author nor the reel owner.
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/reals/{$real->id}/comment/{$comment->id}")
            ->assertStatus(403)
            ->assertJsonPath('status', false);

        $this->assertDatabaseHas('real_user_comments', ['id' => $comment->id]);
    }
}
