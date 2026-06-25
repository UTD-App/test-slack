{{-- Level badge icon for the admin table. Resolves the stored icon to a
     HOST-RELATIVE url (so it loads on the dashboard regardless of the public-disk
     host, e.g. the emulator's 10.0.2.2) and renders it via the shared gift-media
     renderer so .svga level badges animate too. --}}
@php
    use Illuminate\Support\Facades\Storage;
    use Illuminate\Support\Str;

    $record = $getRecord();
    $raw = (string) ($record->img ?? '');

    $src = null;
    if ($raw !== '') {
        if (Str::startsWith($raw, ['http://', 'https://'])) {
            $src = $raw;
        } else {
            $abs  = Storage::disk('public')->url(ltrim($raw, '/'));
            $path = parse_url($abs, PHP_URL_PATH);
            $src  = $path ?: $abs;
        }
    }

    // Infer the media kind from the file extension (no image_type column on levels).
    $ext = strtolower((string) pathinfo((string) (parse_url($raw, PHP_URL_PATH) ?: $raw), PATHINFO_EXTENSION));
@endphp

@include('gifts::filament.columns.gift-media', [
    'src'     => $src,
    'type'    => $ext,
    'caption' => null,
    'size'    => 40,
])
