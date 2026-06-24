<?php

namespace Tests\Feature;

use App\Models\Language;
use App\Services\TranslationLoader;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/**
 * Runtime translation edits (dashboard / AI / UTD Studio) must persist in the DB
 * and OVERLAY the git-tracked lang-file defaults — never write the files. This is
 * what fixes "key saved on the server but value missing" (the file write was
 * reverted by deploy / stale-cached by OPcache) and the git conflicts on push.
 */
class TranslationStorageTest extends TestCase
{
    use RefreshDatabase;

    private function loader(): TranslationLoader
    {
        return app(TranslationLoader::class);
    }

    private function english(): Language
    {
        return Language::create([
            'code'        => 'en',
            'name'        => 'English',
            'native_name' => 'English',
            'is_rtl'      => false,
            'is_active'   => true,
            'is_default'  => true,
        ]);
    }

    public function test_runtime_write_persists_to_db_and_not_to_lang_files(): void
    {
        $this->english();
        $loader = $this->loader();

        $key = 'app.__storage_test_key';
        $written = $loader->writeGroupValues('en', 'app', [$key => 'Hello']);

        $this->assertSame(1, $written);
        // Persisted in the DB override store…
        $this->assertDatabaseHas('translation_keys', ['key' => $key]);
        $this->assertDatabaseHas('translations', ['value' => 'Hello']);
        // …visible through the resolved read…
        $this->assertSame('Hello', $loader->resolvedValues('en')[$key] ?? null);
        $this->assertSame('Hello', $loader->getValue('en', $key));
        // …and the lang FILE was never touched (the key isn't in the file scan).
        $this->assertArrayNotHasKey($key, $loader->scanLangFiles('en'));
    }

    public function test_db_override_wins_over_file_default(): void
    {
        $this->english();
        $loader = $this->loader();

        // Pick a real key that exists in the lang files.
        $fileValues = $loader->scanLangFiles('en');
        $this->assertNotEmpty($fileValues, 'expected lang/en/* to provide keys');
        $key      = array_key_first($fileValues);
        $original = $fileValues[$key];
        $group    = explode('.', $key)[0];

        $loader->writeGroupValues('en', $group, [$key => '__OVERRIDDEN__']);

        // Resolved read returns the DB override, not the file default.
        $this->assertSame('__OVERRIDDEN__', $loader->resolvedValues('en')[$key]);
        $this->assertSame('__OVERRIDDEN__', $loader->getValue('en', $key));
        // The file on disk is unchanged — defaults stay in git.
        $this->assertSame($original, $loader->scanLangFiles('en')[$key]);
    }

    public function test_blank_override_falls_back_to_file_default(): void
    {
        $this->english();
        $loader = $this->loader();

        $fileValues = $loader->scanLangFiles('en');
        $key        = array_key_first($fileValues);
        $original   = $fileValues[$key];
        $group      = explode('.', $key)[0];

        // Clearing a translation (empty value) should reveal the file default again.
        $loader->writeGroupValues('en', $group, [$key => '']);

        $this->assertArrayNotHasKey($key, $loader->dbValues('en'));
        $this->assertSame($original, $loader->resolvedValues('en')[$key]);
    }

    public function test_write_is_ignored_for_unknown_locale(): void
    {
        // No Language row for 'zz' → nothing should be written.
        $written = $this->loader()->writeGroupValues('zz', 'app', ['app.x' => 'Y']);

        $this->assertSame(0, $written);
        $this->assertDatabaseCount('translations', 0);
    }
}
