<?php

namespace App\Http\Controllers\Api\V1;

use App\Contracts\WalletContract;
use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\TranslationKey;
use Illuminate\Http\Request;

class PackageController extends Controller
{
    // GET /api/packages/installed
    // Returns list of installed packages — UTD Studio reads this
    // to know which screens to show the client
    public function installed(): \Illuminate\Http\JsonResponse
    {
        $packages = \App\Models\TranslationKey::distinct()
            ->whereNotIn('group', ['app', 'admin', 'auth', 'dashboard', 'messages', 'api', 'validation'])
            ->pluck('group')
            ->values();

        $installedPackages = array_merge(['base'], $packages->toArray());

        return Common::apiResponse(true, '', [
            'packages'     => $installedPackages,
            'server'       => config('app.url'),
            // Runtime capabilities the client uses to gate features that depend on
            // a package that may not be installed. `wallet` is false until a real
            // Wallet package binds WalletContract (NullWallet => false), so host
            // features (Moment, Reels…) hide their gift button while it's absent.
            'capabilities' => [
                'wallet' => app(WalletContract::class)->isAvailable(),
            ],
        ]);
    }

    // POST /api/packages/register
    // Called when a package is installed to register its translation keys
    // Body: { "package": "audio-room", "version": "1.0.0", "keys": [{"key": "audio_room.room_title", "group": "audio-room"}] }
    public function register(Request $request): \Illuminate\Http\JsonResponse
    {
        $request->validate([
            'package' => 'required|string',
            'version' => 'required|string',
            'keys'    => 'array',
            'keys.*.key'   => 'required|string',
            'keys.*.group' => 'required|string',
        ]);

        $registered = 0;

        foreach ($request->input('keys', []) as $item) {
            TranslationKey::firstOrCreate(
                ['key' => $item['key']],
                ['group' => $item['group']]
            );
            $registered++;
        }

        return Common::apiResponse(true, "Package '{$request->package}' registered. {$registered} keys added.", [
            'package'    => $request->package,
            'version'    => $request->version,
            'keys_added' => $registered,
        ]);
    }
}
