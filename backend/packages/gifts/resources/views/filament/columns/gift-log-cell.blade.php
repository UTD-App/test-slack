{{-- Gift log "gift" cell: the gift's artwork (SVGA included) with its name below.
     Falls back to the denormalized gift_name when the gift row is gone. --}}
@php
    $record = $getRecord();
    $gift   = $record->gift;
    $name   = $record->gift_name ?: ($gift->name ?? '—');
@endphp

@include('gifts::filament.columns.gift-media', [
    'src'     => $gift ? \Utd\Gifts\Support\Media::url($gift->img) : null,
    'type'    => $gift?->image_type,
    'caption' => $name,
    'size'    => 44,
])
