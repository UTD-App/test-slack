<?php

namespace Tests\Feature;

use App\Models\Page;
use App\Support\Translatable\TranslatableContentWriter;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * The shared write path for per-locale translatable content. Writes into a
 * model's keyed-by-locale JSON, preserving other locales, then saves.
 */
class TranslatableContentWriterTest extends TestCase
{
    use RefreshDatabase;

    public function test_writes_locale_value_into_empty_map(): void
    {
        $page = Page::create(['key' => 'about', 'title' => [], 'body' => []]);

        TranslatableContentWriter::write($page, ['title', 'body'], 'en', [
            'title' => 'About Us',
            'body'  => '<p>Hello</p>',
        ]);

        $page->refresh();
        $this->assertSame(['en' => 'About Us'], $page->title);
        $this->assertSame(['en' => '<p>Hello</p>'], $page->body);
    }

    public function test_preserves_other_locales_when_writing_one(): void
    {
        $page = Page::create([
            'key'   => 'about',
            'title' => ['en' => 'About', 'ar' => 'حول'],
            'body'  => [],
        ]);

        TranslatableContentWriter::write($page, ['title'], 'fr', ['title' => 'À propos']);

        $page->refresh();
        $this->assertSame(['en' => 'About', 'ar' => 'حول', 'fr' => 'À propos'], $page->title);
    }

    public function test_skips_fields_absent_from_values(): void
    {
        $page = Page::create(['key' => 'about', 'title' => [], 'body' => ['en' => 'keep']]);

        // Only 'title' supplied; 'body' must be left untouched.
        TranslatableContentWriter::write($page, ['title', 'body'], 'en', ['title' => 'T']);

        $page->refresh();
        $this->assertSame(['en' => 'T'], $page->title);
        $this->assertSame(['en' => 'keep'], $page->body);
    }

    public function test_casts_value_to_string(): void
    {
        $page = Page::create(['key' => 'about', 'title' => [], 'body' => []]);

        TranslatableContentWriter::write($page, ['title'], 'en', ['title' => 123]);

        $page->refresh();
        $this->assertSame(['en' => '123'], $page->title);
    }
}
