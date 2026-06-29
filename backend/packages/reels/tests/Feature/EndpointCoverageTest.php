<?php

namespace Utd\Reels\Tests\Feature;

use App\Contracts\MediaUploader;
use App\Models\User;
use App\Support\Media\MediaResult;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;
use Utd\Reels\Entities\Real;
use Utd\Reels\Entities\RealUserLike;

/**
 * Endpoint coverage for reels routes not exercised by the existing suites
 * (ReelsApiTest / ReelsFeedPageTest / ReelsReactionsTest).
 *
 * Covers: reals/seed (dev), reals/user/{id?}, reals/my-reals,
 * reals/user-followers, GET reals/{id} (show), DELETE reals/{id} (destroy),
 * reals-update/{id} (update), GET reals/{id}/like (likes index),
 * DELETE reals/{id}/like/{id} (like destroy).
 */
class EndpointCoverageTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Stub the Base MediaUploader so create/update never touch real storage.
        $this->app->bind(MediaUploader::class, fn () => new class implements MediaUploader
        {
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

    private function actingUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('test')->plainTextToken;

        return [$user, $token];
    }

    /**
     * Re-resolve the auth guard so the NEXT authenticated request maps to its own
     * token's user. In the real app every request is a fresh process; in a single
     * PHPUnit test the container persists, so the StatefulGuard caches the first
     * resolved user and reuses it for later requests with a different token. Call
     * this whenever a test switches the acting (token) user mid-test.
     */
    private function flushAuth(): void
    {
        $this->app['auth']->forgetGuards();
    }

    private function reelFor(User $owner): Real
    {
        return Real::create(['user_id' => $owner->id, 'url' => 'videos/x.mp4', 'description' => 'r']);
    }

    // ── reals/seed (public dev route) ──────────────────────────────────────

    public function test_seed_route_is_public_and_returns_total(): void
    {
        // No auth header: route is registered before the auth group and runs
        // freely in the testing environment.
        $this->getJson('/api/reals/seed')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['status', 'message', 'data' => ['total_reels']]);

        // The bulk seeder produced at least one reel.
        $this->assertGreaterThan(0, Real::count());
    }

    // ── reals/user/{user_id?} (getUserReals) ───────────────────────────────

    public function test_get_user_reals_lists_only_that_users_reels(): void
    {
        [$author, $authorToken] = $this->actingUser();
        [$other] = $this->actingUser();

        $mine = $this->reelFor($author);
        $mine->update(['description' => 'by author']);
        $this->reelFor($other)->update(['description' => 'by other']);

        $this->withHeader('Authorization', "Bearer {$authorToken}")
            ->getJson("/api/reals/user/{$author->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.user_id', $author->id);
    }

    public function test_get_user_reals_unknown_user_returns_status_false(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/reals/user/99999999')
            ->assertStatus(200)
            ->assertJsonPath('status', false);
    }

    public function test_get_user_reals_requires_auth(): void
    {
        $this->getJson('/api/reals/user/1')->assertStatus(401);
    }

    // ── reals/my-reals (getMyReals) ────────────────────────────────────────

    public function test_my_reals_returns_only_callers_reels(): void
    {
        [$me, $token] = $this->actingUser();
        [$other] = $this->actingUser();

        $this->reelFor($me);
        $this->reelFor($other);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/reals/my-reals')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.user_id', $me->id);
    }

    public function test_my_reals_requires_auth(): void
    {
        $this->getJson('/api/reals/my-reals')->assertStatus(401);
    }

    // ── reals/user-followers (getUserFollowersReals) ───────────────────────

    public function test_user_followers_feed_returns_envelope(): void
    {
        [, $token] = $this->actingUser();

        // No Follow graph in the Base → empty/best-effort feed; assert the shape.
        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/reals/user-followers')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['status', 'message', 'data']);
    }

    public function test_user_followers_feed_requires_auth(): void
    {
        $this->getJson('/api/reals/user-followers')->assertStatus(401);
    }

    // ── GET reals/{real} (show) ────────────────────────────────────────────

    public function test_show_returns_a_single_reel(): void
    {
        [$owner, $token] = $this->actingUser();
        $real = $this->reelFor($owner);
        $real->update(['description' => 'single']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/reals/{$real->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.id', $real->id)
            ->assertJsonPath('data.description', 'single');
    }

    public function test_show_missing_reel_returns_status_false(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/reals/99999999')
            ->assertStatus(200)
            ->assertJsonPath('status', false);
    }

    public function test_show_requires_auth(): void
    {
        $this->getJson('/api/reals/1')->assertStatus(401);
    }

    // ── DELETE reals/{real} (destroy) ──────────────────────────────────────

    public function test_owner_can_delete_own_reel(): void
    {
        [$owner, $token] = $this->actingUser();
        $real = $this->reelFor($owner);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/reals/{$real->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseMissing('reals', ['id' => $real->id]);
    }

    public function test_stranger_cannot_delete_reel(): void
    {
        [$owner] = $this->actingUser();
        $real = $this->reelFor($owner);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/reals/{$real->id}")
            ->assertStatus(403)
            ->assertJsonPath('status', false);

        $this->assertDatabaseHas('reals', ['id' => $real->id]);
    }

    public function test_destroy_requires_auth(): void
    {
        $this->deleteJson('/api/reals/1')->assertStatus(401);
    }

    // ── POST reals-update/{id} (update) ────────────────────────────────────

    public function test_owner_can_update_caption(): void
    {
        [$owner, $token] = $this->actingUser();
        $real = $this->reelFor($owner);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals-update/{$real->id}", ['description' => 'edited caption'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('reals', ['id' => $real->id, 'description' => 'edited caption']);
    }

    public function test_non_owner_update_is_rejected(): void
    {
        [$owner] = $this->actingUser();
        $real = $this->reelFor($owner);

        [, $token] = $this->actingUser();

        // Service returns null for a non-owner → status:false, original untouched.
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals-update/{$real->id}", ['description' => 'hijacked'])
            ->assertStatus(200)
            ->assertJsonPath('status', false);

        $this->assertDatabaseHas('reals', ['id' => $real->id, 'description' => 'r']);
    }

    public function test_update_rejects_overlong_description(): void
    {
        [$owner, $token] = $this->actingUser();
        $real = $this->reelFor($owner);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals-update/{$real->id}", ['description' => str_repeat('x', 501)])
            ->assertStatus(200)
            ->assertJsonPath('status', false);

        $this->assertDatabaseHas('reals', ['id' => $real->id, 'description' => 'r']);
    }

    public function test_update_requires_auth(): void
    {
        $this->postJson('/api/reals-update/1', ['description' => 'x'])->assertStatus(401);
    }

    // ── GET reals/{real_id}/like (likes index) ─────────────────────────────

    public function test_likes_index_lists_reactors(): void
    {
        [$owner] = $this->actingUser();
        $real = $this->reelFor($owner);

        [$liker, $token] = $this->actingUser();
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like", ['reaction_type' => 'love'])
            ->assertStatus(200);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson("/api/reals/{$real->id}/like")
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.0.user_id', $liker->id)
            ->assertJsonPath('data.0.reaction_type', 'love');
    }

    public function test_likes_index_missing_reel_is_404(): void
    {
        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/reals/99999999/like')
            ->assertStatus(404)
            ->assertJsonPath('status', false);
    }

    public function test_likes_index_requires_auth(): void
    {
        $this->getJson('/api/reals/1/like')->assertStatus(401);
    }

    // ── DELETE reals/{real_id}/like/{id} (like destroy) ────────────────────

    public function test_user_can_delete_own_like_row_and_counter_drops(): void
    {
        [$owner] = $this->actingUser();
        $real = $this->reelFor($owner);

        [$liker, $token] = $this->actingUser();
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like", ['reaction_type' => 'like'])
            ->assertStatus(200);

        $like = RealUserLike::where('real_id', $real->id)->where('user_id', $liker->id)->firstOrFail();
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'like_num' => 1]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->deleteJson("/api/reals/{$real->id}/like/{$like->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseMissing('real_user_likes', ['id' => $like->id]);
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'like_num' => 0]);
    }

    public function test_user_cannot_delete_another_users_like(): void
    {
        [$owner] = $this->actingUser();
        $real = $this->reelFor($owner);

        // Liker A reacts.
        [$likerA, $tokenA] = $this->actingUser();
        $this->withHeader('Authorization', "Bearer {$tokenA}")
            ->postJson("/api/reals/{$real->id}/like", ['reaction_type' => 'like']);
        $like = RealUserLike::where('user_id', $likerA->id)->firstOrFail();

        // Switch acting user; re-resolve the guard so the next request maps to B
        // (mirrors a fresh request in production — see flushAuth()).
        [, $tokenB] = $this->actingUser();
        $this->flushAuth();
        $this->withHeader('Authorization', "Bearer {$tokenB}")
            ->deleteJson("/api/reals/{$real->id}/like/{$like->id}")
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        // A's like still exists, counter unchanged.
        $this->assertDatabaseHas('real_user_likes', ['id' => $like->id]);
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'like_num' => 1]);
    }

    public function test_like_destroy_requires_auth(): void
    {
        $this->deleteJson('/api/reals/1/like/1')->assertStatus(401);
    }
}
