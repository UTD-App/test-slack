<?php

use App\Models\Agency;
use App\Models\User;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\DB;

/*
|--------------------------------------------------------------------------
| Console Routes
|--------------------------------------------------------------------------
|
| This file is where you may define all of your Closure based console
| commands. Each Closure is bound to a command instance allowing a
| simple approach to interacting with each command's IO methods.
|
*/

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command ('monthly_update',function (){
    Agency::query ()->update (
        [
            'old_usd' => DB::raw('old_usd + target_usd - target_token_usd'),
            'target_usd' => 0,
            'target_token_usd' => 0
        ]
    );
    User::query ()->update (
        [
            'old_usd' => DB::raw('old_usd + target_usd - target_token_usd'),
            'target_usd' => 0,
            'target_token_usd' => 0,
            'coins'=>0
        ]
    );
    $this->comment('updated');
})->purpose ('update data every month');




