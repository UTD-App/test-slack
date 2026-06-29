<?php

namespace Tests\Feature;

use App\Models\Language;
use App\Support\AppLanguages;
use App\Support\Translatable;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Locale-resolution fallback chain for keyed-by-locale maps. Needs a DB because
 * the "default language" leg consults AppLanguages → languages table.
 */
class TranslatableResolverTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        AppLanguages::flush();
    }

    private function makeDefault(string $code = 'en'): void
    {
        Language::create([
            'code' => $code, 'name' => strtoupper($code), 'native_name' => $code,
            'is_rtl' => false, 'is_active' => true, 'is_default' => true,
        ]);
        AppLanguages::flush();
    }

    public function test_resolve_returns_null_for_empty_or_null_map(): void
    {
        $this->assertNull(Translatable::resolve(null));
        $this->assertNull(Translatable::resolve([]));
    }

    public function test_resolve_prefers_requested_locale(): void
    {
        $map = ['en' => 'Hello', 'fr' => 'Bonjour'];
        $this->assertSame('Bonjour', Translatable::resolve($map, 'fr'));
        $this->assertSame('Hello', Translatable::resolve($map, 'en'));
    }

    public function test_resolve_falls_back_to_default_language(): void
    {
        $this->makeDefault('en');
        // Requested 'fr' is missing → fall back to default 'en'.
        $this->assertSame('Hello', Translatable::resolve(['en' => 'Hello'], 'fr'));
    }

    public function test_resolve_falls_back_to_first_non_empty_value(): void
    {
        $this->makeDefault('en');
        // Neither requested 'de' nor default 'en' present → first non-empty value.
        $map = ['en' => '', 'fr' => '  ', 'es' => 'Hola'];
        $this->assertSame('Hola', Translatable::resolve($map, 'de'));
    }

    public function test_resolve_treats_whitespace_as_missing_but_html_as_present(): void
    {
        // "<p></p>" counts as deliberately-blank present content (wins over fallback).
        $this->assertSame('<p></p>', Translatable::resolve(['en' => '<p></p>'], 'en'));
        // Pure whitespace is missing → null when nothing else present.
        $this->assertNull(Translatable::resolve(['en' => '   '], 'en'));
    }

    public function test_resolve_or_never_returns_null(): void
    {
        $this->assertSame('', Translatable::resolveOr(null));
        $this->assertSame('FB', Translatable::resolveOr([], 'en', 'FB'));
        $this->assertSame('Hi', Translatable::resolveOr(['en' => 'Hi'], 'en', 'FB'));
    }

    public function test_has_locale(): void
    {
        $map = ['en' => 'Hi', 'fr' => '   '];
        $this->assertTrue(Translatable::hasLocale($map, 'en'));
        $this->assertFalse(Translatable::hasLocale($map, 'fr'));  // whitespace = missing
        $this->assertFalse(Translatable::hasLocale($map, 'de'));  // absent
        $this->assertFalse(Translatable::hasLocale(null, 'en'));
    }

    public function test_resolve_uses_app_locale_when_none_given(): void
    {
        app()->setLocale('fr');
        $this->assertSame('Bonjour', Translatable::resolve(['en' => 'Hello', 'fr' => 'Bonjour']));
    }
}
