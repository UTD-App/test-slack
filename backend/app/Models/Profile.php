<?php

namespace App\Models;

use App\Facades\Media;
use Illuminate\Database\Eloquent\Model;

class Profile extends Model
{
    protected $fillable = [
        'user_id',
        'avatar',
        'covers',
        'gender',
        'birthday',
        'province',
        'city',
        'country',
    ];

    protected $casts = [
        // Multi-image profile cover (swipeable banner). Stored as a JSON array
        // of raw storage paths / URLs; resolved to public URLs via `cover_images`.
        'covers' => 'array',
    ];

    // Expose `image` (avatar) and `cover_images` (covers) as full public URLs so
    // the Flutter clients render the stored paths without knowing the storage
    // driver. Already-absolute URLs pass through; relative paths go through the
    // Media seam.
    protected $appends = ['image', 'cover_images'];

    public function getImageAttribute(): ?string
    {
        return $this->resolveMediaUrl($this->attributes['avatar'] ?? null);
    }

    /**
     * Resolved, displayable URLs for every stored cover. Returns [] when none,
     * so clients can simply render the list (empty → no banner).
     *
     * @return array<int, string>
     */
    public function getCoverImagesAttribute(): array
    {
        $covers = $this->covers; // cast to array (or null)
        if (empty($covers) || ! is_array($covers)) {
            return [];
        }

        return array_values(array_filter(array_map(
            fn ($path) => $this->resolveMediaUrl(is_string($path) ? $path : null),
            $covers,
        )));
    }

    /** Absolute-URL passthrough; relative paths resolved via the Media seam. */
    protected function resolveMediaUrl(?string $path): ?string
    {
        if (empty($path)) {
            return null;
        }
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }
        return Media::url($path);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
