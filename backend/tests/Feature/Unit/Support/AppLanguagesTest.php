<?php

namespace Tests\Feature;

use App\Models\Language;
use App\Support\AppLanguages;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Cached view of the languages table + its en/ar degradation when empty.
 * CACHE_DRIVER=array in phpunit.xml, so caching is real-but-isolated per process.
 */
class AppLanguagesTest extends TestCase
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
            'code'        => $code,
            'name'        => strtoupper($code),
            'native_name' => $code,
            'is_rtl'      => false,
            'is_active'   => true,
            'is_default'  => false,
        ], $overrides));
    }

    public function test_degrades_to_en_ar_when_table_empty(): void
    {
        // activeCodes() has an explicit en/ar fallback when the query returns [].
        $this->assertSame(['en', 'ar'], AppLanguages::activeCodes());

        // rtlCodes()/names() only fall back inside their catch (query error); an
        // empty-but-existing table just returns the empty query result.
        $this->assertSame([], AppLanguages::rtlCodes());
        $this->assertSame([], AppLanguages::names());
    }

    public function test_default_code_falls_back_to_config_locale_when_none(): void
    {
        config(['app.locale' => 'en']);
        $this->assertSame('en', AppLanguages::defaultCode());
    }

    public function test_active_codes_lists_default_first_then_by_id(): void
    {
        $this->lang('en');                                  // id 1, not default
        $this->lang('ar', ['is_default' => true, 'is_rtl' => true]); // id 2, default
        AppLanguages::flush();

        // Default ('ar') first, then remaining active by id.
        $this->assertSame(['ar', 'en'], AppLanguages::activeCodes());
    }

    public function test_inactive_languages_are_excluded(): void
    {
        $this->lang('en', ['is_default' => true]);
        $this->lang('fr', ['is_active' => false]);
        AppLanguages::flush();

        $this->assertSame(['en'], AppLanguages::activeCodes());
        $this->assertFalse(AppLanguages::isActive('fr'));
        $this->assertTrue(AppLanguages::isActive('en'));
    }

    public function test_default_code_reads_default_language(): void
    {
        $this->lang('en');
        $this->lang('ar', ['is_default' => true]);
        AppLanguages::flush();

        $this->assertSame('ar', AppLanguages::defaultCode());
    }

    public function test_rtl_codes_only_active_rtl(): void
    {
        $this->lang('en', ['is_default' => true]);
        $this->lang('ar', ['is_rtl' => true]);
        $this->lang('he', ['is_rtl' => true, 'is_active' => false]); // inactive, excluded
        AppLanguages::flush();

        $this->assertSame(['ar'], AppLanguages::rtlCodes());
    }

    public function test_names_keyed_by_code(): void
    {
        $this->lang('en', ['is_default' => true, 'native_name' => 'English']);
        $this->lang('ar', ['native_name' => 'العربية']);
        AppLanguages::flush();

        $this->assertSame(['en' => 'English', 'ar' => 'العربية'], AppLanguages::names());
    }

    public function test_results_are_cached_until_flushed(): void
    {
        $this->lang('en', ['is_default' => true]);
        AppLanguages::flush();

        $this->assertSame(['en'], AppLanguages::activeCodes());

        // Insert a row via the query builder (bypasses model events, so no flush)
        // → the cached value is still served.
        \Illuminate\Support\Facades\DB::table('languages')->insert([
            'code' => 'fr', 'name' => 'FR', 'native_name' => 'fr',
            'is_rtl' => false, 'is_active' => true, 'is_default' => false,
            'created_at' => now(), 'updated_at' => now(),
        ]);
        $this->assertSame(['en'], AppLanguages::activeCodes());

        // Flush → fresh read includes it.
        AppLanguages::flush();
        $this->assertSame(['en', 'fr'], AppLanguages::activeCodes());
    }

    public function test_language_save_flushes_cache_via_model_event(): void
    {
        // Warm the cache against en/ar fallback.
        $this->assertSame(['en', 'ar'], AppLanguages::activeCodes());

        // Creating a Language fires saved() → AppLanguages::flush() in the model.
        $this->lang('en', ['is_default' => true]);

        $this->assertSame(['en'], AppLanguages::activeCodes());
    }
}
