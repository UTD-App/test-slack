<?php

namespace Utd\Moment\Http\Controllers;

use App\Contracts\GiftDirectory;
use App\Contracts\GiftSender;
use App\Contracts\NotificationSender;
use App\Helpers\Common;
use App\Models\User;
use App\Support\Notifications\NotificationMessage;
use Illuminate\Http\Request;
use Illuminate\Routing\Controller;
use Illuminate\Support\Facades\Auth;
use Utd\Moment\Entities\Moment;

/**
 * Sending gifts on a moment depends on the Gifts package + currency, which may
 * not be installed. Resolves the optional App\Contracts\GiftSender:
 *  - not bound  → 503 "gifts feature not installed" (graceful).
 *  - bound (Gifts installed) → gifting works automatically.
 */
class MomentUserGiftsController extends Controller
{
    public function store(Request $request, $moment_id)
    {
        if (! app()->bound(GiftSender::class)) {
            return Common::apiResponse(0, __('moment::messages.gifts_not_installed'), null, 503);
        }

        $moment = Moment::find($moment_id);
        if (! $moment) {
            return Common::apiResponse(0, __('moment::messages.not_found'), [], 404);
        }

        $sender = Auth::user();
        $receiver = User::find($moment->user_id);
        if (! $receiver) {
            return Common::apiResponse(0, __('moment::messages.user_not_found'), [], 404);
        }

        $result = app(GiftSender::class)->send(
            $sender,
            $receiver,
            (int) $request->input('gift_id'),
            (int) $request->input('num', 1),
            ['type' => 'moment', 'id' => $moment->id],
        );

        // Eagle parity: notify the moment owner that a gift landed on their moment.
        if ($result['success'] ?? false) {
            $this->notifyOwner($moment, $sender, $receiver);
        }

        return Common::apiResponse(
            $result['success'] ?? false,
            $result['message'] ?? '',
            $result['data'] ?? null,
            ($result['success'] ?? false) ? 200 : 402,
        );
    }

    /**
     * Notify the moment owner of a received gift via the Base NotificationSender
     * contract (best-effort; replaces Eagle's CustomNotification::sendMomentGift).
     */
    protected function notifyOwner(Moment $moment, $actor, User $owner): void
    {
        if ($owner->id === $actor->id || ! app()->bound(NotificationSender::class)) {
            return;
        }

        try {
            app(NotificationSender::class)->send(
                $owner,
                NotificationMessage::make(
                    $actor->name ?? __('moment::messages.someone'),
                    __('moment::messages.notify_gift'),
                    ['type' => 'moment', 'id' => (string) $moment->id],
                ),
            );
        } catch (\Throwable) {
            // best-effort
        }
    }

    /** Gifts received on a moment (grouped & summed) — served by the Gifts package. */
    public function getGifts($id)
    {
        if (! app()->bound(GiftDirectory::class)) {
            return Common::apiResponse(0, __('moment::messages.gifts_not_installed'), null, 503);
        }

        return Common::apiResponse(1, 'successful', app(GiftDirectory::class)->giftsFor('moment', (int) $id));
    }

    /** Who gifted on a moment — served by the Gifts package. */
    public function userGift($id)
    {
        if (! app()->bound(GiftDirectory::class)) {
            return Common::apiResponse(0, __('moment::messages.gifts_not_installed'), null, 503);
        }

        return Common::apiResponse(1, 'successful', app(GiftDirectory::class)->giftersFor('moment', (int) $id));
    }
}
