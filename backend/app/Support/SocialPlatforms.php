<?php

namespace App\Support;

/**
 * Shared registry of the social/contact platforms surfaced on the app's
 * "Contact Us" screen (Admin → App Settings → Contact Us).
 *
 * For a *known* platform the admin only picks it from a dropdown and types the
 * link — the icon and brand color are supplied here (the app keeps the matching
 * icons keyed by the same platform key). For anything else the admin chooses
 * the {@see self::CUSTOM} option and uploads a custom icon + color, so the list
 * is fully extensible without a code change.
 *
 * The platform keys MUST stay in sync with the Flutter `_platformRegistry`
 * in `contact_us_screen.dart` (same keys → same icons).
 */
final class SocialPlatforms
{
    /** The "anything else" option — admin uploads icon + color. */
    public const CUSTOM = 'custom';

    /**
     * Known platforms keyed by platform key.
     *  - color : default brand color (hex), used when the admin doesn't override.
     *  - url   : how the app turns the stored value into a tappable link
     *            ('whatsapp' = wa.me deep link, 'http' = plain web URL).
     *
     * The human label is NOT stored here — it comes from the existing
     * `admin.social_{key}` translations so it stays localized.
     *
     * @var array<string,array{color:string,url:string}>
     */
    public const KNOWN = [
        'whatsapp'  => ['color' => '#25D366', 'url' => 'whatsapp'],
        'website'   => ['color' => '#42A5F5', 'url' => 'http'],
        'facebook'  => ['color' => '#1877F2', 'url' => 'http'],
        'instagram' => ['color' => '#E4405F', 'url' => 'http'],
        'twitter'   => ['color' => '#1DA1F2', 'url' => 'http'],
        'youtube'   => ['color' => '#FF0000', 'url' => 'http'],
        'tiktok'    => ['color' => '#69C9D0', 'url' => 'http'],
        'snapchat'  => ['color' => '#FFC400', 'url' => 'http'],
        'telegram'  => ['color' => '#29A9EB', 'url' => 'http'],
    ];

    /** Whether a platform key is one of the known platforms. */
    public static function isKnown(string $platform): bool
    {
        return array_key_exists($platform, self::KNOWN);
    }

    /** Localized label for a platform key (known → translation, else the key). */
    public static function label(string $platform): string
    {
        if (self::isKnown($platform)) {
            return __('admin.social_' . $platform);
        }

        return $platform;
    }

    /**
     * Options for the admin platform dropdown: every known platform (localized
     * label) plus the trailing "Other / Custom" choice.
     *
     * @return array<string,string>
     */
    public static function options(): array
    {
        $options = [];
        foreach (array_keys(self::KNOWN) as $key) {
            $options[$key] = self::label($key);
        }
        $options[self::CUSTOM] = __('admin.social_platform_custom');

        return $options;
    }

    /**
     * Normalize one stored repeater item into the public API shape, filling in
     * the default label/color for known platforms. Returns null when the item
     * has no usable value (so callers can drop empty rows).
     *
     * @param  array<string,mixed>  $item
     * @return array{platform:string,label:string,value:string,icon:?string,color:?string}|null
     */
    public static function enrich(array $item): ?array
    {
        $value = trim((string) ($item['value'] ?? ''));
        if ($value === '') {
            return null;
        }

        $platform = (string) ($item['platform'] ?? self::CUSTOM);
        $known    = self::KNOWN[$platform] ?? null;

        $label = trim((string) ($item['label'] ?? ''));
        if ($label === '') {
            $label = self::label($platform);
        }

        $color = trim((string) ($item['color'] ?? ''));
        if ($color === '') {
            $color = $known['color'] ?? null;
        }

        $icon = trim((string) ($item['icon'] ?? ''));

        return [
            'platform' => $platform,
            'label'    => $label,
            'value'    => $value,
            'icon'     => $icon !== '' ? $icon : null,
            'color'    => $color !== '' ? $color : null,
        ];
    }
}
