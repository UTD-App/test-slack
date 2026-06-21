<?php

namespace App\Services;

use App\Models\Config;

/**
 * Applies admin-configured SMTP settings (from the Config table, edited in
 * App Settings → Mail) onto the runtime mail config, so the mail transport is
 * manageable from the dashboard without touching .env. Mirrors StorageConfigService.
 *
 * When no `mail_host` is configured it does nothing, so the app falls back to the
 * .env defaults (e.g. MAIL_MAILER=log in dev/harness).
 */
class MailConfigService
{
    public function configure(): void
    {
        $map = Config::map();

        $host = $map['mail_host'] ?? null;
        if (empty($host)) {
            return; // not configured — keep .env defaults
        }

        // 'none'/'' → no encryption; otherwise 'ssl' (465) or 'tls' (587).
        $encryption = $map['mail_encryption'] ?? 'tls';
        if ($encryption === 'none' || $encryption === '') {
            $encryption = null;
        }

        config([
            'mail.default' => $map['mail_mailer'] ?? 'smtp',
            'mail.mailers.smtp.host' => $host,
            'mail.mailers.smtp.port' => (int) ($map['mail_port'] ?? 587),
            'mail.mailers.smtp.encryption' => $encryption,
            'mail.mailers.smtp.username' => $map['mail_username'] ?? null,
            'mail.mailers.smtp.password' => $map['mail_password'] ?? null,
        ]);

        if (!empty($map['mail_from_address'])) {
            config([
                'mail.from.address' => $map['mail_from_address'],
                'mail.from.name' => ($map['mail_from_name'] ?? '') ?: config('app.name'),
            ]);
        }
    }
}
