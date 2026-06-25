{{--
  One moment card in the user-profile "Moments" grid. Small media thumbnail
  (single `img` or the first gallery image) + caption + engagement counts.
  Inline styles only — Filament purges Tailwind for package blades.
--}}
@php
    $moment = $getRecord();
    $rm     = \Utd\Moment\Filament\Resources\UserResource\RelationManagers\UserMomentsRelationManager::class;
    $raw    = $moment->img ?: optional($moment->images->first())->image;
    $src    = $rm::mediaUrl($raw);
    $more   = max(0, ($moment->images?->count() ?? 0) - ($moment->img ? 0 : 1));
    $desc   = trim((string) ($moment->description ?? ''));
@endphp

<div style="border:1px solid rgba(0,0,0,.08);border-radius:.9rem;overflow:hidden;background:#fff;
            box-shadow:0 2px 8px rgba(0,0,0,.06);height:100%;display:flex;flex-direction:column;">
    @if ($src)
        <div style="position:relative;background:#0f172a;height:200px;display:flex;align-items:center;justify-content:center;">
            <img src="{{ $src }}" alt="" loading="lazy"
                 style="width:100%;height:100%;object-fit:cover;display:block;">
            @if ($more > 0)
                <span style="position:absolute;top:.5rem;inset-inline-end:.5rem;background:rgba(0,0,0,.6);color:#fff;
                             font-size:.72rem;padding:.15rem .5rem;border-radius:999px;">+{{ $more }}</span>
            @endif
        </div>
    @else
        <div style="background:linear-gradient(135deg,#1e293b,#334155);color:#e2e8f0;height:200px;
                    display:flex;align-items:center;justify-content:center;padding:1rem;text-align:center;">
            <div style="font-size:.9rem;line-height:1.45;display:-webkit-box;-webkit-line-clamp:4;
                        -webkit-box-orient:vertical;overflow:hidden;">{{ $desc !== '' ? $desc : '📝' }}</div>
        </div>
    @endif

    <div style="padding:.7rem .8rem;display:flex;flex-direction:column;gap:.45rem;flex:1;">
        @if ($src && $desc !== '')
            <div style="font-size:.82rem;color:#334155;line-height:1.35;display:-webkit-box;
                        -webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;">{{ $desc }}</div>
        @endif

        <div style="margin-top:auto;display:flex;align-items:center;gap:.85rem;flex-wrap:wrap;
                    font-size:.76rem;color:#64748b;">
            <span title="{{ __('moment::admin.likes') }}">❤ {{ number_format((int) ($moment->like_num ?? 0)) }}</span>
            <span title="{{ __('moment::admin.comments') }}">💬 {{ number_format((int) ($moment->comment_num ?? 0)) }}</span>
            <span style="margin-inline-start:auto;color:#94a3b8;">{{ optional($moment->created_at)?->format('Y-m-d') }}</span>
        </div>
    </div>
</div>
