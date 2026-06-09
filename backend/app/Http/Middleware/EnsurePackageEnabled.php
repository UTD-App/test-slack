<?php

namespace App\Http\Middleware;

use App\Helpers\Common;
use App\Services\PackageRegistry;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Blocks a package's API routes while that package is disabled in admin/packages.
 *
 * General-purpose: any package guards its route group with the slug it
 * registered, e.g.
 *   Route::middleware(['auth:sanctum', 'package.enabled:moment'])->group(...)
 *
 * A disabled package returns 403 instead of running its controllers.
 */
class EnsurePackageEnabled
{
    public function __construct(private PackageRegistry $packages) {}

    public function handle(Request $request, Closure $next, string $slug): Response
    {
        if (! $this->packages->isEnabled($slug)) {
            return Common::apiResponse(0, __('packages.disabled'), null, 403);
        }

        return $next($request);
    }
}
