{{--
  One reel card in the user-profile "Reels" grid. Small inline video player
  (preload="metadata" → only the first frame is fetched) + description + counts.
  Inline styles only — Filament purges Tailwind for package blades.
--}}
@php
    $reel = $getRecord();
    $src  = \Utd\Reels\Filament\Resources\UserResource\RelationManagers\UserReelsRelationManager::mediaUrl($reel->url);
    $desc = trim((string) ($reel->description ?? ''));
@endphp

<div style="border:1px solid rgba(0,0,0,.08);border-radius:.9rem;overflow:hidden;background:#fff;
            box-shadow:0 2px 8px rgba(0,0,0,.06);height:100%;display:flex;flex-direction:column;">
    <div style="background:#000;display:flex;align-items:center;justify-content:center;height:220px;">
        @if ($src)
            <video src="{{ $src }}" controls preload="metadata" playsinline
                   style="max-height:100%;max-width:100%;object-fit:contain;"></video>
        @else
            <div style="color:#94a3b8;font-size:.8rem;">🎬</div>
        @endif
    </div>

    <div style="padding:.7rem .8rem;display:flex;flex-direction:column;gap:.45rem;flex:1;">
        @if ($desc !== '')
            <div style="font-size:.82rem;color:#334155;line-height:1.35;display:-webkit-box;
                        -webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden;">{{ $desc }}</div>
        @endif

        <div style="margin-top:auto;display:flex;align-items:center;gap:.85rem;flex-wrap:wrap;
                    font-size:.76rem;color:#64748b;">
            <span title="{{ __('reels::admin.views') }}">👁 {{ number_format((int) ($reel->view_num ?? 0)) }}</span>
            <span title="{{ __('reels::admin.likes') }}">❤ {{ number_format((int) ($reel->like_num ?? 0)) }}</span>
            <span title="{{ __('reels::admin.comments') }}">💬 {{ number_format((int) ($reel->comment_num ?? 0)) }}</span>
            <span style="margin-inline-start:auto;color:#94a3b8;">{{ optional($reel->created_at)?->format('Y-m-d') }}</span>
        </div>
    </div>
</div>
