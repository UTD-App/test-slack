@php
    /** @var \Utd\Moment\Entities\ReportMoment $record */
    $record = $getRecord();
    $moment = $record->moment;
    $text = $moment?->description;
    $imgPath = optional($moment?->images?->first())->image ?: $moment?->img;
    $img = \Utd\Moment\Filament\Resources\ReportMomentResource::resolveImageUrl($imgPath);
    $deleted = __('moment::admin.deleted_moment');
@endphp

<div class="flex items-center gap-3" style="max-width:280px;">
    @if ($img)
        <img
            src="{{ $img }}"
            alt=""
            loading="lazy"
            class="shrink-0 object-cover ring-1 ring-gray-950/10 dark:ring-white/20"
            style="width:44px;height:44px;border-radius:8px;"
        />
    @else
        <div
            class="shrink-0 flex items-center text-gray-400"
            style="width:44px;height:44px;border-radius:8px;background:rgba(156,163,175,0.2);justify-content:center;"
        >
            @svg('heroicon-o-photo', 'h-5 w-5')
        </div>
    @endif

    <div class="min-w-0 leading-tight">
        <div
            class="text-sm text-gray-950 dark:text-white"
            style="display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;"
        >
            {{ $text ?: $deleted }}
        </div>
        <div class="text-xs text-gray-400 font-mono" style="margin-top:2px;">#{{ $record->moment_id }}</div>
    </div>
</div>
