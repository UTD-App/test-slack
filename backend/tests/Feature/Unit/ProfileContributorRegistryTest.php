<?php

namespace Tests\Feature\Unit;

use App\Contracts\ProfileContributor;
use App\Models\User;
use App\Services\ProfileContributorRegistry;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

/**
 * ProfileContributorRegistry merges per-package profile sections, keyed by
 * contributor key. Null sections are omitted; a throwing contributor is
 * isolated (logged + skipped) so one bad section never breaks the profile.
 */
class ProfileContributorRegistryTest extends TestCase
{
    use RefreshDatabase;

    private function registry(): ProfileContributorRegistry
    {
        return new ProfileContributorRegistry();
    }

    private function contributor(string $key, ?array $section, bool $throws = false): ProfileContributor
    {
        return new class($key, $section, $throws) implements ProfileContributor {
            public function __construct(private string $key, private ?array $section, private bool $throws) {}
            public function key(): string { return $this->key; }
            public function contribute(User $target, ?User $viewer): ?array
            {
                if ($this->throws) {
                    throw new \RuntimeException('boom');
                }
                return $this->section;
            }
        };
    }

    public function test_empty_registry_aggregates_to_empty_array(): void
    {
        $sections = $this->registry()->aggregate(User::factory()->create(), null);

        $this->assertSame([], $sections);
    }

    public function test_keys_lists_registered_contributors(): void
    {
        $registry = $this->registry();
        $registry->register($this->contributor('gifts', ['count' => 1]));
        $registry->register($this->contributor('moments', ['count' => 2]));

        $this->assertSame(['gifts', 'moments'], $registry->keys());
    }

    public function test_aggregate_keys_each_section_by_contributor_key(): void
    {
        $registry = $this->registry();
        $registry->register($this->contributor('gifts', ['count' => 12]));
        $registry->register($this->contributor('moments', ['count' => 3, 'items' => []]));

        $sections = $registry->aggregate(User::factory()->create(), null);

        $this->assertSame(['count' => 12], $sections['gifts']);
        $this->assertSame(['count' => 3, 'items' => []], $sections['moments']);
    }

    public function test_null_section_is_omitted(): void
    {
        $registry = $this->registry();
        $registry->register($this->contributor('gifts', null));
        $registry->register($this->contributor('moments', ['count' => 1]));

        $sections = $registry->aggregate(User::factory()->create(), null);

        $this->assertArrayNotHasKey('gifts', $sections);
        $this->assertArrayHasKey('moments', $sections);
    }

    public function test_throwing_contributor_is_skipped_and_logged_not_fatal(): void
    {
        Log::spy();

        $registry = $this->registry();
        $registry->register($this->contributor('bad', null, throws: true));
        $registry->register($this->contributor('good', ['ok' => true]));

        $sections = $registry->aggregate(User::factory()->create(), null);

        // Bad one isolated; good one still merged.
        $this->assertArrayNotHasKey('bad', $sections);
        $this->assertSame(['ok' => true], $sections['good']);
        Log::shouldHaveReceived('warning')->once();
    }

    public function test_re_registering_same_key_overwrites(): void
    {
        $registry = $this->registry();
        $registry->register($this->contributor('gifts', ['v' => 1]));
        $registry->register($this->contributor('gifts', ['v' => 2]));

        $sections = $registry->aggregate(User::factory()->create(), null);

        $this->assertSame(['v' => 2], $sections['gifts']);
        $this->assertCount(1, $registry->keys());
    }

    public function test_viewer_is_passed_through_to_contributor(): void
    {
        $target = User::factory()->create();
        $viewer = User::factory()->create();

        $registry = $this->registry();
        $registry->register(new class implements ProfileContributor {
            public function key(): string { return 'rel'; }
            public function contribute(User $target, ?User $viewer): ?array
            {
                return ['viewer_id' => $viewer?->id, 'target_id' => $target->id];
            }
        });

        $sections = $registry->aggregate($target, $viewer);

        $this->assertSame($viewer->id, $sections['rel']['viewer_id']);
        $this->assertSame($target->id, $sections['rel']['target_id']);
    }
}
