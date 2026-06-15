<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\Page;

class PageController extends Controller
{
    /**
     * Public static content page by key (privacy-policy, about-us, …).
     * Returns localized title/body ({en, ar}); the app picks the locale.
     */
    public function show(string $key)
    {
        $page = Page::where('key', $key)->first();

        if (! $page) {
            return Common::apiResponse(false, 'Page not found', null, 404);
        }

        return Common::apiResponse(true, '', [
            'key'   => $page->key,
            'title' => $page->title,
            'body'  => $page->body,
        ]);
    }
}
