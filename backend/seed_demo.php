<?php

use App\Models\User;

$u = User::firstOrCreate(['email' => 'demo@chat.test'], ['name' => 'Demo User']);
$peer = User::firstOrCreate(['email' => 'peer@chat.test'], ['name' => 'Peer User']);

$u->tokens()->delete();
$token = $u->createToken('demo')->plainTextToken;

echo "TOKEN=" . $token . PHP_EOL;
echo "UID=" . $u->id . " PEER=" . $peer->id . PHP_EOL;
