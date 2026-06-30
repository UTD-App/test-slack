<?php

namespace Utd\Gifts\Http\Controllers;

use App\Contracts\GiftDirectory;
use App\Contracts\GiftSender;
use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Utd\Gifts\Models\GiftLog;
use Utd\Gifts\Services\GiftCatalogService;

class GiftController extends Controller
{
    public function __construct(private readonly GiftCatalogService $catalog)
    {
    }

    /** Gift categories (ordered, localized title). */
    public function categories()
    {
        return Common::apiResponse(true, 'categories', $this->catalog->categories());
    }

    /** Enabled gifts, optionally filtered by ?category_id=. */
    public function index(Request $request)
    {
        $categoryId = $request->filled('category_id') ? (int) $request->input('category_id') : null;

        return Common::apiResponse(true, 'gifts', $this->catalog->giftsByCategory($categoryId));
    }

    /**
     * Eagle parity (GET /gifts/v2?type=): `type` is the category id, with the
     * special value -1 meaning the user's backpack. Returns the same gift shape.
     */
    public function indexV2(Request $request)
    {
        $type = $request->filled('type') ? (int) $request->input('type') : null;

        if ($type === -1) {
            return Common::apiResponse(true, 'gifts', $this->catalog->backpackGifts($request->user()));
        }

        return Common::apiResponse(true, 'gifts', $this->catalog->giftsByCategory($type));
    }

    /** Flat list of enabled gift image URLs (Eagle's GET /gifts/images). */
    public function images()
    {
        return Common::apiResponse(true, 'images', $this->catalog->images());
    }

    /** Minimal gift lookup by ?id= (Eagle's GET /gifts-by-id); {} when missing. */
    public function byId(Request $request)
    {
        $gift = $this->catalog->byId((int) $request->integer('id'));

        return Common::apiResponse(true, '', $gift ?? new \stdClass());
    }

    /** Enabled gifts the user can afford, paginated (Eagle's GET /user-gifts). */
    public function userGifts(Request $request)
    {
        $user = $request->user();
        $this->catalog->markGiftsSeen($user);

        $gifts = $this->catalog->affordableGifts($user);

        return Common::apiResponse(true, 'gifts', $gifts->items(), 200, $gifts);
    }

    /** The user's gift history: ?type=sent|received (default received). */
    public function history(Request $request)
    {
        $userId = $request->user()->getKey();
        $type   = $request->string('type')->toString() === 'sent' ? 'sent' : 'received';
        $column = $type === 'sent' ? 'sender_id' : 'receiver_id';

        // Clamp page size to a sane range so a caller can't request millions of
        // rows in one page (matches WalletController::transactions).
        $perPage = min(max((int) $request->integer('per_page', 20), 1), 100);

        $logs = GiftLog::query()
            ->where($column, $userId)
            ->latest()
            ->paginate($perPage)
            ->through(fn (GiftLog $log) => [
                'id'           => $log->id,
                'gift_id'      => $log->gift_id,
                'gift_name'    => $log->gift_name,
                'gift_num'     => $log->gift_num,
                'total_price'  => (float) $log->total_price,
                'earned'       => (float) $log->receiver_earned,
                'direction'    => $type,
                'context_type' => $log->context_type,
                'context_id'   => $log->context_id,
                'created_at'   => optional($log->created_at)->toIso8601String(),
            ]);

        return Common::apiResponse(true, 'history', $logs->items(), 200, $logs);
    }

    /** Gifts received in a context (e.g. a moment): grouped & summed. */
    public function contextGifts(GiftDirectory $directory, string $type, int $id)
    {
        return Common::apiResponse(true, 'context_gifts', $directory->giftsFor($type, $id));
    }

    /** Who gifted in a context. */
    public function contextGifters(GiftDirectory $directory, string $type, int $id)
    {
        return Common::apiResponse(true, 'context_gifters', $directory->giftersFor($type, $id));
    }

