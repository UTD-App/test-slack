<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    /**
     * The URIs that should be excluded from CSRF verification.
     *
     * @var array<int, string>
     */
    protected $except = [
        'update-room-count',
        '__debugbar/screen',
        'admin/_handle_action_',
        'superadmin/_handle_action_',
        'areaManager/_handle_action_',
        'agency/_handle_action_',
    ];
}
