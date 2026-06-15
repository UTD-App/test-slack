<?php

namespace Tests\Feature;

use App\Contracts\MediaUploader;
use App\Exceptions\MediaUploadException;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MediaUploadTest extends TestCase
{
    use RefreshDatabase;

    private function actingUser(): string
    {
        $user = User::factory()->create();

        return $user->createToken('test')->plainTextToken;
    }

    public function test_upload_endpoint_stores_file_and_returns_path_and_url(): void
    {
        Storage::fake(config('filesystems.default'));
        $token = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/media/upload', [
                'folder' => 'avatars',
                'file'   => UploadedFile::fake()->image('avatar.jpg'),
            ])
            ->assertStatus(200)
            ->assertJsonPath('status', true)
            ->assertJsonStructure(['data' => ['path', 'url']]);
    }

    public function test_uploader_throws_clean_exception_when_disk_write_fails(): void
    {
        // Simulate a disk failure (e.g. GCS 403 from read-only credentials).
        Storage::shouldReceive('put')->andThrow(new \RuntimeException('403 Forbidden'));

        $this->expectException(MediaUploadException::class);

        app(MediaUploader::class)->upload(UploadedFile::fake()->image('x.jpg'), 'avatars');
    }

    public function test_upload_endpoint_returns_clean_error_envelope_on_failure(): void
    {
        Storage::shouldReceive('put')->andThrow(new \RuntimeException('403 Forbidden'));
        $token = $this->actingUser();

        $this->withHeader('Authorization', "Bearer {$token}")
            ->postJson('/api/media/upload', [
                'folder' => 'avatars',
                'file'   => UploadedFile::fake()->image('avatar.jpg'),
            ])
            ->assertStatus(500)
            ->assertJsonPath('status', false);
    }
}
