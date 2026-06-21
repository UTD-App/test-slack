<?php

namespace App\Services\Translation;

use App\Contracts\Translator;
use App\Support\AppLanguages;
use Google\Auth\ApplicationDefaultCredentials;
use Illuminate\Http\Client\Pool;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Gemini-based auto-translate engine (the default {@see Translator}). Higher
 * quality than plain machine translation for long/HTML content and nuance.
 *
 * Auth (two modes via `services.gemini.driver_mode`):
 *   - 'api_key' (default): Google **Generative Language API** (AI Studio) —
 *     just GEMINI_API_KEY, no project/IAM. Simplest, lowest-risk.
 *   - 'vertex': **Vertex AI** with an ADC bearer token (reuses the
 *     service-account key file + absolute-path normalization from
 *     {@see \App\Services\StorageConfigService::gcsConfig()}). Needs the Vertex
 *     AI API enabled + roles/aiplatform.user on the project.
 *
 * Fails soft: any error logs a warning, records {@see lastError()} and returns
 * the ORIGINAL text — translation never throws into the Filament action.
 */
class GeminiTranslateService implements Translator
{
    private const MAX_CHARS = 30000;
    private const TOKEN_CACHE_KEY = 'gemini.access_token';

    /** Max concurrent Gemini calls per round (bulk translate fans out — Gemini has
     *  no multi-text endpoint; capped to stay under provider rate limits). */
    private const CONCURRENCY = 10;

    private ?string $lastError = null;

    public function isConfigured(): bool
    {
        if (! config('services.gemini.enabled', true)) {
            return false;
        }

        if ($this->mode() === 'vertex') {
            // Rely on ambient ADC (gcloud / metadata) or an explicit key file; the
            // actual call fails soft if no usable credentials are present.
            return true;
        }

        return (bool) config('services.gemini.api_key');
    }

    public function lastError(): ?string
    {
        return $this->lastError;
    }

    public function translate(string $text, string $targetLang, ?string $sourceLang = null, bool $html = false): string
    {
        return $this->translateBatch([$text], $targetLang, $sourceLang, $html)[0] ?? $text;
    }

    /**
     * Gemini's generateContent is single-prompt (no multi-text endpoint), so each
     * text is its own request — but they're fired CONCURRENTLY in capped rounds
     * ({@see self::CONCURRENCY}) via Http::pool, which is ~Nx faster than the old
     * sequential loop for bulk translate (hundreds of UI keys). The Vertex token /
     * endpoint is resolved ONCE and reused. Order/length preserved; fail-soft per
     * item (blank/oversize/failed items keep their original value).
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

        // Resolve endpoint + auth once (mints/caches the Vertex token a single time).
        try {
            [$url, $headers] = $this->endpointAndHeaders();
        } catch (\Throwable $e) {
            $this->lastError = $e->getMessage();
            Log::warning('Gemini auth failed', ['error' => $e->getMessage()]);

            return $result;
        }

        foreach (array_chunk($send, self::CONCURRENCY, true) as $chunk) {
            $responses = Http::pool(fn (Pool $pool) => array_map(
                fn ($i) => $pool->as((string) $i)
                    // Per-request caps so one slow/hung call can't stall the whole
                    // batch past the queue's retry_after (which would reclaim the
                    // job → MaxAttemptsExceeded). A timed-out call fails soft.
                    ->connectTimeout(10)
                    ->timeout(45)
                    ->asJson()
                    ->withHeaders($headers)
                    ->post($url, [
                        'contents' => [[
                            'role'  => 'user',
                            'parts' => [['text' => $this->buildPrompt($chunk[$i], $sourceLang, $targetLang, $html)]],
                        ]],
                        'generationConfig' => ['temperature' => 0],
                    ]),
                array_keys($chunk)
            ));

            foreach (array_keys($chunk) as $i) {
                $parsed = $this->parseResponse($responses[(string) $i] ?? null);
                if ($parsed !== null) {
                    $result[$i] = $parsed;
                }
            }
        }

        return $result;
    }

    /**
     * Extract the translated text from one Gemini response (or a pool error).
     * null = keep original (error recorded in {@see lastError()}).
     */
    private function parseResponse($response): ?string
    {
        if (! $response instanceof Response) {
            $this->lastError = 'pool_error';
            if ($response instanceof \Throwable) {
                Log::warning('Gemini pool exception', ['error' => $response->getMessage()]);
            }

            return null;
        }

        if ($response->failed()) {
            $this->lastError = 'http_' . $response->status();
            Log::warning('Gemini request failed', ['status' => $response->status(), 'body' => $response->body()]);

            return null;
        }

        $out = $response->json('candidates.0.content.parts.0.text');
        if (! is_string($out) || trim($out) === '') {
            $this->lastError = 'empty_response';

            return null;
        }

        return $this->stripCodeFence($out);
    }

