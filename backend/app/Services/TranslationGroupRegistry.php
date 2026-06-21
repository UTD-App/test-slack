<?php

namespace App\Services;

/**
 * Lets packages contribute their Flutter/UI translation groups to the backend
 * WITHOUT the base depending on those packages — the single seam that makes the
 * whole "backend controls every UI string" system package-ready.
 *
 * A package ships its default values as a lang file
 * `<langDir>/<locale>/<group>.php` (mirroring its Flutter const map, prefix
 * stripped — e.g. `gifts_strings.dart` 'gifts.send' → `resources/lang/en/gifts.php`
 * `['send' => 'Send']`) and registers it from its ServiceProvider boot():
 *
 *   app(TranslationGroupRegistry::class)->register('gifts', self::PACKAGE_ROOT.'/resources/lang');
 *
 * {@see TranslationLoader::scanLangFiles()} then merges every registered group so
 * the keys flow automatically into the translation_keys catalog, the
 * GET /api/translations/{locale} payload, the admin Translations page, and
 * AI-translate-all — no further wiring per package. Admin/AI translations are
 * written centrally to the app's own resource_path('lang') (which overrides these
 * package-shipped defaults), so the package stays read-only and survives reinstall.
 *
 * Bound as a singleton in AppServiceProvider so packages register into the same
 * instance the loader reads. Keyed by group → idempotent across re-boots.
 */
class TranslationGroupRegistry
{
    /** @var array<string, string> group => absolute lang dir (containing <locale>/<group>.php) */
    protected array $groups = [];

    /**
     * Register a translatable UI group shipped by a package.
     *
     * @param  string  $group    The dot-prefix / lang-file name (e.g. 'gifts', 'moment').
     * @param  string  $langDir  A `resources/lang` dir holding `<locale>/<group>.php` defaults.
     */
    public function register(string $group, string $langDir): void
    {
        if ($group === '' || $langDir === '') {
            return;
        }

        $this->groups[$group] = rtrim($langDir, '/\\');
    }

    /** @return array<string, string> group => lang dir, in registration order. */
    public function all(): array
    {
        return $this->groups;
    }
}
