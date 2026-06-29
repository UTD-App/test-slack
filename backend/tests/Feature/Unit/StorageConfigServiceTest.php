<?php

namespace Tests\Feature\Unit;

use App\Models\Config;
use App\Services\StorageConfigService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * StorageConfigService URL building (driver-aware) and webUrl resolution rules
 * for the admin panel (cloud → absolute, local → host-relative, re-resolve our
 * own stored /storage/<tail> URLs, pass third-party absolutes through).
 */
class StorageConfigServiceTest extends TestCase
{
    use RefreshDatabase;

    private function service(): StorageConfigService
    {
        return app(StorageConfigService::class);
    }

    private function setConf(array $pairs): void
    {
        foreach ($pairs as $name => $value) {
            Config::updateOrCreate(['name' => $name], ['value' => $value]);
        }
    }

    public function test_gcs_url_uses_googleapis_host(): void
    {
        $this->setConf(['storage_driver' => 'gcs', 'storage_bucket' => 'my-bucket']);

        $url = $this->service()->url('avatars/a.png');

        $this->assertSame('https://storage.googleapis.com/my-bucket/avatars/a.png', $url);
    }

    public function test_gcs_url_strips_leading_slash_on_path(): void
    {
        $this->setConf(['storage_driver' => 'gcs', 'storage_bucket' => 'b']);

        $this->assertSame('https://storage.googleapis.com/b/x.png', $this->service()->url('/x.png'));
    }

    public function test_s3_url_uses_endpoint_and_bucket(): void
    {
        $this->setConf([
            'storage_driver' => 's3',
            'storage_endpoint' => 'https://minio.example.com/',
            'storage_bucket' => 'media',
        ]);

        $this->assertSame('https://minio.example.com/media/folder/f.jpg', $this->service()->url('folder/f.jpg'));
    }

    public function test_web_url_returns_null_for_empty(): void
    {
        $this->assertNull($this->service()->webUrl(null));
        $this->assertNull($this->service()->webUrl(''));
    }

    public function test_web_url_passes_through_third_party_absolute(): void
    {
        $this->setConf(['storage_driver' => 'gcs', 'storage_bucket' => 'b']);

        $ext = 'https://ui-avatars.com/api/?name=A';
        $this->assertSame($ext, $this->service()->webUrl($ext));
    }

    public function test_web_url_keeps_absolute_for_cloud_backed_media(): void
    {
        $this->setConf(['storage_driver' => 'gcs', 'storage_bucket' => 'b']);

        $this->assertSame(
            'https://storage.googleapis.com/b/avatars/a.png',
            $this->service()->webUrl('avatars/a.png'),
        );
    }

    public function test_web_url_re_resolves_our_own_stored_storage_url(): void
    {
        // A stored absolute URL pointing at an emulator host must be re-resolved
        // from its /storage/<tail> against the configured cloud bucket.
        $this->setConf(['storage_driver' => 'gcs', 'storage_bucket' => 'b']);

        $stored = 'http://10.0.2.2:8000/storage/avatars/a.png';
        $this->assertSame(
            'https://storage.googleapis.com/b/avatars/a.png',
            $this->service()->webUrl($stored),
        );
    }

    public function test_web_url_local_driver_is_host_relative(): void
    {
        $this->setConf(['storage_driver' => 'local']);

        $result = $this->service()->webUrl('avatars/a.png');

        // Local (non-cloud) media must be host-relative (no scheme/host).
        $this->assertStringStartsWith('/', $result);
        $this->assertStringNotContainsString('http', $result);
        $this->assertStringContainsString('avatars/a.png', $result);
    }
}
