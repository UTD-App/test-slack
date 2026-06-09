<?php

namespace Database\Seeders;

use App\Models\Language;
use App\Models\Translation;
use App\Models\TranslationKey;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\File;

class LanguageSeeder extends Seeder
{
    public function run(): void
    {
        // 1. Seed languages
        $english = Language::firstOrCreate(
            ['code' => 'en'],
            [
                'name'        => 'English',
                'native_name' => 'English',
                'is_rtl'      => false,
                'is_active'   => true,
                'is_default'  => true,
            ]
        );

        $arabic = Language::firstOrCreate(
            ['code' => 'ar'],
            [
                'name'        => 'Arabic',
                'native_name' => 'العربية',
                'is_rtl'      => true,
                'is_active'   => true,
                'is_default'  => false,
            ]
        );

        // 2. Seed translation keys from lang/en/
        $this->command->info('Seeding translation keys from lang/en/...');
        $enPath = resource_path('lang/en');
        $keys   = $this->scanLangDir($enPath);

        foreach ($keys as $dotKey => $enValue) {
            $group = explode('.', $dotKey)[0];

            $keyModel = TranslationKey::firstOrCreate(
                ['key'  => $dotKey],
                ['group' => $group]
            );

            // English translation (from file)
            Translation::firstOrCreate(
                ['language_id' => $english->id, 'translation_key_id' => $keyModel->id],
                ['value' => $enValue]
            );
        }

        $this->command->info('Seeding Arabic translations from lang/ar/...');

        // 3. Seed Arabic translations from lang/ar/
        $arPath  = resource_path('lang/ar');
        $arValues = $this->scanLangDir($arPath);

        foreach ($arValues as $dotKey => $arValue) {
            $keyModel = TranslationKey::where('key', $dotKey)->first();
            if (!$keyModel) continue;

            Translation::firstOrCreate(
                ['language_id' => $arabic->id, 'translation_key_id' => $keyModel->id],
                ['value' => $arValue]
            );
        }

        $this->command->info('Languages seeded: English (default) + Arabic (RTL)');
        $this->command->info('Keys seeded: ' . TranslationKey::count());
    }

    private function scanLangDir(string $path): array
    {
        if (!File::isDirectory($path)) {
            return [];
        }

        $result = [];

        foreach (File::files($path) as $file) {
            if ($file->getExtension() !== 'php') continue;

            $group  = $file->getFilenameWithoutExtension();
            $values = include $file->getPathname();

            if (!is_array($values)) continue;

            foreach ($this->flatten($values, $group) as $key => $value) {
                $result[$key] = (string) $value;
            }
        }

        return $result;
    }

    private function flatten(array $array, string $prefix = ''): array
    {
        $result = [];
        foreach ($array as $key => $value) {
            $fullKey = $prefix ? "{$prefix}.{$key}" : $key;
            if (is_array($value)) {
                $result = array_merge($result, $this->flatten($value, $fullKey));
            } else {
                $result[$fullKey] = $value;
            }
        }
        return $result;
    }
}
