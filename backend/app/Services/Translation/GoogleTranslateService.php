<?php

namespace App\Services\Translation;

use App\Contracts\Translator;
use Google\Auth\ApplicationDefaultCredentials;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Thin wrapper over the Google Cloud Translation API (v2 REST) used by the admin
 * "Translate" buttons in the translatable-content system. HTML-aware: pass
 * $html = true for rich bodies so tags/attributes are preserved.
 *
 * Auth: an API key (GOOGLE_TRANSLATE_API_KEY) takes precedence; otherwise an ADC
 * bearer token is minted from the service-account key file (the same file the GCS
 * storage uses), with the path normalized to absolute the way
 * {@see \App\Services\StorageConfigService::gcsConfig()} does (relative paths
 * break under php-fpm whose CWD is public/).
 *
 * Fails soft: any auth/HTTP error logs a warning, records {@see lastError()} and
 * returns the ORIGINAL text — translation never throws into the Filament action.
 *
 * Ops: enable the "Cloud Translation API" + billing on the project; the service
 * account needs roles/cloudtranslate.user.
 */
class GoogleTranslateService implements Translator
{
    /** Hard ceiling for a single text. Oversize content is left untranslated. */
    private const MAX_CHARS = 30000;

    private const TOKEN_CACHE_KEY = 'google_translate.access_token';

    private ?string $lastError = null;

    public function isConfigured(): bool
    {
        if (! config('services.google_translate.enabled', true)) {
            return false;
        }

        if (config('services.google_translate.api_key')) {
            return true;
        }

        $keyFile = $this->resolveKeyFilePath();

        return $keyFile !== null && is_file($keyFile);
    }

    /** The reason the last call returned originals, or null on success. */
    public function lastError(): ?string
    {
        return $this->lastError;
    }

    /**
     * Translate one string. Returns the original on any failure / when blank /
     * when over the size limit.
     */
    public function translate(string $text, string $targetLang, ?string $sourceLang = null, bool $html = false): string
    {
        return $this->translateBatch([$text], $targetLang, $sourceLang, $html)[0] ?? $text;
    }

    /**
     * Translate many strings in one request. The returned array preserves order
     * and length; blank / oversize items, and every item on failure, keep their
     * original value.
     *
     * @param  array<int,string>  $texts
     * @return array<int,string>
     */
    public function translateBatch(array $texts, string $targetLang, ?string $sourceLang = null, bool $html = false): array
    {
        $this->lastError = null;
        $result = array_values($texts);

        if (! $this->isConfigured()) {
            $this->lastError = 'not_configured';

            return $result;
        }

        // Only send non-empty texts within the size limit; the rest keep original.
        $send = [];
        foreach ($result as $i => $text) {
            if (! is_string($text) || trim($text) === '') {
                continue;
            }
            if (mb_strlen($text) > self::MAX_CHARS) {
                $this->lastError = 'too_large';
                continue;
            }
            $send[$i] = $text;
        }

        if ($send === []) {
            return $result;
        }

        try {
            [$url, $headers] = $this->endpointAndHeaders();

            $payload = [
                'q'      => array_values($send),
                'target' => $targetLang,
                'format' => $html ? 'html' : 'text',
            ];
            if ($sourceLang) {
                $payload['source'] = $sourceLang;
            }

            $response = Http::asJson()->withHeaders($headers)->post($url, $payload);

            if ($response->failed()) {
                $this->lastError = 'http_' . $response->status();
                Log::warning('GoogleTranslate request failed', [
                    'status' => $response->status(),
                    'body'   => $response->body(),
                ]);

                return $result;
            }

            $translations = $response->json('data.translations', []);
            $offset = 0;
            foreach (array_keys($send) as $originalIndex) {
                $translated = $translations[$offset]['translatedText'] ?? null;
                if (is_string($translated) && $translated !== '') {
                    $result[$originalIndex] = $translated;
                }
                $offset++;
            }
        } catch (\Throwable $e) {
            $this->lastError = $e->getMessage();
            Log::warning('GoogleTranslate exception', ['error' => $e->getMessage()]);

            return array_values($texts);
        }

        return $result;
    }

    /**
     * The request URL (with ?key= when using an API key) and auth headers
     * (Bearer token when using ADC).
     *
     * @return array{0:string,1:array<string,string>}
     */
    private function endpointAndHeaders(): array
    {
        $endpoint = (string) config(
            'services.google_translate.endpoint',
            'https://translation.googleapis.com/language/translate/v2'
        );

        $apiKey = config('services.google_translate.api_key');
        if ($apiKey) {
            return [$endpoint . '?key=' . urlencode((string) $apiKey), []];
        }

        $token = $this->bearerToken();
        if (! $token) {
            throw new \RuntimeException('Unable to obtain a Google access token for translation.');
        }

        return [$endpoint, ['Authorization' => 'Bearer ' . $token]];
    }

    /** Mint (and cache ~50 min) an ADC access token scoped to Cloud Translation. */
    private function bearerToken(): ?string
    {
        return Cache::remember(self::TOKEN_CACHE_KEY, now()->addMinutes(50), function () {
            $keyFile = $this->resolveKeyFilePath();
            if ($keyFile && ! getenv('GOOGLE_APPLICATION_CREDENTIALS')) {
                putenv('GOOGLE_APPLICATION_CREDENTIALS=' . $keyFile);
            }

            $credentials = ApplicationDefaultCredentials::getCredentials(
                'https://www.googleapis.com/auth/cloud-translation'
            );

            $token = $credentials->fetchAuthToken();

            return $token['access_token'] ?? null;
        });
    }

    /** Absolute path to the service-account key file, or null if none configured. */
    private function resolveKeyFilePath(): ?string
    {
        $path = config('services.google_translate.key_file') ?: base_path('service-account.json');

        if (! is_string($path) || $path === '') {
            return null;
        }

        if (! $this->isAbsolutePath($path)) {
            $path = base_path($path);
        }

        return $path;
    }

    /** Whether $path is absolute: Unix "/..." or Windows "C:\..." / "C:/...". */
    private function isAbsolutePath(string $path): bool
    {
        return (bool) preg_match('#^(/|[A-Za-z]:[\\\\/])#', $path);
    }
}
