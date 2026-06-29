<?php

namespace Tests\Feature;

use App\Models\Language;
use App\Models\Page;
use App\Support\AppLanguages;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Page uses HasTranslations: tr()/trMap() over keyed-by-locale JSON columns.
 */
class PageModelTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        AppLanguages::flush();
        Language::create([
            'code' => 'en', 'name' => 'English', 'native_name' => 'English',
            'is_rtl' => false, 'is_active' => true, 'is_default' => true,
        ]);
        AppLanguages::flush();
    }

    public function test_title_and_body_cast_to_array(): void
    {
        $page = Page::create([
            'key'   => 'about',
            'title' => ['en' => 'About', 'ar' => 'حول'],
            'body'  => ['en' => 'Body'],
        ]);
        $page->refresh();

        $this->assertIsArray($page->title);
        $this->assertSame(['en' => 'About', 'ar' => 'حول'], $page->title);
    }

    public function test_tr_resolves_for_requested_locale(): void
    {
        $page = Page::create([
            'key' => 'about', 'title' => ['en' => 'About', 'ar' => 'حول'], 'body' => [],
        ]);

        $this->assertSame('حول', $page->tr('title', 'ar'));
        $this->assertSame('About', $page->tr('title', 'en'));
    }

    public function test_tr_falls_back_to_default_language(): void
    {
        $page = Page::create([
            'key' => 'about', 'title' => ['en' => 'About'], 'body' => [],
        ]);

        // 'fr' missing → falls back to the default language 'en'.
        $this->assertSame('About', $page->tr('title', 'fr'));
    }

    public function test_tr_returns_empty_string_when_nothing_present(): void
    {
        $page = Page::create(['key' => 'about', 'title' => [], 'body' => []]);
        $this->assertSame('', $page->tr('title'));
    }

    public function test_tr_uses_app_locale_when_no_locale_given(): void
    {
        app()->setLocale('ar');
        $page = Page::create([
            'key' => 'about', 'title' => ['en' => 'About', 'ar' => 'حول'], 'body' => [],
        ]);

        $this->assertSame('حول', $page->tr('title'));
    }

    public function test_tr_map_returns_raw_map_stringified(): void
    {
        $page = Page::create([
            'key' => 'about', 'title' => ['en' => 'About', 'ar' => 'حول'], 'body' => [],
        ]);

        $this->assertSame(['en' => 'About', 'ar' => 'حول'], $page->trMap('title'));
    }

    public function test_tr_map_empty_for_non_array_attribute(): void
    {
        $page = Page::create(['key' => 'about', 'title' => [], 'body' => []]);
        $this->assertSame([], $page->trMap('title'));
    }
}
