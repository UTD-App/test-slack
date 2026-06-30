<?php

namespace Tests\Unit\Support;

use Illuminate\Support\Arr;
use Tests\TestCase;

/**
 * Guards against translation drift: every EN lang file (base app + each package)
 * must have an AR counterpart with the SAME set of keys, and vice-versa. A key
 * present in one locale but not the other silently falls back to the raw key /
 * other-locale string in the app — this test fails loudly instead.
 *
 * audio-room is intentionally excluded (no backend i18n yet; owner's package).
 */
class TranslationParityTest extends TestCase
{
    public function test_every_lang_group_has_en_ar_key_parity(): void
    {
        $root = base_path();

        // Base app + every package's lang dir. Profile ships `Resources` (capital);
        // the rest use `resources` — glob both so the check is filesystem-agnostic.
        $enDirs = array_unique(array_merge(
            glob("{$root}/resources/lang/en", GLOB_ONLYDIR) ?: [],
            glob("{$root}/packages/*/resources/lang/en", GLOB_ONLYDIR) ?: [],
            glob("{$root}/packages/*/Resources/lang/en", GLOB_ONLYDIR) ?: [],
        ));

        $problems = [];

        foreach ($enDirs as $enDir) {
            if (str_contains($enDir, 'audio-room')) {
                continue;
            }
            $arDir = preg_replace('#[\\\\/]en$#', DIRECTORY_SEPARATOR.'ar', $enDir);

            foreach (glob("{$enDir}/*.php") as $enFile) {
                $name = basename($enFile);
                $rel  = ltrim(str_replace($root, '', $enFile), '\\/');
                $arFile = $arDir.DIRECTORY_SEPARATOR.$name;

                if (! is_file($arFile)) {
                    $problems[] = "Missing AR file for {$rel}";
                    continue;
                }

                $enKeys = array_keys(Arr::dot(require $enFile));
                $arKeys = array_keys(Arr::dot(require $arFile));

                foreach (array_diff($enKeys, $arKeys) as $k) {
                    $problems[] = "{$rel}: key '{$k}' in EN but missing in AR";
                }
                foreach (array_diff($arKeys, $enKeys) as $k) {
                    $problems[] = "{$rel}: key '{$k}' in AR but missing in EN";
                }
            }

            // AR files with no EN counterpart.
            foreach (glob("{$arDir}/*.php") as $arFile) {
                $name = basename($arFile);
                if (! is_file($enDir.DIRECTORY_SEPARATOR.$name)) {
                    $rel = ltrim(str_replace($root, '', $arFile), '\\/');
                    $problems[] = "Missing EN file for {$rel}";
                }
            }
        }

        $problems = array_values(array_unique($problems));

        $this->assertSame(
            [],
            $problems,
            "Translation EN/AR drift detected:\n  - ".implode("\n  - ", $problems),
        );
    }
}
