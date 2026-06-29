<?php

namespace App\Http\Controllers\Api\V1;

use App\Helpers\Common;
use App\Http\Controllers\Controller;
use App\Models\Page;

class PageController extends Controller
{
    /**
     * Public static content page by key (privacy-policy, about-us, …).
     *
     * Title/body are resolved to the request's current locale (set from the
     * X-localization header by the `localization` middleware), falling back to
     * the default language when a translation is missing — so the app just shows
     * `data.title` / `data.body` as plain strings.
     */
    public function show(string $key)
    {
        $page = Page::where('key', $key)->first();

        if (! $page) {
            return Common::apiResponse(false, __('messages.page_not_found'), null, 404);
        }

        return Common::apiResponse(true, '', [
            'key'    => $page->key,
            'title'  => $page->tr('title'),
            'body'   => $page->tr('body'),
            'locale' => app()->getLocale(),
        ]);
    }
}