    private function buildPrompt(string $text, ?string $sourceLang, string $targetLang, bool $html): string
    {
        $names  = AppLanguages::names();
        $target = $names[$targetLang] ?? strtoupper($targetLang);

        $from = $sourceLang
            ? 'from ' . ($names[$sourceLang] ?? strtoupper($sourceLang)) . ' '
            : '';

        $instruction = "Translate the following text {$from}to {$target}. "
            . 'Return ONLY the translated text, with no explanations, quotes, or preamble. '
            // UI strings often contain Laravel/ICU placeholders — they are NOT words
            // to translate and must survive verbatim or the rendered string breaks.
            . 'Keep any placeholder tokens EXACTLY as-is and untranslated: '
            . ':name style (:attribute, :seconds…), :Name/:NAME casing variants, '
            . '{0}/{1} and {count}/:count style, and %s/%d.';

        $instruction .= $html
            ? ' The text is HTML — preserve all tags, attributes and structure exactly; translate only the human-readable text between tags.'
            : ' Return plain text.';

        return $instruction . "\n\n" . $text;
    }

    /**
     * Endpoint URL (with ?key= for the API-key mode) + auth headers (Bearer for
     * Vertex).
     *
     * @return array{0:string,1:array<string,string>}
     */
    private function endpointAndHeaders(): array
    {
        $model = (string) config('services.gemini.model', 'gemini-2.5-flash');

        if ($this->mode() === 'vertex') {
            $project  = (string) config('services.gemini.project_id', 'aitry-476410');
            $location = (string) config('services.gemini.location', 'us-central1');

            // The 'global' location uses the unprefixed host; regions are prefixed.
            $host = $location === 'global'
                ? 'https://aiplatform.googleapis.com'
                : "https://{$location}-aiplatform.googleapis.com";
            $url = "{$host}/v1/projects/{$project}/locations/{$location}/publishers/google/models/{$model}:generateContent";

            $token = $this->bearerToken();
            if (! $token) {
                throw new \RuntimeException('Unable to obtain a Google access token for Vertex AI.');
            }

            return [$url, [
                'Authorization'       => 'Bearer ' . $token,
                'X-Goog-User-Project' => $project, // billing/quota project (needed for user ADC)
            ]];
        }

        $base   = rtrim((string) config('services.gemini.base_url', 'https://generativelanguage.googleapis.com'), '/');
        $apiKey = (string) config('services.gemini.api_key');

        return ["{$base}/v1beta/models/{$model}:generateContent?key=" . urlencode($apiKey), []];
    }

    private function mode(): string
    {
        return config('services.gemini.driver_mode', 'api_key') === 'vertex' ? 'vertex' : 'api_key';
    }

    /** Mint (and cache ~50 min) an ADC token scoped to cloud-platform (Vertex). */
    private function bearerToken(): ?string
    {
        return Cache::remember(self::TOKEN_CACHE_KEY, now()->addMinutes(50), function () {
            $keyFile = $this->resolveKeyFilePath();
            if ($keyFile && ! getenv('GOOGLE_APPLICATION_CREDENTIALS')) {
                putenv('GOOGLE_APPLICATION_CREDENTIALS=' . $keyFile);
            }

            $credentials = ApplicationDefaultCredentials::getCredentials('https://www.googleapis.com/auth/cloud-platform');
            $token = $credentials->fetchAuthToken();

            return $token['access_token'] ?? null;
        });
    }

    private function resolveKeyFilePath(): ?string
    {
        // Only an EXPLICIT gemini key file (service account or a gcloud ADC json).
        // When null we leave GOOGLE_APPLICATION_CREDENTIALS untouched so google/auth
        // discovers the ambient ADC (gcloud well-known file / GCE metadata).
        $path = config('services.gemini.key_file');

        if (! is_string($path) || $path === '') {
            return null;
        }

        if (! $this->isAbsolutePath($path)) {
            $path = base_path($path);
        }

        return $path;
    }

    private function isAbsolutePath(string $path): bool
    {
        return (bool) preg_match('#^(/|[A-Za-z]:[\\\\/])#', $path);
    }

    /** Models sometimes wrap output in a ```/```html fence — strip it. */
    private function stripCodeFence(string $text): string
    {
        $s = trim($text);
        if (! str_starts_with($s, '```')) {
            return $s;
        }
        $s = preg_replace('/^`{3,}[^\n]*\n?/', '', $s) ?? $s;
        $s = preg_replace('/`{3,}\s*$/', '', $s) ?? $s;

        return trim($s);
    }
}
