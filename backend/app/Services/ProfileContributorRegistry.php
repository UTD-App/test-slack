<?php

namespace App\Services;

use App\Contracts\ProfileContributor;
use App\Models\User;
use Illuminate\Support\Facades\Log;

/**
 * Collects {@see ProfileContributor}s registered by feature packages and merges
 * their sections into a profile payload. Mirrors {@see UserDataService}: a
 * singleton that packages push into during provider boot(). A failing contributor
 * is isolated (logged + skipped) so one bad section never breaks the profile.
 */
class ProfileContributorRegistry
{
    /** @var array<string, ProfileContributor> */
    protected array $contributors = [];

    public function register(ProfileContributor $contributor): void
    {
        $this->contributors[$contributor->key()] = $contributor;
    }

    /** @return string[] keys of the registered contributors */
    public function keys(): array
    {
        return array_keys($this->contributors);
    }

    /**
     * Merge every registered contributor's section, keyed by contributor key.
     * Absent packages contribute nothing; failures are skipped.
     */
    public function aggregate(User $target, ?User $viewer): array
    {
        $sections = [];

        foreach ($this->contributors as $key => $contributor) {
            try {
                $section = $contributor->contribute($target, $viewer);
                if ($section !== null) {
                    $sections[$key] = $section;
                }
            } catch (\Throwable $e) {
                Log::warning("Profile contributor [{$key}] failed", ['error' => $e->getMessage()]);
            }
        }

        return $sections;
    }
}
