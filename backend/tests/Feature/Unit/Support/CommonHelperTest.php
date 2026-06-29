<?php

namespace Tests\Feature;

use App\Helpers\Common;
use App\Models\Config;
use App\Models\Setting;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Pagination\CursorPaginator;
use Illuminate\Pagination\LengthAwarePaginator;
use Illuminate\Pagination\Paginator;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class CommonHelperTest extends TestCase
{
    use \Illuminate\Foundation\Testing\RefreshDatabase;

    // ---- apiResponse envelope ---------------------------------------------

    public function test_api_response_envelope_shape(): void
    {
        $res = Common::apiResponse(true, 'ok', ['a' => 1], 201);

        $this->assertSame(201, $res->getStatusCode());
        $data = $res->getData(true);
        $this->assertSame(true, $data['status']);
        $this->assertSame('ok', $data['message']);
        $this->assertSame(['a' => 1], $data['data']);
        $this->assertArrayNotHasKey('meta', $data); // no paginator → no meta
    }

    public function test_api_response_casts_status_to_bool_and_defaults(): void
    {
        $res = Common::apiResponse(0);
        $data = $res->getData(true);

        $this->assertFalse($data['status']);
        $this->assertSame('', $data['message']);
        $this->assertNull($data['data']);
        $this->assertSame(200, $res->getStatusCode());
    }

    // ---- pagination meta ---------------------------------------------------

    public function test_explicit_length_aware_paginator_emits_full_meta(): void
    {
        $paginator = new LengthAwarePaginator(
            items: [['id' => 1], ['id' => 2]],
            total: 10,
            perPage: 2,
            currentPage: 1,
            options: ['path' => 'http://x/feed']
        );

        $res = Common::apiResponse(true, '', ['x'], 200, $paginator);
        $meta = $res->getData(true)['meta'];

        $this->assertSame(1, $meta['current_page']);
        $this->assertSame(2, $meta['per_page']);
        $this->assertSame(2, $meta['count']);
        $this->assertTrue($meta['has_more']);
        $this->assertSame(10, $meta['total']);       // length-aware only
        $this->assertSame(5, $meta['last_page']);    // length-aware only
        $this->assertNotNull($meta['next_page_url']);
        $this->assertNull($meta['prev_page_url']);
    }

    public function test_resource_collection_wrapping_paginator_auto_emits_meta(): void
    {
        $paginator = new LengthAwarePaginator(
            items: [['id' => 1]],
            total: 3,
            perPage: 1,
            currentPage: 2,
            options: ['path' => 'http://x/feed']
        );
        // AnonymousResourceCollection whose ->resource is the paginator.
        $collection = JsonResource::collection($paginator);
        $this->assertInstanceOf(AnonymousResourceCollection::class, $collection);

        $res = Common::apiResponse(true, '', $collection);
        $meta = $res->getData(true)['meta'];

        $this->assertSame(2, $meta['current_page']);
        $this->assertSame(3, $meta['total']);
        $this->assertTrue($meta['has_more']);
        $this->assertNotNull($meta['prev_page_url']);
    }

    public function test_simple_paginator_meta_has_no_total_or_last_page(): void
    {
        // Simple paginator: hasMorePages true when items > perPage requested+1.
        $paginator = new Paginator(
            items: [['id' => 1], ['id' => 2]],
            perPage: 1,
            currentPage: 1,
            options: ['path' => 'http://x/feed']
        );

        $res = Common::apiResponse(true, '', null, 200, $paginator);
        $meta = $res->getData(true)['meta'];

        $this->assertArrayNotHasKey('total', $meta);
        $this->assertArrayNotHasKey('last_page', $meta);
        $this->assertArrayHasKey('current_page', $meta);
        $this->assertArrayHasKey('has_more', $meta);
    }

    /**
     * FIXED: Common::paginationMeta() now branches on paginator type — it only
     * calls currentPage() for page-number paginators and emits next/prev cursor
     * for cursor paginators, so a cursor paginator no longer throws.
     *  Common::paginationMeta — Common.php
     */
    public function test_cursor_paginator_emits_cursor_meta_without_throwing(): void
    {
        $paginator = new CursorPaginator(
            items: [['id' => 1]],
            perPage: 1,
            options: ['path' => 'http://x/feed', 'parameters' => ['id']]
        );

        $res  = Common::apiResponse(true, '', null, 200, $paginator);
        $meta = $res->getData(true)['meta'];

        $this->assertArrayHasKey('per_page', $meta);
        $this->assertArrayHasKey('has_more', $meta);
        // cursor paginators expose a cursor, not a page number.
        $this->assertArrayNotHasKey('current_page', $meta);
        $this->assertArrayHasKey('next_cursor', $meta);
        $this->assertArrayHasKey('prev_cursor', $meta);
    }

    public function test_resource_collection_not_wrapping_paginator_has_no_meta(): void
    {
        // Plain collection (not a paginator) → no meta block.
        $collection = JsonResource::collection(new Collection([['id' => 1]]));

        $res = Common::apiResponse(true, '', $collection);
        $this->assertArrayNotHasKey('meta', $res->getData(true));
    }

    // ---- getSettingValue / getConf caching ---------------------------------

    public function test_get_setting_value_returns_default_when_missing(): void
    {
        $this->assertSame('fallback', Common::getSettingValue('nope', 'fallback'));
    }

    public function test_get_setting_value_reads_db_then_caches(): void
    {
        Setting::create(['key' => 'site', 'value' => 'Eagle']);
        $this->assertSame('Eagle', Common::getSettingValue('site'));

        // Mutate DB without clearing cache → cached value still served.
        Setting::where('key', 'site')->update(['value' => 'Changed']);
        $this->assertSame('Eagle', Common::getSettingValue('site'));

        // After cache forget → fresh read.
        Cache::forget('setting_site');
        $this->assertSame('Changed', Common::getSettingValue('site'));
    }

    public function test_get_conf_returns_default_when_missing(): void
    {
        $this->assertSame('def', Common::getConf('absent', 'def'));
    }

    public function test_get_conf_reads_db_then_caches(): void
    {
        Config::create(['name' => 'version', 'value' => '1.0']);
        $this->assertSame('1.0', Common::getConf('version'));

        Config::where('name', 'version')->update(['value' => '2.0']);
        $this->assertSame('1.0', Common::getConf('version')); // cached

        Cache::forget('config_version');
        $this->assertSame('2.0', Common::getConf('version'));
    }
}
