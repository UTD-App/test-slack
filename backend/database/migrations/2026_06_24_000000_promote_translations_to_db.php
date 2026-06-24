<?php

use App\Models\Language;
use App\Models\Translation;
use App\Models\TranslationKey;
use App\Services\TranslationLoader;
use Illuminate\Database\Migrations\Migration;

/**
 * UI translations now live in the DB (`translations`) and OVERLAY the git-tracked
 * lang-file defaults, instead of being written back into the files. The files
 * broke as the runtime store: a deploy's `git pull` reverted owner/Studio edits,
 * OPcache served the stale compiled file, and every push conflicted with the
 * runtime-written file.
 *
 * This one-off promotes the CURRENT effective values (the old file-wins
 * resolution) into the DB so the new DB-wins read reproduces EXACTLY what the
 * server shows today — including values currently sitting only in committed lang
 * files. Idempotent (updateOrCreate); safe to re-run.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (! class_exists(TranslationLoader::class)) {
            return; // defensive: nothing to do without the service
        }

        $loader = app(TranslationLoader::class);

        foreach (Language::all() as $language) {
            // Effective values under the OLD precedence (file wins over legacy DB).
            $current = array_merge(
                $loader->dbValues($language->code),
                $loader->scanLangFiles($language->code),
            );

            foreach ($current as $dotKey => $value) {
                if (! is_string($value) || $value === '' || ! str_contains($dotKey, '.')) {
                    continue;
                }

                $group = explode('.', $dotKey)[0];
                $key   = TranslationKey::firstOrCreate(['key' => $dotKey], ['group' => $group]);

                Translation::updateOrCreate(
                    ['language_id' => $language->id, 'translation_key_id' => $key->id],
                    ['value' => $value],
                );
            }
        }

        // Bump every locale's version so devices re-fetch the now-authoritative set.
        $loader->clearAllCaches();
    }

    public function down(): void
    {
        // No safe rollback: promoted rows are indistinguishable from later edits.
    }
};
