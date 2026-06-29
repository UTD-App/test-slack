<?php

namespace Tests\Feature;

use App\Models\Language;
use App\Models\Translation;
use App\Models\TranslationKey;
use App\Support\AppLanguages;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Language enforces EXACTLY ONE default and keeps AppLanguages cache in sync.
 */
class LanguageModelTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        AppLanguages::flush();
    }

    private function lang(string $code, array $overrides = []): Language
    {
        return Language::create(array_merge([
            'code' => $code, 'name' => strtoupper($code), 'native_name' => $code,
            'is_rtl' => false, 'is_active' => true, 'is_default' => false,
        ], $overrides));
    }

    public function test_boolean_casts(): void
    {
        $l = $this->lang('en', ['is_default' => 1, 'is_rtl' => 0, 'is_active' => 1]);
        $l->refresh();
        $this->assertIsBool($l->is_rtl);
        $this->assertIsBool($l->is_active);
        $this->assertIsBool($l->is_default);
    }

    public function test_setting_a_new_default_clears_the_previous_one(): void
    {
        $en = $this->lang('en', ['is_default' => true]);
        $ar = $this->lang('ar', ['is_default' => true]);

        $this->assertFalse($en->fresh()->is_default); // demoted
        $this->assertTrue($ar->fresh()->is_default);
        // Exactly one default exists.
        $this->assertSame(1, Language::where('is_default', true)->count());
    }

    public function test_a_default_language_is_forced_active(): void
    {
        $l = $this->lang('en', ['is_default' => true, 'is_active' => false]);
        $this->assertTrue($l->fresh()->is_active);
    }

    public function test_never_leaves_zero_defaults(): void
    {
        $en = $this->lang('en', ['is_default' => true]);

        // Try to clear the only default → it is re-promoted.
        $en->update(['is_default' => false]);

        $this->assertTrue($en->fresh()->is_default);
        $this->assertSame(1, Language::where('is_default', true)->count());
    }

    public function test_translations_relationship(): void
    {
        $en = $this->lang('en', ['is_default' => true]);
        $key = TranslationKey::create(['key' => 'auth.login', 'group' => 'auth']);
        Translation::create([
            'language_id' => $en->id, 'translation_key_id' => $key->id, 'value' => 'Login',
        ]);

        $this->assertCount(1, $en->translations);
        $this->assertSame('Login', $en->translations->first()->value);
    }

    public function test_save_flushes_app_languages_cache(): void
    {
        // Warm fallback cache.
        $this->assertSame(['en', 'ar'], AppLanguages::activeCodes());

        $this->lang('en', ['is_default' => true]);

        // Cache flushed by the saved() hook → fresh read reflects DB.
        $this->assertSame(['en'], AppLanguages::activeCodes());
    }
}
