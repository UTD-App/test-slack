<?php

use Illuminate\Support\Facades\Route;
use Utd\Profile\Http\Controllers\ProfileController;

// Auto-loaded by BaseModuleServiceProvider under the /api prefix +
// ['api','localization'] middleware, only while the package is enabled.
Route::middleware([
    'auth:sanctum',
    'checkLatestToken',
    'generalBan',
    'userBan',
    'update.last.seen',
])->group(function () {
    Route::get('users/{id}/profile', [ProfileController::class, 'show']);
});
 