<?php

namespace Utd\Moment\Tests\Feature;

use App\Contracts\FollowProvider;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Tests\TestCase;
use Utd\Moment\Entities\Moment;
use Utd\Moment\Entities\MomentCommentLikes;
use Utd\Moment\Entities\MomentCommint;
use Utd\Moment\Entities\MomentGallery;
use Utd\Moment\Entities\MomentLikes;
use Utd\Moment\Entities\ReportMoment;
use Utd\Moment\Http\Repositories\MomentRepository;
use Utd\Moment\Http\Services\MomentCommentsService;
use Utd\Moment\Http\Services\MomentLikesService;
use Utd\Moment\Http\Services\MomentService;
use Utd\Moment\Profile\MomentProfileContributor;

/**
 * Internal-logic (non-HTTP) coverage for the Moment package: services resolved
 * from the container, the repository's feed building/ordering, entity
 * relationships + scopes, and the profile contributor. HTTP endpoints are
 * already covered by MomentApiTest / EndpointCoverageTest.
 */
class InternalLogicTest extends TestCase
{
    use RefreshDatabase;

    private function service(): MomentService
    {
        return app(MomentService::class);
    }

    // =====================================================================
    // MomentService
    // =====================================================================

    public function test_get_moments_by_type_unknown_type_returns_null(): void
    {
        $u = User::factory()->create();

        $this->assertNull($this->service()->getMomentsByType(99, $u->id, 1, $u->id));
    }

    public function test_get_moments_by_type_user_moments_filters_by_author(): void
    {
        $author = User::factory()->create();
        $other  = User::factory()->create();
        Moment::create(['user_id' => $author->id, 'description' => 'mine']);
        Moment::create(['user_id' => $other->id, 'description' => 'theirs']);

        $this->actingAs($author);
        $page = $this->service()->getMomentsByType(1, $author->id, 1, $author->id);

        $this->assertCount(1, $page->items());
        $this->assertSame('mine', $page->items()[0]->description);
    }

    public function test_get_moments_by_type_user_moments_falls_back_to_current_user(): void
    {
        $current = User::factory()->create();
        Moment::create(['user_id' => $current->id, 'description' => 'self feed']);

        $this->actingAs($current);
        // $userId = null → uses $currentUser.
        $page = $this->service()->getMomentsByType(1, null, 1, $current->id);

        $this->assertCount(1, $page->items());
        $this->assertSame('self feed', $page->items()[0]->description);
    }

    public function test_get_moments_by_type_all_returns_paginator(): void
    {
        $author = User::factory()->create();
        Moment::create(['user_id' => $author->id, 'description' => 'a']);
        Moment::create(['user_id' => $author->id, 'description' => 'b']);

        $this->actingAs($author);
        $page = $this->service()->getMomentsByType(4, null, 1, $author->id);

        $this->assertSame(2, $page->total());
    }

    public function test_delete_moment_by_id_missing_returns_404(): void
    {
        $result = $this->service()->deleteMomentById(999999, 1);

        $this->assertFalse($result['success']);
        $this->assertSame(404, $result['status']);
    }

