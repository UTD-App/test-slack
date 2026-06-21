<?php

namespace App\Contracts;

/**
 * Auto-translate engine used by the translatable-content system (the admin
 * "Translate" buttons). Implementations must FAIL SOFT — never throw; return the
 * original text on any error and expose the reason via {@see lastError()}.
 *
 * Bound to a concrete driver in AppServiceProvider per config('services.translator.driver')
 * (gemini | google). Resolve via app(\App\Contracts\Translator::class).
 */
interface Translator
{
    /** Translate one string. Returns the original on failure / blank / oversize. */
    public function translate(string $text, string $targetLang, ?string $sourceLang = null, bool $html = false): string;

    /**
     * Translate many strings; the returned array preserves order and length
     * (blank/oversize items and every item on failure keep their original value).
     *
     * @param  array<int,string>  $texts
     * @return array<int,string>
     */
    public function translateBatch(array $texts, string $targetLang, ?string $sourceLang = null, bool $html = false): array;

    /** Whether the engine has the credentials/config it needs to translate. */
    public function isConfigured(): bool;

    /** The reason the last call returned originals, or null on success. */
    public function lastError(): ?string;
}
