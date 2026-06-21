<?php

namespace App\Jobs;

use App\Contracts\Translator;
use App\Models\Language;
use App\Models\TranslationKey;
use App\Services\TranslationLoader;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Bulk AI-translate every UNtranslated UI string for one language, off the
 * request cycle (the synchronous Filament action timed out — Gemini does one API
 * call per item, so hundreds of keys take a while even fanned out concurrently).
 *
 * Writes to lang FILES (lang/<code>/<group>.php), NOT the DB — Laravel __() (the
 * admin dashboard) resolves from files, so this is what actually makes the UI
 * show the language. (Dynamic CONTENT translations stay in the DB elsewhere.)
 *
 * SELF-CONTINUING via a forward OFFSET: each run handles the next {@see self::BATCH}
 * keys of the ordered list then re-dispatches itself at `offset + BATCH`, so every
 * key is visited exactly once and the chain ENDS deterministically when the offset
 * passes the end — it never stalls on a batch that translates nothing (e.g. keys
 * identical in both languages). Each run is short (≪ queue retry_after), so no
 * mid-run reclaim. Idempotent: keys already present in the target files are
 * skipped, so re-clicking only fills the gaps.
 *
 * Source for a UI key = its English value in lang/en/*.php. Requires a queue
 * worker (php artisan queue:work).
 */
class AiTranslateMissingTranslations implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    /** Keys processed per run (each Gemini call ~seconds, fanned out concurrently). */
    private const BATCH = 40;

    /** Mirrors ManageTranslations::$adminGroups (the "admin" tab grouping). */
    private const ADMIN_GROUPS = ['admin', 'dashboard', 'auth', 'validation', 'passwords', 'pagination'];

    public int $timeout = 280;
    public int $tries = 1;

    public function __construct(
        public int $languageId,
        public string $tab = 'admin',
        public ?string $group = null,
        public int $offset = 0,
        public int $done = 0,
    ) {
    }

    public function handle(Translator $translator, TranslationLoader $loader): void
    {
        $lang = Language::find($this->languageId);

        // Nothing to translate to: gone, the source language itself, or no engine.
        if (! $lang || $lang->code === 'en' || ! $translator->isConfigured()) {
            return;
        }

        $keys = TranslationKey::query()
            ->when($this->tab === 'admin',
                fn ($q) => $q->whereIn('group', self::ADMIN_GROUPS),
                fn ($q) => $q->whereNotIn('group', self::ADMIN_GROUPS)
            )
            ->when($this->group, fn ($q) => $q->where('group', $this->group))
            ->orderBy('id')
            ->get();

        // Walked past the end → the whole tab/group has been visited. Done.
        if ($this->offset >= $keys->count()) {
            $loader->clearCache($lang->code);
            return;
        }

        $slice    = $keys->slice($this->offset, self::BATCH);
        $english  = $loader->scanLangFiles('en');
        $existing = $loader->scanLangFiles($lang->code); // current target-file values

        // dotKey => English source, for slice keys still missing from the files.
        $pending = [];
        foreach ($slice as $key) {
            if (filled($existing[$key->key] ?? null)) {
                continue;
            }
            $src = $english[$key->key] ?? null;
            if ($src === null || trim($src) === '') {
                continue;
            }
            $pending[$key->key] = $src;
        }

        if ($pending !== []) {
            $dotKeys    = array_keys($pending);
            $sources    = array_values($pending);
            $translated = $translator->translateBatch($sources, $lang->code, 'en');
            $batchOk    = $translator->lastError() === null;

            // Collect successful translations keyed by full dot key.
            $out = [];
            foreach ($dotKeys as $i => $dotKey) {
                $value = $translated[$i] ?? null;
                if ($value === null || $value === '') {
                    continue;
                }
                // Identical-to-source is a real translation only when the batch had
                // no errors; in a partially-failed batch it's the untouched original
                // → skip so a later re-run retries it.
                if ($value === $sources[$i] && ! $batchOk) {
                    continue;
                }
                $out[$dotKey] = $value;
                $this->done++;
            }

            // Write into lang files, one read-modify-write per group.
            if ($out !== []) {
                $byGroup = [];
                foreach ($out as $dotKey => $value) {
                    $group = explode('.', $dotKey, 2)[0];
                    $byGroup[$group][$dotKey] = $value;
                }
                foreach ($byGroup as $group => $vals) {
                    $loader->writeGroupValues($lang->code, $group, $vals);
                }
                $loader->clearCache($lang->code);
            }
        }

        // Always advance to the next slice (forward progress, deterministic end).
        self::dispatch(
            $this->languageId,
            $this->tab,
            $this->group,
            $this->offset + self::BATCH,
            $this->done,
        );
    }
}
