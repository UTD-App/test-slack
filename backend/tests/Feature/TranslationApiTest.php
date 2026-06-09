<?php

namespace Tests\Feature;

use App\Models\Language;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TranslationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_supported_languages_endpoint_works(): void
    {
        Language::create([
            'code'        => 'en',
            'name'        => 'English',
            'native_name' => 'English',
            'is_rtl'      => false,
            'is_active'   => true,
            'is_default'  => true,
        ]);

        $this->getJson('/api/translations/supported')
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_translation_version_endpoint_returns_version(): void
    {
        Language::create([
            'code'        => 'en',
            'name'        => 'English',
            'native_name' => 'English',
            'is_rtl'      => false,
            'is_active'   => true,
            'is_default'  => true,
        ]);

        $this->getJson('/api/translations/en/version')
            ->assertStatus(200)
            ->assertJsonPath('success', true);
    }

    public function test_translation_content_endpoint_works(): void
    {
        Language::create([
            'code'        => 'ar',
            'name'        => 'Arabic',
            'native_name' => 'العربية',
            'is_rtl'      => true,
            'is_active'   => true,
            'is_default'  => false,
        ]);

        $this->getJson('/api/translations/ar')
            ->assertStatus(200)
            ->assertJsonStructure(['success', 'data' => ['version', 'locale', 'translations']]);
    }
}
