<?php

namespace App\Services;

use App\Models\PackageSetting;

class SettingService
{
    /**
     * Register package setting definitions (idempotent — keyed by `key`).
     *
     * Uses updateOrCreate so a package upgrade that changes a setting's
     * definition (type / default / label) is reflected on re-sync. Any
     * admin-set runtime *value* lives in a separate table and is untouched.
     *
     * @param array<int, array{key:string, type?:string, default?:mixed, label_key?:string}> $settings
     */
    public function registerSettings(array $settings, ?string $package = null): void
    {
        foreach ($settings as $setting) {
            if (empty($setting['key'])) {
                continue;
            }

            PackageSetting::updateOrCreate(
                ['key' => $setting['key']],
                [
                    'package'       => $package ?? 'base',
                    'type'          => $setting['type'] ?? 'bool',
                    'default_value' => $setting['default'] ?? null,
                    'label_key'     => $setting['label_key'] ?? null,
                ],
            );
        }
    }

    /**
     * All setting definitions, optionally scoped to a package.
     *
     * @return array<string, mixed>  key => default_value
     */
    public function defaults(?string $package = null): array
    {
        return PackageSetting::query()
            ->when($package, fn ($q) => $q->where('package', $package))
            ->pluck('default_value', 'key')
            ->toArray();
    }
}