    public function test_delete_moment_by_id_rejects_non_owner(): void
    {
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'x']);

        $result = $this->service()->deleteMomentById($moment->id, $owner->id + 999);

        $this->assertFalse($result['success']);
        $this->assertSame(403, $result['status']);
        $this->assertDatabaseHas('moment', ['id' => $moment->id]);
    }

    public function test_delete_moment_by_id_owner_succeeds(): void
    {
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'x']);

        $result = $this->service()->deleteMomentById($moment->id, $owner->id);

        $this->assertTrue($result['success']);
        $this->assertSame(200, $result['status']);
        $this->assertDatabaseMissing('moment', ['id' => $moment->id]);
    }

    public function test_delete_moment_by_id_skips_ownership_check_when_userid_null(): void
    {
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'admin delete']);

        // $userId === null → admin path, no ownership guard.
        $result = $this->service()->deleteMomentById($moment->id, null);

        $this->assertTrue($result['success']);
        $this->assertDatabaseMissing('moment', ['id' => $moment->id]);
    }

    public function test_delete_moment_and_report_removes_both(): void
    {
        $owner = User::factory()->create();
        $reporter = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'reported']);
        $report = ReportMoment::create([
            'moment_id'   => $moment->id,
            'Reporter_id' => $reporter->id,
            'Reported_id' => $owner->id,
            'description' => 'spam',
            'type'        => 'abuse',
        ]);

        $result = $this->service()->deleteMomentAndReport($moment->id, $report->id);

        $this->assertTrue($result['success']);
        $this->assertSame(200, $result['status']);
        $this->assertDatabaseMissing('moment', ['id' => $moment->id]);
        $this->assertDatabaseMissing('report_moments', ['id' => $report->id]);
    }

    public function test_delete_moment_and_report_missing_moment_returns_404(): void
    {
        $result = $this->service()->deleteMomentAndReport(999999, 1);

        $this->assertFalse($result['success']);
        $this->assertSame(404, $result['status']);
    }

    public function test_create_moment_rejects_empty_content(): void
    {
        $u = User::factory()->create();
        $this->actingAs($u);

        $request = Request::create('/api/moment', 'POST', ['contacts' => '']);
        $result = $this->service()->createMoment('', $request);

        $this->assertFalse($result['success']);
        $this->assertDatabaseCount('moment', 0);
    }

    public function test_create_moment_persists_text(): void
    {
        $u = User::factory()->create();
        $this->actingAs($u);

        $request = Request::create('/api/moment', 'POST', ['contacts' => 'hi there']);
        $result = $this->service()->createMoment('hi there', $request);

        $this->assertTrue($result['success']);
        $this->assertDatabaseHas('moment', ['user_id' => $u->id, 'description' => 'hi there']);
    }

    public function test_get_moment_missing_returns_404_envelope(): void
    {
        $u = User::factory()->create();

        $result = $this->service()->getMoment(999999, $u->id);

        $this->assertFalse($result['success']);
        $this->assertNull($result['data']);
        $this->assertSame(404, $result['status']);
    }

    public function test_get_moment_returns_hydrated_model_with_counts(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'counted']);
        $moment->likes()->create(['user_id' => $viewer->id]);
        $moment->comments()->create(['user_id' => $viewer->id, 'comment' => 'c']);

        $result = $this->service()->getMoment($moment->id, $viewer->id);

        $this->assertTrue($result['success']);
        $this->assertSame(1, (int) $result['data']->likes_count);
        $this->assertSame(1, (int) $result['data']->comments_count);
        // likeExists scope flag for the viewer.
        $this->assertTrue((bool) $result['data']->likes_exists);
    }

    public function test_service_delete_accepts_int_or_model(): void
    {
        $owner = User::factory()->create();
        $m1 = Moment::create(['user_id' => $owner->id, 'description' => 'a']);
        $m2 = Moment::create(['user_id' => $owner->id, 'description' => 'b']);

        $this->service()->delete($m1->id);
        $this->service()->delete($m2);

        $this->assertDatabaseMissing('moment', ['id' => $m1->id]);
        $this->assertDatabaseMissing('moment', ['id' => $m2->id]);
    }

    public function test_service_delete_missing_id_is_noop(): void
    {
        // Should not throw on an unknown id.
        $this->service()->delete(999999);
        $this->assertTrue(true);
    }

    // =====================================================================
    // MomentLikesService
    // =====================================================================

    public function test_like_service_like_then_unlike_toggles(): void
    {
        $svc = app(MomentLikesService::class);
        $owner = User::factory()->create();
        $liker = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        $this->assertSame('Like', $svc->likeOrUnLike($moment, $liker));
        $this->assertDatabaseHas('moment_user_likes', ['moment_id' => $moment->id, 'user_id' => $liker->id]);

        $this->assertSame('un Like', $svc->likeOrUnLike($moment, $liker));
        $this->assertDatabaseMissing('moment_user_likes', ['moment_id' => $moment->id, 'user_id' => $liker->id]);
    }

    public function test_like_service_react_add_switch_remove(): void
    {
        $svc = app(MomentLikesService::class);
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        $this->assertSame('reacted', $svc->react($moment, $user, 'love'));
        $this->assertSame('updated', $svc->react($moment, $user, 'haha'));
        $this->assertDatabaseHas('moment_user_likes', [
            'moment_id' => $moment->id, 'user_id' => $user->id, 'reaction_type' => 'haha',
        ]);
        $this->assertSame('removed', $svc->react($moment, $user, 'haha'));
        $this->assertDatabaseMissing('moment_user_likes', ['moment_id' => $moment->id, 'user_id' => $user->id]);
    }

    public function test_like_service_delete_by_id(): void
    {
        $svc = app(MomentLikesService::class);
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);
        $like = $moment->likes()->create(['user_id' => $user->id]);

        $svc->delete($like->id, $moment);

        $this->assertDatabaseMissing('moment_user_likes', ['id' => $like->id]);
    }

    public function test_like_service_show_likes_paginates(): void
    {
        $svc = app(MomentLikesService::class);
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);
        $liker = User::factory()->create();
        $moment->likes()->create(['user_id' => $liker->id]);

        $page = $svc->showLikes($moment);

        $this->assertSame(1, $page->total());
        $this->assertTrue($page->items()[0]->relationLoaded('user'));
    }

    // =====================================================================
    // MomentCommentsService
    // =====================================================================

    public function test_comment_service_add(): void
    {
        $svc = app(MomentCommentsService::class);
        $owner = User::factory()->create();
        $commenter = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        $this->assertTrue($svc->add(['comment' => 'nice'], $moment, $commenter));
        $this->assertDatabaseHas('moment_user_comments', [
            'moment_id' => $moment->id, 'user_id' => $commenter->id, 'comment' => 'nice',
        ]);
    }

    public function test_comment_service_delete_cascades_replies(): void
    {
        $svc = app(MomentCommentsService::class);
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        $parent = MomentCommint::create(['user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'parent']);
        $reply  = MomentCommint::create([
            'user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'reply', 'parent_id' => $parent->id,
        ]);

        $svc->delete($parent->id, $moment);

        // Both the parent and its reply are gone (no orphaned replies resurfacing).
        $this->assertDatabaseMissing('moment_user_comments', ['id' => $parent->id]);
        $this->assertDatabaseMissing('moment_user_comments', ['id' => $reply->id]);
    }

    public function test_comment_service_delete_missing_returns_false_string(): void
    {
        $svc = app(MomentCommentsService::class);
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        $this->assertSame('false', $svc->delete(999999, $moment));
    }

    public function test_comment_react_add_switch_remove(): void
    {
        $svc = app(MomentCommentsService::class);
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);
        $comment = MomentCommint::create(['user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'c']);

        $this->assertSame('reacted', $svc->reactToComment($comment, $user, 'love'));
        $this->assertSame('updated', $svc->reactToComment($comment, $user, 'wow'));
        $this->assertDatabaseHas('moment_comment_likes', [
            'comment_id' => $comment->id, 'user_id' => $user->id, 'reaction_type' => 'wow',
        ]);
        $this->assertSame('removed', $svc->reactToComment($comment, $user, 'wow'));
        $this->assertDatabaseMissing('moment_comment_likes', ['comment_id' => $comment->id, 'user_id' => $user->id]);
    }

    public function test_show_comments_returns_only_top_level_with_replies(): void
    {
        $svc = app(MomentCommentsService::class);
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);

        $parent = MomentCommint::create(['user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'top']);
        MomentCommint::create([
            'user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'reply', 'parent_id' => $parent->id,
        ]);

        $page = $svc->showComments($moment);

        // Only one TOP-LEVEL comment is paginated; its reply is nested.
        $this->assertSame(1, $page->total());
        $top = $page->items()[0];
        $this->assertSame('top', $top->comment);
        $this->assertTrue($top->relationLoaded('replies'));
        $this->assertCount(1, $top->replies);
    }

    // =====================================================================
    // MomentRepository — feed building / ordering
    // =====================================================================

    public function test_repository_all_moments_floats_unliked_above_liked(): void
    {
        $repo = app(MomentRepository::class);
        $viewer = User::factory()->create();
        $author = User::factory()->create();
        $this->actingAs($viewer);

        $older = Moment::create(['user_id' => $author->id, 'description' => 'A-old']);
        $newer = Moment::create(['user_id' => $author->id, 'description' => 'B-new']);
        $newer->likes()->create(['user_id' => $viewer->id]); // viewer liked the newer → it sinks

        $page = $repo->getAllMoments($viewer->id, 1);

        $this->assertSame('A-old', $page->items()[0]->description);
    }

    public function test_repository_followed_filters_by_follow_provider(): void
    {
        $repo = app(MomentRepository::class);
        $viewer = User::factory()->create();
        $followed = User::factory()->create();
        $stranger = User::factory()->create();
        $this->actingAs($viewer);

        Moment::create(['user_id' => $followed->id, 'description' => 'from-followed']);
        Moment::create(['user_id' => $stranger->id, 'description' => 'from-stranger']);

        app()->bind(FollowProvider::class, fn () => new class($followed->id) implements FollowProvider {
            public function __construct(private int $id) {}
            public function followingIds(int $userId): array { return [$this->id]; }
        });

        $page = $repo->getFollowedMoments($viewer->id, 1);

        $this->assertCount(1, $page->items());
        $this->assertSame('from-followed', $page->items()[0]->description);
    }

    public function test_repository_followed_returns_empty_when_following_nobody(): void
    {
        $repo = app(MomentRepository::class);
        $viewer = User::factory()->create();
        $author = User::factory()->create();
        $this->actingAs($viewer);
        Moment::create(['user_id' => $author->id, 'description' => 'anything']);

        app()->bind(FollowProvider::class, fn () => new class implements FollowProvider {
            public function followingIds(int $userId): array { return []; }
        });

        $page = $repo->getFollowedMoments($viewer->id, 1);

        // followingIds [] → whereIn [0] → no rows.
        $this->assertCount(0, $page->items());
    }

    public function test_repository_followed_falls_back_to_full_feed_without_provider(): void
    {
        $repo = app(MomentRepository::class);
        $viewer = User::factory()->create();
        $author = User::factory()->create();
        $this->actingAs($viewer);
        Moment::create(['user_id' => $author->id, 'description' => 'anything']);

        $page = $repo->getFollowedMoments($viewer->id, 1);

        $this->assertGreaterThanOrEqual(1, $page->total());
    }

    public function test_repository_excludes_moments_with_no_author(): void
    {
        $repo = app(MomentRepository::class);
        $viewer = User::factory()->create();
        $ghost = User::factory()->create();
        $this->actingAs($viewer);

        Moment::create(['user_id' => $ghost->id, 'description' => 'orphan']);
        $ghost->delete(); // author gone → whereHas('user') filters it out

        $page = $repo->getAllMoments($viewer->id, 1);

        $this->assertCount(0, $page->items());
    }

    public function test_repository_hydrates_reaction_breakdown(): void
    {
        $repo = app(MomentRepository::class);
        $viewer = User::factory()->create();
        $author = User::factory()->create();
        $other = User::factory()->create();
        $this->actingAs($viewer);

        $moment = Moment::create(['user_id' => $author->id, 'description' => 'reacted']);
        MomentLikes::create(['moment_id' => $moment->id, 'user_id' => $viewer->id, 'reaction_type' => 'love']);
        MomentLikes::create(['moment_id' => $moment->id, 'user_id' => $other->id, 'reaction_type' => 'love']);

        $page = $repo->getAllMoments($viewer->id, 1);
        $m = $page->items()[0];

        $this->assertSame('love', $m->getAttribute('my_reaction_pre'));
        $this->assertSame(['love' => 2], $m->getAttribute('reactions_pre'));
    }

    public function test_repository_get_liked_moments_returns_likes_for_user(): void
    {
        $repo = app(MomentRepository::class);
        $viewer = User::factory()->create();
        $author = User::factory()->create();
        $this->actingAs($viewer);

        $moment = Moment::create(['user_id' => $author->id, 'description' => 'liked one']);
        $moment->likes()->create(['user_id' => $viewer->id]);

        $page = $repo->getLikedMoments($viewer->id, 1);

        $this->assertSame(1, $page->total());
        $this->assertSame($moment->id, $page->items()[0]->moment_id);
    }

    // =====================================================================
    // Entities — relationships, scopes, casts
    // =====================================================================

    public function test_moment_relationships(): void
    {
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'rel']);
        $comment = MomentCommint::create(['user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'c']);
        $moment->likes()->create(['user_id' => $owner->id]);
        MomentGallery::create(['moment_id' => $moment->id, 'image' => 'a.jpg']);
        ReportMoment::create([
            'moment_id' => $moment->id, 'Reporter_id' => $owner->id, 'Reported_id' => $owner->id,
            'description' => 'd', 'type' => 't',
        ]);

        $moment->refresh();
        $this->assertCount(1, $moment->comments);
        $this->assertCount(1, $moment->likes);
        $this->assertCount(1, $moment->images);
        $this->assertCount(1, $moment->reports);
        $this->assertSame($owner->id, $moment->user->id);
        $this->assertInstanceOf(Moment::class, $comment->moment);
    }

    public function test_moment_like_exists_scope_reflects_viewer(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        $stranger = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);
        $moment->likes()->create(['user_id' => $viewer->id]);

        $forViewer = Moment::where('id', $moment->id)->likeExists($viewer->id)->first();
        $forStranger = Moment::where('id', $moment->id)->likeExists($stranger->id)->first();

        $this->assertTrue((bool) $forViewer->likes_exists);
        $this->assertFalse((bool) $forStranger->likes_exists);
    }

    public function test_comment_replies_and_parent_relationship(): void
    {
        $owner = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);
        $parent = MomentCommint::create(['user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'p']);
        $reply = MomentCommint::create([
            'user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'r', 'parent_id' => $parent->id,
        ]);

        $this->assertCount(1, $parent->replies);
        $this->assertSame($parent->id, $reply->parent->id);
    }

    public function test_comment_likes_relationship(): void
    {
        $owner = User::factory()->create();
        $user = User::factory()->create();
        $moment = Moment::create(['user_id' => $owner->id, 'description' => 'm']);
        $comment = MomentCommint::create(['user_id' => $owner->id, 'moment_id' => $moment->id, 'comment' => 'c']);
        $like = MomentCommentLikes::create(['comment_id' => $comment->id, 'user_id' => $user->id, 'reaction_type' => 'love']);

        $this->assertCount(1, $comment->likes);
        $this->assertSame($comment->id, $like->comment->id);
    }

    // =====================================================================
    // MomentProfileContributor
    // =====================================================================

    public function test_profile_contributor_key_and_count(): void
    {
        $contributor = new MomentProfileContributor();
        $this->assertSame('moments', $contributor->key());

        $target = User::factory()->create();
        Moment::create(['user_id' => $target->id, 'description' => 'a']);
        Moment::create(['user_id' => $target->id, 'description' => 'b']);
        Moment::create(['user_id' => User::factory()->create()->id, 'description' => 'someone else']);

        $section = $contributor->contribute($target, null);

        $this->assertSame(2, $section['count']);
    }
}
