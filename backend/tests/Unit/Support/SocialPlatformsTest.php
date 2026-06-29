<?php

namespace Tests\Unit\Support;

use App\Support\SocialPlatforms;
use Tests\TestCase;

/**
 * Pure registry logic for the "Contact Us" social platforms. No DB; label()
 * falls through __() which returns the key when no translation is loaded.
 */
class SocialPlatformsTest extends TestCase
{
    public function test_is_known_recognises_built_in_platforms(): void
    {
        $this->assertTrue(SocialPlatforms::isKnown('whatsapp'));
        $this->assertTrue(SocialPlatforms::isKnown('telegram'));
        $this->assertFalse(SocialPlatforms::isKnown('myspace'));
        $this->assertFalse(SocialPlatforms::isKnown(SocialPlatforms::CUSTOM));
    }

    public function test_label_returns_raw_key_for_unknown_platform(): void
    {
        // Unknown platform → the key is returned verbatim (no translation lookup).
        $this->assertSame('myspace', SocialPlatforms::label('myspace'));
    }

    public function test_options_lists_every_known_platform_plus_custom(): void
    {
        $options = SocialPlatforms::options();

        foreach (array_keys(SocialPlatforms::KNOWN) as $key) {
            $this->assertArrayHasKey($key, $options);
        }
        $this->assertArrayHasKey(SocialPlatforms::CUSTOM, $options);
        // Custom is the trailing option.
        $this->assertSame(SocialPlatforms::CUSTOM, array_key_last($options));
        $this->assertCount(count(SocialPlatforms::KNOWN) + 1, $options);
    }

    public function test_enrich_drops_rows_with_empty_value(): void
    {
        $this->assertNull(SocialPlatforms::enrich([]));
        $this->assertNull(SocialPlatforms::enrich(['platform' => 'whatsapp', 'value' => '']));
        $this->assertNull(SocialPlatforms::enrich(['platform' => 'whatsapp', 'value' => '   ']));
    }

    public function test_enrich_fills_default_brand_color_for_known_platform(): void
    {
        $row = SocialPlatforms::enrich(['platform' => 'whatsapp', 'value' => '+201000000000']);

        $this->assertNotNull($row);
        $this->assertSame('whatsapp', $row['platform']);
        $this->assertSame('+201000000000', $row['value']);
        $this->assertSame('#25D366', $row['color']);   // default brand color
        $this->assertNull($row['icon']);               // no custom icon supplied
    }

    public function test_enrich_keeps_explicit_overrides(): void
    {
        $row = SocialPlatforms::enrich([
            'platform' => 'whatsapp',
            'value'    => 'x',
            'label'    => 'Chat with us',
            'color'    => '#000000',
            'icon'     => 'icons/wa.png',
        ]);

        $this->assertSame('Chat with us', $row['label']);
        $this->assertSame('#000000', $row['color']);
        $this->assertSame('icons/wa.png', $row['icon']);
    }

    public function test_enrich_defaults_platform_to_custom_and_trims(): void
    {
        $row = SocialPlatforms::enrich(['value' => '  hello  ']);

        $this->assertSame(SocialPlatforms::CUSTOM, $row['platform']);
        $this->assertSame('hello', $row['value']); // value trimmed
        $this->assertNull($row['color']);          // custom → no default color
        $this->assertSame('custom', $row['label']);
    }
}
