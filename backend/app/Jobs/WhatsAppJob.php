<?php

namespace App\Jobs;

use App\Models\Config;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Delivers an OTP code to a phone over WhatsApp.
 *
 * Ported from Eagle's WhatsAppJob. The gateway is the self-hosted "Safwa" service:
 * a GET to {base_url}/api/send-code-service?code=&phone= with a Bearer token.
 * Both base_url and token are admin-editable via the Config table
 * (keys: whatsapp_base_url, whatsapp_token) — no .env coupling.
 *
 * When the gateway is not configured (local/dev/harness), the code is written to
 * the log instead of being sent, so the recovery flow stays testable end-to-end.
 * The OTP is never returned through the API.
 */
class WhatsAppJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        private readonly string $phone,
        private readonly string $message,
    ) {}

    public function handle(): void
    {
        // Config::map() is cached-forever but auto-flushed on any admin save, so
        // gateway credentials set in App Settings take effect immediately.
        $config = Config::map();
        $baseUrl = $config['whatsapp_base_url'] ?? null;
        $token = $config['whatsapp_token'] ?? null;

        // Fallback: gateway not configured → log the code so dev/harness can read it.
        if (empty($baseUrl) || empty($token)) {
            Log::info('WhatsApp OTP (gateway not configured — dev fallback)', [
                'phone' => $this->phone,
                'code' => $this->message,
            ]);

            return;
        }

        try {
            Http::withHeaders([
                'Authorization' => 'Bearer ' . $token,
                'Content-Type' => 'application/json',
            ])->get(rtrim($baseUrl, '/') . '/api/send-code-service', [
                'code' => $this->message,
                'phone' => $this->phone,
            ]);
        } catch (\Throwable $e) {
            Log::error('WhatsApp OTP send failed', [
                'phone' => $this->phone,
                'error' => $e->getMessage(),
            ]);
        }
    }
}