    /** Who received the most gifts in a context. */
    public function contextReceivers(GiftDirectory $directory, string $type, int $id)
    {
        return Common::apiResponse(true, 'context_receivers', $directory->receiversFor($type, $id));
    }

    /**
     * Gifts RECEIVED by a user, grouped & summed (Eagle's GET /my_gifts?user_id=).
     * Defaults to the authenticated user; 404 for an unknown explicit user_id.
     */
    public function myGifts(Request $request, GiftDirectory $directory)
    {
        $userId = $request->filled('user_id')
            ? (int) $request->input('user_id')
            : $request->user()->getKey();

        if ($request->filled('user_id') && ! User::whereKey($userId)->exists()) {
            return Common::apiResponse(false, __('gifts::messages.user_not_found'), null, 404);
        }

        return Common::apiResponse(true, 'my_gifts', $directory->receivedBy($userId));
    }

    /**
     * Send a gift to one or many receivers (Eagle's POST /gifts/send → gift_queue_cp).
     * Thin wrapper over the GiftSender contract: parses the comma-separated `toUid`,
     * loads the receivers, and delegates the money/log/event flow to sendMany().
     *
     * Room-specific effects (room-owner / host / agency split, room.session, PK,
     * family, room boom, banner >= threshold, zego) are layered by listeners of
     * App\Events\Gifts\GiftSent in the feature packages (Room/Family/Agency) — the
     * context carries room_id/roomowner_id for them. Not done here.
     */
    public function send(Request $request)
    {
        if (! app()->bound(GiftSender::class)) {
            return Common::apiResponse(false, __('gifts::messages.wallet_required'), null, 503);
        }

        $validator = Validator::make($request->all(), [
            'id'              => 'required|integer',
            'toUid'           => 'required|string',
            'num'             => 'required|integer|min:1',
            'type'            => 'nullable|string',
            'owner_id'        => 'nullable|integer',
            'room_id'         => 'nullable|integer',
            // Per-tap UUID from the client so a retry / double-tap does not
            // charge the sender (or credit receivers) twice. Optional for old
            // clients, but the app should always send one.
            'idempotency_key' => 'nullable|string|max:64',
        ]);

        if ($validator->fails()) {
            return Common::apiResponse(false, $validator->errors()->first(), $validator->errors(), 422);
        }

        $receiverIds = collect(explode(',', (string) $request->input('toUid')))
            ->map(fn ($v) => (int) trim($v))
            ->filter()
            ->unique()
            ->values();

        $receivers = User::query()->whereIn('id', $receiverIds)->get();
        if ($receivers->isEmpty()) {
            return Common::apiResponse(false, __('gifts::messages.no_receivers'), null, 422);
        }

        $context = array_filter([
            'type'            => 'room',
            'id'              => $request->integer('room_id') ?: null,
            'room_id'         => $request->integer('room_id') ?: null,
            'roomowner_id'    => $request->integer('owner_id') ?: null,
            'source'          => $request->input('type') === 'bag' ? 'bag' : 'coins',
            'idempotency_key' => $request->filled('idempotency_key')
                ? (string) $request->input('idempotency_key')
                : null,
        ], fn ($v) => $v !== null);

        $result = app(GiftSender::class)->sendMany(
            $request->user(),
            $receivers->all(),
            (int) $request->input('id'),
            (int) $request->input('num'),
            $context,
        );

        $ok   = (bool) ($result['success'] ?? false);
        $data = (array) ($result['data'] ?? []);

        return Common::apiResponse(
            $ok,
            $result['message'] ?? '',
            $ok ? [
                // receiver_ids (normal) / receivers_ids (lucky resolver) / requested ids.
                'ids'      => $data['receiver_ids'] ?? $data['receivers_ids'] ?? $receiverIds->all(),
                'batch_id' => $data['batch_id'] ?? null,
                'total'    => $data['total'] ?? 0,
            ] : null,
            $ok ? 200 : 422,
        );
    }
}
