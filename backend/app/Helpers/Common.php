<?php

namespace App\Helpers;

use App\Models\Setting;
use Illuminate\Contracts\Pagination\LengthAwarePaginator as LengthAwarePaginatorContract;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\ResourceCollection;
use Illuminate\Pagination\AbstractCursorPaginator;
use Illuminate\Pagination\AbstractPaginator;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;

class Common
{
    /**
     * Standard API envelope. When the data is paginated, emit pagination `meta`
     * so feeds (rooms, moments, reels) can do correct infinite scroll instead of
     * collapsing to a bare array. The paginator is taken from either the explicit
     * 5th arg or a resource collection wrapping a paginator; passing it is
     * purely additive — `data` keeps its existing shape.
     */
    public static function apiResponse($status, $message = '', $data = null, $code = 200, $paginator = null): JsonResponse
    {
        if ($paginator === null
            && $data instanceof ResourceCollection
            && ($data->resource instanceof AbstractPaginator || $data->resource instanceof AbstractCursorPaginator)) {
            $paginator = $data->resource;
        }

        $response = [
            'status' => (bool) $status,
            'message' => $message,
            'data' => $data,
        ];

        if ($paginator instanceof AbstractPaginator || $paginator instanceof AbstractCursorPaginator) {
            $response['meta'] = self::paginationMeta($paginator);
        }

        return response()->json($response, $code);
    }

    /** Build a compact, client-friendly pagination meta block. */
    private static function paginationMeta($paginator): array
    {
        $meta = [
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'count' => count($paginator->items()),
            'has_more' => $paginator->hasMorePages(),
            'next_page_url' => $paginator->nextPageUrl(),
            'prev_page_url' => $paginator->previousPageUrl(),
        ];

        // total/last_page exist only on length-aware paginators (not simple/cursor).
        if ($paginator instanceof LengthAwarePaginatorContract) {
            $meta['total'] = $paginator->total();
            $meta['last_page'] = $paginator->lastPage();
        }

        return $meta;
    }

    public static function getSettingValue($key, $default = null)
    {
        return Cache::remember("setting_{$key}", 3600, function () use ($key, $default) {
            return Setting::where('key', $key)->value('value') ?? $default;
        });
    }

    public static function getConf($key, $default = null)
    {
        return Cache::remember("config_{$key}", 3600, function () use ($key, $default) {
            return \App\Models\Config::where('name', $key)->value('value') ?? $default;
        });
    }

    public static function uploadProfileUser($folder, $file, $profileId, $count): string
    {
        $extension = $file->getClientOriginalExtension() ?: 'jpg';
        $fileName = "{$profileId}_{$count}.{$extension}";
        $path = "{$folder}/{$fileName}";

        Storage::put($path, file_get_contents($file), config('filesystems.default'));

        return $path;
    }
}
