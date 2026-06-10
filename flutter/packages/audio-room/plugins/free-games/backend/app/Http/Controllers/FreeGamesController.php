<?php

namespace App\Http\Controllers;

use App\Helpers\Common;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class FreeGamesController extends Controller
{
    public function images()
    {
        $data = Cache::remember('free_games_images', 300, function () {
            $dice = DB::table('gifts')->where('name', 'dice')->first();
            $rps = DB::table('gifts')->where('name', 'rps')->first();
            $giftBox = DB::table('gifts')->where('name', 'gift_box')->first();

            return [
                'dice' => [
                    'id' => $dice->id ?? 0,
                    'image' => $dice->image ?? '',
                ],
                'rps' => [
                    'id' => $rps->id ?? 0,
                    'image' => $rps->image ?? '',
                ],
                'gift_box' => [
                    'id' => $giftBox->id ?? 0,
                    'image' => $giftBox->image ?? '',
                ],
            ];
        });

        return Common::apiResponse(1, '', $data);
    }
}
