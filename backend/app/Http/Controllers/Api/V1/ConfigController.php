<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\Config;

class ConfigController extends Controller
{
    public function index()
    {
        $configs = Config::where('is_hidden', false)->get(['name', 'value']);

        return Common::apiResponse(true, 'configs', $configs);
    }
}
