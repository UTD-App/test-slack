<?php

namespace App\Http\Controllers\Api\V1;

use App\Facades\Media;
use App\Helpers\Common;
use App\Http\Controllers\Controller;
use Illuminate\Http\Request;

class MediaController extends Controller
{
    /**
     * Reusable, provider-agnostic media upload. Stores the file through the
     * Media seam (local now; switch to S3/GCS later purely via the admin
     * storage settings — no code change) and returns its canonical path +
     * public URL. Any feature uploads here, then sends the returned `path`
     * to its own endpoint (e.g. profile/update).
     */
    public function upload(Request $request)
    {
        $request->validate([
            'file'   => 'required|image|mimes:jpeg,jpg,png,webp,gif|max:5120',
            'folder' => 'nullable|string|regex:/^[a-z0-9_\-]+$/|max:40',
        ]);

        $result = Media::upload($request->file('file'), $request->input('folder', 'uploads'));

        return Common::apiResponse(true, 'Uploaded', [
            'path' => $result->path,
            'url'  => $result->url,
        ]);
    }
}
