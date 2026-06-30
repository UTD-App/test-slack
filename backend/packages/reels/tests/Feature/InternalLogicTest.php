<?php

namespace Utd\Reels\Tests\Feature;

use App\Contracts\MediaUploader;
use App\Models\User;
use App\Support\Media\MediaResult;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Bus;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealCategory;
use Utd\Reels\Entities\RealUserComment;
use Utd\Reels\Entities\RealUserLike;
use Utd\Reels\Entities\RealUserView;
use Utd\Reels\Entities\ReportReals;
use Utd\Reels\Http\Repositories\ReelsRepository;
use Utd\Reels\Http\Services\RealCommentsService;
use Utd\Reels\Http\Services\RealLikesService;
use Utd\Reels\Http\Services\RealsService;
use Utd\Reels\Http\Services\RealViewsService;
use Utd\Reels\Jobs\ProcessReelVideo;

/**
 * Direct unit/service coverage for the Reels internals the endpoint tests don't
 * reach: the like/view/comment services (counter maintenance + reactions), the
 * RealsService write path (ownership, category sync), the feed repository, the
 * Real entity, and the ProcessReelVideo job's best-effort no-op branches.
 */
class InternalLogicTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Cache::flush();

        // Stub the Base MediaUploader so RealsService::create/update never touch
        // real storage (and the best-effort FFMpeg frame extraction has a fake url).
        $this->app->bind(MediaUploader::class, fn () => new class implements MediaUploader {
            public function upload(UploadedFile $file, string $folder = 'uploads', array $options = []): MediaResult
            {
                return new MediaResult(path: 'videos/fake.mp4', url: 'https://example.com/videos/fake.mp4');
            }

            public function putContents(string $path, string $contents, array $options = []): MediaResult
            {
                return new MediaResult(path: $path, url: 'https://example.com/' . $path);
            }

            public function url(string $path): string
            {
                return 'https://example.com/' . $path;
            }

            public function delete(string $path): bool
            {
                return true;
            }
        });
    }

    private function reel(?User $owner = null, array $attrs = []): Real
    {
        $owner ??= User::factory()->create();

        return Real::create(array_merge([
            'user_id'     => $owner->id,
            'url'         => 'videos/x.mp4',
            'description' => 'A reel',
        ], $attrs));
    }

    // ----------------------------------------------------------------------
    // RealLikesService — toggle / reactions / counter maintenance
    // ----------------------------------------------------------------------

    private function likes(): RealLikesService
    {
        return app(RealLikesService::class);
    }

    public function test_add_creates_like_row_and_increments_counter(): void
    {
        $reel = $this->reel();
        $user = User::factory()->create();

        $this->assertTrue($this->likes()->add($reel, $user));

        $this->assertDatabaseHas('real_user_likes', ['real_id' => $reel->id, 'user_id' => $user->id]);
        $this->assertSame(1, $reel->fresh()->like_num);
    }

    public function test_like_or_unlike_toggles_row_and_counter(): void
    {
        $reel = $this->reel();
        $user = User::factory()->create();

        $this->assertSame('Like', $this->likes()->likeOrUnLike($reel, $user));
        $this->assertSame(1, $reel->fresh()->like_num);

        $this->assertSame('un Like', $this->likes()->likeOrUnLike($reel, $user));
        $this->assertSame(0, $reel->fresh()->like_num);
        $this->assertDatabaseMissing('real_user_likes', ['real_id' => $reel->id, 'user_id' => $user->id]);
    }

    public function test_react_adds_switches_and_removes_with_correct_counter(): void
    {
        $reel = $this->reel();
        $user = User::factory()->create();
        $svc = $this->likes();

        // new reaction → 'reacted', counter +1
        $this->assertSame('reacted', $svc->react($reel, $user, 'love'));
        $this->assertSame(1, $reel->fresh()->like_num);

        // switch type → 'updated', counter unchanged, one row
        $this->assertSame('updated', $svc->react($reel, $user, 'angry'));
        $this->assertSame(1, $reel->fresh()->like_num);
        $this->assertSame(1, RealUserLike::where('real_id', $reel->id)->count());
        $this->assertSame('angry', RealUserLike::where('real_id', $reel->id)->value('reaction_type'));

        // same type again → 'removed', counter -1
        $this->assertSame('removed', $svc->react($reel, $user, 'angry'));
        $this->assertSame(0, $reel->fresh()->like_num);
    }

    public function test_delete_with_ownership_scope_only_removes_own_like(): void
    {
        $reel = $this->reel();
        $owner = User::factory()->create();
        $other = User::factory()->create();
        $svc = $this->likes();
        $svc->add($reel, $owner);
        $likeId = RealUserLike::where('user_id', $owner->id)->value('id');

        // wrong user → no delete, counter stays
        $svc->delete($likeId, $reel, $other->id);
        $this->assertSame(1, $reel->fresh()->like_num);
        $this->assertDatabaseHas('real_user_likes', ['id' => $likeId]);

        // correct user → deleted, counter drops
        $svc->delete($likeId, $reel, $owner->id);
        $this->assertSame(0, $reel->fresh()->like_num);
        $this->assertDatabaseMissing('real_user_likes', ['id' => $likeId]);
    }

    public function test_counter_never_drops_below_zero_on_stale_delete(): void
    {
        // like_num already 0 but a like row exists (simulating drift) → delete must
        // not push the counter negative.
        $reel = $this->reel();
        $user = User::factory()->create();
        RealUserLike::create(['real_id' => $reel->id, 'user_id' => $user->id, 'reaction_type' => 'like']);
        $this->assertSame(0, $reel->fresh()->like_num);

        $this->likes()->delete(RealUserLike::first()->id, $reel);

        $this->assertSame(0, $reel->fresh()->like_num); // clamped, not -1
    }

    public function test_show_likes_paginates_with_user(): void
    {
        $reel = $this->reel();
        $u1 = User::factory()->create();
        $u2 = User::factory()->create();
        $this->likes()->add($reel, $u1);
        $this->likes()->add($reel, $u2);

        $page = $this->likes()->showLikes($reel);

        $this->assertSame(2, $page->total());
        $this->assertNotNull($page->items()[0]->user); // user eager-loaded
    }

    // ----------------------------------------------------------------------
    // RealViewsService — atomic counter
    // ----------------------------------------------------------------------

    public function test_view_add_increments_counter_and_reports_existence(): void
    {
        $reel = $this->reel();
        $svc = app(RealViewsService::class);

        $this->assertTrue($svc->add($reel->id));
        $this->assertTrue($svc->add($reel->id));
        $this->assertSame(2, $reel->fresh()->view_num);

        // Missing reel → no row affected → false.
        $this->assertFalse($svc->add(999999));
    }

    public function test_view_delete_removes_a_view_row(): void
    {
        $reel = $this->reel();
        $user = User::factory()->create();
        $view = RealUserView::create(['real_id' => $reel->id, 'user_id' => $user->id]);

        app(RealViewsService::class)->delete($view->id, $reel);

        $this->assertDatabaseMissing('real_user_views', ['id' => $view->id]);
    }

    // ----------------------------------------------------------------------
    // RealCommentsService — comments, replies, cascade, reactions
    // ----------------------------------------------------------------------

    private function comments(): RealCommentsService
    {
        return app(RealCommentsService::class);
    }

    public function test_add_comment_and_reply_increment_comment_num(): void
    {
        $reel = $this->reel();
        $user = User::factory()->create();
        $svc = $this->comments();

        $svc->add(['comment' => 'top'], $reel, $user);
        $parentId = RealUserComment::where('real_id', $reel->id)->value('id');

        $svc->add(['comment' => 'reply'], $reel, $user, $parentId);

        $this->assertSame(2, $reel->fresh()->comment_num); // replies count too
        $this->assertDatabaseHas('real_user_comments', ['parent_id' => $parentId, 'comment' => 'reply']);
    }

    public function test_delete_top_level_comment_cascades_replies_and_decrements_counter(): void
    {
        $reel = $this->reel();
        $user = User::factory()->create();
        $svc = $this->comments();

        $svc->add(['comment' => 'top'], $reel, $user);
        $parent = RealUserComment::first();
        $svc->add(['comment' => 'r1'], $reel, $user, $parent->id);
        $svc->add(['comment' => 'r2'], $reel, $user, $parent->id);
        $this->assertSame(3, $reel->fresh()->comment_num);

        $svc->delete($parent->id, $reel);

        // parent + 2 replies removed, counter back to 0
        $this->assertSame(0, RealUserComment::count());
        $this->assertSame(0, $reel->fresh()->comment_num);
    }

    public function test_delete_unknown_comment_is_noop(): void
    {
        $reel = $this->reel();
        // counter columns are NOT mass-assignable on Real → set + save directly.
        $reel->comment_num = 5;
        $reel->save();

        $this->assertFalse($this->comments()->delete(999999, $reel));
        $this->assertSame(5, $reel->fresh()->comment_num); // untouched
    }

    public function test_comment_counter_clamps_to_zero_when_drifted(): void
    {
        // comment_num intentionally lower than the actual rows → bulk delete must
        // not leave a negative counter.
        $reel = $this->reel();
        $user = User::factory()->create();
        $svc = $this->comments();
        $svc->add(['comment' => 'top'], $reel, $user);
        $parent = RealUserComment::first();
        $svc->add(['comment' => 'r1'], $reel, $user, $parent->id);

        $reel->comment_num = 1; // drift: 2 rows, counter says 1
        $reel->save();
        $svc->delete($parent->id, $reel);

        $this->assertSame(0, $reel->fresh()->comment_num); // clamped to 0, not -1
    }

    public function test_react_to_comment_adds_switches_and_removes(): void
    {
        $reel = $this->reel();
        $user = User::factory()->create();
        $svc = $this->comments();
        $svc->add(['comment' => 'top'], $reel, $user);
        $comment = RealUserComment::first();
        $reactor = User::factory()->create();

        $this->assertSame('reacted', $svc->reactToComment($comment, $reactor, 'love'));
        $this->assertDatabaseHas('real_comment_likes', ['comment_id' => $comment->id, 'reaction_type' => 'love']);

        $this->assertSame('updated', $svc->reactToComment($comment, $reactor, 'haha'));
        $this->assertSame(1, $comment->likes()->count());
        $this->assertSame('haha', $comment->likes()->first()->reaction_type);

        $this->assertSame('removed', $svc->reactToComment($comment, $reactor, 'haha'));
        $this->assertSame(0, $comment->likes()->count());
    }

    public function test_show_comments_returns_only_top_level_with_replies(): void
    {
        $reel = $this->reel();
        $user = User::factory()->create();
        $svc = $this->comments();
        $svc->add(['comment' => 'top'], $reel, $user);
        $parent = RealUserComment::first();
        $svc->add(['comment' => 'reply'], $reel, $user, $parent->id);

        $page = $svc->showComments($reel);

        $this->assertSame(1, $page->total());                 // only the top-level
        $this->assertCount(1, $page->items()[0]->replies);    // reply nested
    }

    // ----------------------------------------------------------------------
    // RealsService — write path
    // ----------------------------------------------------------------------

    public function test_create_uploads_persists_and_dispatches_optimisation(): void
    {
        Bus::fake([ProcessReelVideo::class]);
        $user = User::factory()->create();

        $real = app(RealsService::class)->create([
            'video'       => UploadedFile::fake()->create('reel.mp4', 512, 'video/mp4'),
            'description' => 'hello',
            'categories'  => [3, 3, 5, null], // de-duped + null filtered
        ], $user->id);

        $this->assertNotNull($real);
        $this->assertSame('videos/fake.mp4', $real->url);
        $this->assertSame('hello', $real->description);
        $this->assertSame([3, 5], RealCategory::where('real_id', $real->id)->pluck('category_id')->all());
        Bus::assertDispatchedAfterResponse(ProcessReelVideo::class);
    }

    public function test_create_returns_null_without_a_valid_video(): void
    {
        $user = User::factory()->create();
        $this->assertNull(app(RealsService::class)->create(['description' => 'x'], $user->id));
        $this->assertSame(0, Real::count());
    }

    public function test_create_defaults_description_to_empty_string(): void
    {
        $user = User::factory()->create();
        $real = app(RealsService::class)->create([
            'video' => UploadedFile::fake()->create('reel.mp4', 64, 'video/mp4'),
        ], $user->id);

        $this->assertSame('', $real->description);
    }

    public function test_update_caption_only_does_not_dispatch_reoptimisation(): void
    {
        Bus::fake([ProcessReelVideo::class]);
        $owner = User::factory()->create();
        $reel = $this->reel($owner);
        Auth::login($owner);

        $updated = app(RealsService::class)->update($reel->id, ['description' => 'new caption']);

        $this->assertSame('new caption', $updated->description);
        Bus::assertNotDispatched(ProcessReelVideo::class); // caption-only skips re-optimise
    }

    public function test_update_with_new_video_redispatches_optimisation(): void
    {
        Bus::fake([ProcessReelVideo::class]);
        $owner = User::factory()->create();
        $reel = $this->reel($owner);
        Auth::login($owner);

        app(RealsService::class)->update($reel->id, [
            'video' => UploadedFile::fake()->create('new.mp4', 64, 'video/mp4'),
        ]);

        Bus::assertDispatchedAfterResponse(ProcessReelVideo::class);
        $this->assertSame('videos/fake.mp4', $reel->fresh()->url);
    }

    public function test_update_rejected_for_non_owner(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $reel = $this->reel($owner, ['description' => 'orig']);
        Auth::login($stranger);

        $this->assertNull(app(RealsService::class)->update($reel->id, ['description' => 'hacked']));
        $this->assertSame('orig', $reel->fresh()->description);
    }

    public function test_update_missing_reel_returns_null(): void
    {
        Auth::login(User::factory()->create());
        $this->assertNull(app(RealsService::class)->update(999999, ['description' => 'x']));
    }

    public function test_delete_owner_succeeds_stranger_fails(): void
    {
        $owner = User::factory()->create();
        $stranger = User::factory()->create();
        $reel = $this->reel($owner);

        Auth::login($stranger);
        $this->assertFalse(app(RealsService::class)->delete($reel->id));
        $this->assertSame(1, Real::count());

        Auth::login($owner);
        $this->assertTrue(app(RealsService::class)->delete($reel->id));
        $this->assertSame(0, Real::count());
    }

    public function test_delete_accepts_a_model_instance_and_handles_missing(): void
    {
        $owner = User::factory()->create();
        $reel = $this->reel($owner);
        Auth::login($owner);

        $this->assertTrue(app(RealsService::class)->delete($reel));   // model instance
        $this->assertFalse(app(RealsService::class)->delete(999999)); // missing id
    }

    public function test_delete_reel_and_report_removes_both(): void
    {
        $owner = User::factory()->create();
        $reporter = User::factory()->create();
        $reel = $this->reel($owner);
        $report = ReportReals::create([
            'real_id' => $reel->id, 'Reporter_id' => $reporter->id,
            'Reported_id' => $owner->id, 'description' => 'bad',
        ]);

        $res = app(RealsService::class)->deleteReelAndReport($reel->id, $report->id);

        $this->assertTrue($res['success']);
        $this->assertSame(200, $res['status']);
        $this->assertSame(0, Real::count());
        $this->assertDatabaseMissing('report_reals', ['id' => $report->id]);
    }

    public function test_delete_reel_and_report_404_for_missing_reel(): void
    {
        $res = app(RealsService::class)->deleteReelAndReport(999999, 1);
        $this->assertFalse($res['success']);
        $this->assertSame(404, $res['status']);
    }

    // ----------------------------------------------------------------------
    // ReelsRepository — feed reads
    // ----------------------------------------------------------------------

    public function test_get_reel_by_id_attaches_like_exists_flag(): void
    {
        $reel = $this->reel();
        $viewer = User::factory()->create();
        $this->likes()->add($reel, $viewer);

        $found = app(ReelsRepository::class)->getReelById($reel->id, $viewer->id);
        $this->assertTrue((bool) $found->likes_exists);

        $stranger = User::factory()->create();
        $found2 = app(ReelsRepository::class)->getReelById($reel->id, $stranger->id);
        $this->assertFalse((bool) $found2->likes_exists);
    }

    public function test_get_user_reals_lists_only_that_users_reels(): void
    {
        $a = User::factory()->create();
        $b = User::factory()->create();
        $this->reel($a, ['description' => 'a1']);
        $this->reel($a, ['description' => 'a2']);
        $this->reel($b, ['description' => 'b1']);

        $page = app(ReelsRepository::class)->getUserReals($a->id, $a->id);
        $this->assertCount(2, $page->items());
    }

    public function test_get_all_reels_excludes_reels_by_soft_deleted_authors(): void
    {
        $live = User::factory()->create();
        $ghost = User::factory()->create();
        $this->reel($live, ['description' => 'visible']);
        $this->reel($ghost, ['description' => 'hidden']);
        $ghost->delete(); // author gone → whereHas('user') drops their reels

        Cache::flush(); // rebuild the deck after the author change
        $page = app(ReelsRepository::class)->getAllReels($live->id);

        $descriptions = collect($page->items())->pluck('description')->all();
        $this->assertContains('visible', $descriptions);
        $this->assertNotContains('hidden', $descriptions);
    }

    public function test_get_all_reels_empty_when_no_reels(): void
    {
        $page = app(ReelsRepository::class)->getAllReels(User::factory()->create()->id);
        $this->assertSame(0, $page->total());
    }

    public function test_get_liked_reels_lists_reels_the_user_reacted_to(): void
    {
        $viewer = User::factory()->create();
        $r1 = $this->reel();
        $r2 = $this->reel();
        $this->likes()->add($r1, $viewer); // only r1 liked

        $page = app(ReelsRepository::class)->getLikedReels($viewer->id);
        $this->assertCount(1, $page->items());
        $this->assertSame($r1->id, $page->items()[0]->real->id);
    }

    public function test_get_all_reels_hydrates_my_reaction_and_breakdown(): void
    {
        $viewer = User::factory()->create();
        $reel = $this->reel();
        $this->actingAs($viewer); // Auth::id() drives the viewer's own-reaction hydration
        $this->likes()->react($reel, $viewer, 'wow');
        $other = User::factory()->create();
        $this->likes()->react($reel, $other, 'wow');

        Cache::flush();
        $page = app(ReelsRepository::class)->getAllReels($viewer->id);
        $item = collect($page->items())->firstWhere('id', $reel->id);

        $this->assertSame('wow', $item->getAttribute('my_reaction_pre'));
        $this->assertSame(2, $item->getAttribute('reactions_pre')['wow']);
    }

    // ----------------------------------------------------------------------
    // Real entity
    // ----------------------------------------------------------------------

    public function test_entity_defaults_null_description_to_empty_on_create(): void
    {
        $user = User::factory()->create();
        $reel = Real::create(['user_id' => $user->id, 'url' => 'videos/x.mp4', 'description' => null]);

        $this->assertSame('', $reel->fresh()->description);
    }

    public function test_entity_relationships_resolve(): void
    {
        $owner = User::factory()->create();
        $reel = $this->reel($owner);
        $u = User::factory()->create();
        $this->likes()->add($reel, $u);
        $this->comments()->add(['comment' => 'c'], $reel, $u);
        RealUserView::create(['real_id' => $reel->id, 'user_id' => $u->id]);
        RealCategory::create(['real_id' => $reel->id, 'category_id' => 9]);

        $reel->refresh();
        $this->assertTrue($reel->user->is($owner));
        $this->assertCount(1, $reel->likes);
        $this->assertCount(1, $reel->comments);
        $this->assertCount(1, $reel->views);
        $this->assertCount(1, $reel->categories);
    }

    // ----------------------------------------------------------------------
    // ProcessReelVideo — best-effort no-op branches
    // ----------------------------------------------------------------------

    public function test_job_is_noop_for_missing_reel(): void
    {
        (new ProcessReelVideo(999999))->handle(); // must not throw
        $this->assertTrue(true);
    }

    public function test_job_skips_external_and_already_optimised_urls(): void
    {
        $ext = $this->reel(null, ['url' => 'https://cdn.example/v.mp4']);
        $opt = $this->reel(null, ['url' => 'videos/v.opt.mp4']);
        $empty = $this->reel(null, ['url' => '']);

        (new ProcessReelVideo($ext->id))->handle();
        (new ProcessReelVideo($opt->id))->handle();
        (new ProcessReelVideo($empty->id))->handle();

        // URLs untouched — none were optimisable, and nothing threw.
        $this->assertSame('https://cdn.example/v.mp4', $ext->fresh()->url);
        $this->assertSame('videos/v.opt.mp4', $opt->fresh()->url);
        $this->assertSame('', $empty->fresh()->url);
    }

    public function test_job_is_noop_when_source_file_missing_on_disk(): void
    {
        // Local source file doesn't exist → storage probe returns false → no-op,
        // url left untouched, no exception.
        $reel = $this->reel(null, ['url' => 'videos/does-not-exist.mp4']);

        (new ProcessReelVideo($reel->id))->handle();

        $this->assertSame('videos/does-not-exist.mp4', $reel->fresh()->url);
    }
}
