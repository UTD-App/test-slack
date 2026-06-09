<?php

namespace App\Helpers;

use App\Models\Setting;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;

class Common
{
    public static function apiResponse($status, $message = '', $data = null, $code = 200): JsonResponse
    {
        $response = [
            'status' => (bool) $status,
            'message' => $message,
            'data' => $data,
        ];

        return response()->json($response, $code);
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
