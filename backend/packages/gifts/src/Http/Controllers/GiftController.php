<?php

namespace Utd\Gifts\Http\Controllers;

use App\Contracts\GiftDirectory;
use App\Helpers\Common;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
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

    /** The user's gift history: ?type=sent|received (default received). */
    public function history(Request $request)
    {
        $userId = $request->user()->getKey();
        $type   = $request->string('type')->toString() === 'sent' ? 'sent' : 'received';
        $column = $type === 'sent' ? 'sender_id' : 'receiver_id';

        $logs = GiftLog::query()
            ->where($column, $userId)
            ->latest()
            ->paginate((int) $request->integer('per_page', 20))
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

        return Common::apiResponse(true, 'history', $logs);
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
}
