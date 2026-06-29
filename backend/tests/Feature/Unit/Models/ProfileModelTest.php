<?php

namespace Tests\Feature;

use App\Facades\Media;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProfileModelTest extends TestCase
{
    use RefreshDatabase;

    private function make(array $overrides = []): Profile
    {
        $user = User::factory()->create();
        return Profile::create(array_merge(['user_id' => $user->id], $overrides));
    }

    public function test_covers_cast_to_array(): void
    {
        $p = $this->make(['covers' => ['c1.png', 'c2.png']]);
        $this->assertSame(['c1.png', 'c2.png'], $p->refresh()->covers);
    }

    public function test_image_accessor_passes_through_absolute_urls(): void
    {
        $p = $this->make(['avatar' => 'https://cdn.example/a.png']);
        // Absolute URL → returned unchanged, Media seam not consulted.
        $this->assertSame('https://cdn.example/a.png', $p->image);
    }

    public function test_image_accessor_resolves_relative_path_via_media_seam(): void
    {
        Media::shouldReceive('url')->once()->with('avatars/a.png')->andReturn('https://host/avatars/a.png');

        $p = $this->make(['avatar' => 'avatars/a.png']);
        $this->assertSame('https://host/avatars/a.png', $p->image);
    }

    public function test_image_accessor_null_when_no_avatar(): void
    {
        $p = $this->make(['avatar' => null]);
        $this->assertNull($p->image);
    }

    public function test_cover_images_empty_when_no_covers(): void
    {
        $p = $this->make(['covers' => null]);
        $this->assertSame([], $p->cover_images);
    }

    public function test_cover_images_resolves_and_filters(): void
    {
        // Absolute URLs pass through; the empty/non-string entries are filtered out.
        $p = $this->make(['covers' => ['https://cdn/1.png', '', 'https://cdn/2.png']]);

        $this->assertSame(['https://cdn/1.png', 'https://cdn/2.png'], $p->cover_images);
    }

    public function test_cover_images_reindexed_after_filtering(): void
    {
        $p = $this->make(['covers' => ['', 'https://cdn/only.png']]);
        $covers = $p->cover_images;

        $this->assertSame([0 => 'https://cdn/only.png'], $covers); // zero-indexed
    }

    public function test_appends_expose_image_and_cover_images(): void
    {
        $p = $this->make(['avatar' => 'https://cdn/a.png', 'covers' => ['https://cdn/c.png']]);
        $array = $p->toArray();

        $this->assertArrayHasKey('image', $array);
        $this->assertArrayHasKey('cover_images', $array);
        $this->assertSame('https://cdn/a.png', $array['image']);
    }

    public function test_user_relationship(): void
    {
        $user = User::factory()->create();
        $p = Profile::create(['user_id' => $user->id]);
        $this->assertTrue($p->user->is($user));
    }
}
