<?php

namespace App\Http\Controllers\Api\V1\Auth;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\Country;

class RegisterController extends Controller
{
    public function countries()
    {
        $data = Country::select('id', 'name', 'e_name', 'flag')->get();
        return Common::apiResponse(true, '', $data);
    }
}
