<?php

use App\Models\User;

// Create 15 demo users via the factory (idempotent-ish: only tops up to 15).
$existing = User::where('email', 'like', '%@example.%')->count();
$toCreate = max(0, 15 - $existing);
if ($toCreate > 0) {
    User::factory()->count($toCreate)->create();
}

echo "Total users: " . User::count() . PHP_EOL;
echo "--- sample UUIDs to search with ---" . PHP_EOL;
foreach (User::query()->latest('id')->take(6)->get(['id', 'name', 'uuid']) as $u) {
    echo $u->id . " | " . $u->uuid . " | " . $u->name . PHP_EOL;
}
