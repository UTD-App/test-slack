{{-- Gifts list (GiftResource) thumbnail: the gift's own artwork, SVGA included. --}}
@php
    $record = $getRecord();
@endphp

@include('gifts::filament.columns.gift-media', [
    'src'     => \Utd\Gifts\Support\Media::url($record->img),
    'type'    => $record->image_type,
    'caption' => null,
    'size'    => 48,
])
