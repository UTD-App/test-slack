<?php

namespace Utd\Reels\Http\Controllers;

use App\Contracts\GiftSender;
use App\Facades\Notifier;
use App\Helpers\Common;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Reels\Entities\Real;

/**
 * Sending gifts on a reel depends on the Gifts package + currency, which may not
 * be installed. Resolves the optional App\Contracts\GiftSender:
 *  - not bound  → 503 "gifts feature not installed" (graceful).
 *  - bound (Gifts installed) → gifting works automatically.
 */
class ReelGiftsController extends Controller
{
    public function store(Request $request, $real_id)
    {
        if (! app()->bound(GiftSender::class)) {
            return Common::apiResponse(0, __('reels::messages.gifts_not_installed'), null, 503);
        }

        $real = Real::find($real_id);
        if (! $real) {
            return Common::apiResponse(0, __('reels::messages.not_found'), [], 402);
        }

        $sender = Auth::user();
        $receiver = User::find($real->user_id);
        if (! $receiver) {
            return Common::apiResponse(0, __('reels::messages.user_not_found'), [], 402);
        }

        $result = app(GiftSender::class)->send(
            $sender,
            $receiver,
            (int) $request->input('gift_id'),
            (int) $request->input('num', 1),
            ['type' => 'reel', 'id' => $real->id],
        );

        // Notify the reel owner they received a gift (only on a successful send,
        // and never self-gifts). Mirrors the like/comment notify path.
        if (($result['success'] ?? false) && $receiver->id !== $sender->id) {
            $this->notifyOwner($real, $receiver, $sender);
        }

        return Common::apiResponse(
            $result['success'] ?? false,
            $result['message'] ?? '',
            $result['data'] ?? null,
            ($result['success'] ?? false) ? 200 : 402,
        );
    }

    /**
     * Notify the reel owner via the high-level Notifier (in-app feed + push +
     * recipient-locale text + preferences). No-op if the notification system
     * isn't installed.
     */
    protected function notifyOwner(Real $real, User $owner, User $actor): void
    {
        if (! app()->bound('utd.notifier')) {
            return;
        }

        Notifier::send(
            $owner,
            'reels.gift',
            params: ['name' => $actor->name ?? __('reels::messages.someone')],
            data: ['reel_id' => $real->id],
            actor: $actor,
        );
    }
}
