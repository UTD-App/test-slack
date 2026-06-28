<?php

namespace Utd\Reels\Tests\Feature;

use App\Contracts\MediaUploader;
use App\Models\User;
use App\Support\Media\MediaResult;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;
use Utd\Reels\Entities\Real;

class ReelsApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        // Stub the Base MediaUploader so create() never touches real storage, and
        // so the (best-effort) FFMpeg frame extraction has a harmless fake URL.
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

    public function test_user_can_create_a_reel(): void
    {
        [$user, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/reals', [
                'video'       => UploadedFile::fake()->create('reel.mp4', 1024, 'video/mp4'),
                'description' => 'My first reel',
            ])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('reals', ['user_id' => $user->id, 'description' => 'My first reel']);
    }

    public function test_create_requires_a_video(): void
    {
        [, $token] = $this->actingUser();

        // Missing video → inline validation returns the standard envelope
        // (HTTP 200, status:false) rather than a thrown 422 (see controller note).
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/reals', ['description' => 'no video'])
            ->assertStatus(200)
            ->assertJsonPath('status', false);
    }

    public function test_feed_lists_reels(): void
    {
        [$user, $token] = $this->actingUser();
        Real::create(['user_id' => $user->id, 'url' => 'videos/x.mp4', 'description' => 'first']);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->getJson('/api/reals')
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonPath('data.0.description', 'first');
    }

    public function test_user_can_like_and_unlike(): void
    {
        [$owner] = $this->actingUser();
        $real = Real::create(['user_id' => $owner->id, 'url' => 'videos/x.mp4', 'description' => 'likeable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like")
            ->assertStatus(200);
        $this->assertDatabaseHas('real_user_likes', ['real_id' => $real->id]);

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/like")
            ->assertStatus(200);
        $this->assertDatabaseMissing('real_user_likes', ['real_id' => $real->id]);
    }

    public function test_user_can_comment(): void
    {
        [$owner] = $this->actingUser();
        $real = Real::create(['user_id' => $owner->id, 'url' => 'videos/x.mp4', 'description' => 'commentable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/comment", ['comment' => 'nice!'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('real_user_comments', ['real_id' => $real->id, 'comment' => 'nice!']);
    }

    public function test_user_can_record_a_view(): void
    {
        [$owner] = $this->actingUser();
        $real = Real::create(['user_id' => $owner->id, 'url' => 'videos/x.mp4', 'description' => 'viewable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/view", ['duration' => 1])
            ->assertStatus(200);

        // Views are now a cheap atomic counter (no row-per-play insert).
        $this->assertDatabaseHas('reals', ['id' => $real->id, 'view_num' => 1]);
        $this->assertDatabaseMissing('real_user_views', ['real_id' => $real->id]);
    }

    public function test_user_can_report_a_reel(): void
    {
        [$owner] = $this->actingUser();
        $real = Real::create(['user_id' => $owner->id, 'url' => 'videos/x.mp4', 'description' => 'reportable']);

        [, $token] = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/report", ['description' => 'spam', 'type' => 'abuse'])
            ->assertStatus(200)
            ->assertJsonPath('status', true);

        $this->assertDatabaseHas('report_reals', ['real_id' => $real->id, 'type' => 'abuse']);
    }

    public function test_gift_endpoint_is_active_when_gifts_installed(): void
    {
        [$owner] = $this->actingUser();
        $real = Real::create(['user_id' => $owner->id, 'url' => 'videos/x.mp4', 'description' => 'giftable']);

        [, $token] = $this->actingUser();

        // The Gifts package binds GiftSender, so the endpoint is no longer 503.
        // An unknown gift id is processed and rejected with 402 (not 503).
        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson("/api/reals/{$real->id}/gift", ['gift_id' => 999999, 'num' => 1])
            ->assertStatus(402)
            ->assertJsonPath('status', false);
    }

    public function test_reel_routes_require_auth(): void
    {
        $this->getJson('/api/reals')->assertStatus(401);
    }
}
