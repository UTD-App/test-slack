<?php

namespace App\Http\Controllers;

use App\Helpers\Common;
use App\Models\Emoji;
use App\Models\EmojiCategory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class EmojiController extends Controller
{
    public function categories(): JsonResponse
    {
        $categories = Cache::remember('emoji_categories', 300, function () {
            return EmojiCategory::orderBy('sort')->get();
        });

        return Common::apiResponse(true, '', $categories);
    }

    public function index(Request $request): JsonResponse
    {
        $query = Emoji::enabled()->orderBy('sort');

        if ($request->filled('category_id')) {
            $query->where('emoji_category_id', $request->category_id);
        }

        $emojis = $query->get();

        return Common::apiResponse(true, '', $emojis);
    }

    public function show(int $id): JsonResponse
    {
        $emoji = Emoji::find($id);

        if (!$emoji) {
            return Common::apiResponse(false, 'Emoji not found', null, 404);
        }

        return Common::apiResponse(true, '', $emoji);
    }
}
