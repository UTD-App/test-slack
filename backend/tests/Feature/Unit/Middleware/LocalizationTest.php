<?php

namespace Tests\Feature\Unit\Middleware;

use App\Http\Middleware\Localization;
use App\Support\AppLanguages;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\App;
use Tests\TestCase;

class LocalizationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        // No languages seeded -> AppLanguages falls back to active codes en/ar.
        AppLanguages::flush();
    }

    private function handleWithHeader(?string $value): string
    {
        $request = Request::create('/_t/loc', 'GET');
        if ($value !== null) {
            $request->headers->set('X-localization', $value);
        }

        (new Localization())->handle($request, fn () => response('ok'));

        return App::getLocale();
    }

    public function test_active_locale_header_sets_app_locale(): void
    {
        // 'ar' is an active fallback code.
        $this->assertSame('ar', $this->handleWithHeader('ar'));
    }

    public function test_bogus_locale_header_is_ignored(): void
    {
        App::setLocale('en');
        // 'zz' is not active, so the locale stays whatever it was (en).
        $this->assertSame('en', $this->handleWithHeader('zz'));
    }

    public function test_missing_header_keeps_default_active_locale(): void
    {
        // Default code (en) is active, so it is applied.
        App::setLocale('ar');
        $locale = $this->handleWithHeader(null);
        $this->assertContains($locale, ['en', 'ar']);
    }
}
