<?php

namespace Tests\Unit\Support;

use App\Support\UtdManifest;
use Tests\TestCase;

/**
 * In-memory package manifest registry. Static state, so each test flushes first.
 */
class UtdManifestTest extends TestCase
{
    protected function setUp(): void
    {
        parent::setUp();
        UtdManifest::flush();
    }

    protected function tearDown(): void
    {
        UtdManifest::flush();
        parent::tearDown();
    }

    public function test_register_ignores_entries_without_a_key(): void
    {
        UtdManifest::registerPackage(['name' => 'No Key']);
        $this->assertSame([], UtdManifest::all());
    }

    public function test_register_applies_defaults(): void
    {
        UtdManifest::registerPackage(['key' => 'chat']);

        $pkg = UtdManifest::get('chat');
        $this->assertSame('Chat', $pkg['name']);            // ucfirst(key)
        $this->assertNull($pkg['icon']);
        $this->assertSame([], $pkg['screens']);
        $this->assertSame([], $pkg['elements']);
        $this->assertSame([], $pkg['action_elements']);
        $this->assertSame([], $pkg['conversation_flags']);
        $this->assertSame([], $pkg['default_screens']);
    }

    public function test_register_preserves_supplied_values_over_defaults(): void
    {
        UtdManifest::registerPackage([
            'key'     => 'chat',
            'name'    => 'Messaging',
            'icon'    => 'chat_bubble',
            'screens' => ['conversations'],
        ]);

        $pkg = UtdManifest::get('chat');
        $this->assertSame('Messaging', $pkg['name']);
        $this->assertSame('chat_bubble', $pkg['icon']);
        $this->assertSame(['conversations'], $pkg['screens']);
    }

    public function test_register_is_idempotent_per_key(): void
    {
        UtdManifest::registerPackage(['key' => 'chat', 'name' => 'A']);
        UtdManifest::registerPackage(['key' => 'chat', 'name' => 'B']);

        $this->assertCount(1, UtdManifest::all());
        $this->assertSame('B', UtdManifest::get('chat')['name']); // last wins
    }

    public function test_all_returns_zero_indexed_list(): void
    {
        UtdManifest::registerPackage(['key' => 'a']);
        UtdManifest::registerPackage(['key' => 'b']);

        $all = UtdManifest::all();
        $this->assertCount(2, $all);
        $this->assertSame([0, 1], array_keys($all));
    }

    public function test_get_returns_null_for_unknown_key(): void
    {
        $this->assertNull(UtdManifest::get('nope'));
    }
}
