<x-filament-panels::page>
    @php($uploader = app(\App\Contracts\MediaUploader::class))
    @php($avatarUrl = function ($u) {
        $name = $u?->name ?: __('reels::admin.user');
        return ($u?->avatar && \Illuminate\Support\Str::startsWith($u->avatar, 'http'))
            ? $u->avatar
            : 'https://ui-avatars.com/api/?name=' . urlencode($name) . '&background=4f46e5&color=fff';
    })
    {{-- Resolve a stored path to a URL. External (http) URLs pass through; local
         storage URLs are made scheme-relative so they match the page scheme
         (http dev server / https prod) and never become blocked mixed-content. --}}
    @php($mediaUrl = function ($path) use ($uploader) {
        if (! $path) return '';
        if (\Illuminate\Support\Str::startsWith($path, 'http')) return $path;
        try { $url = $uploader->url($path); } catch (\Throwable $e) { return ''; }
        return preg_replace('#^https?:#i', '', $url);
    })
    @php($frameUrl = function ($reel) use ($mediaUrl) {
        $p = (config('app.env') != 'production' ? '' : 'test-') . 'frames/' . $reel->id . '.jpg';
        return $mediaUrl($p);
    })
    @php($fmt = function ($n) {
        if ($n >= 1000000) return round($n / 1000000, 1) . 'M';
        if ($n >= 1000) return round($n / 1000, 1) . 'K';
        return (string) $n;
    })

    {{-- Geometry is set with INLINE STYLES on purpose: Filament ships a fixed,
         pre-compiled CSS, so arbitrary Tailwind utilities (h-[80vh], max-w-[430px],
         bg-white/15, backdrop-blur, …) used in a package blade generate no rule and
         the stage would collapse to zero height (blank page). Inline styles always
         apply, independent of any Tailwind build. --}}
    @php($railBtn = 'display:flex;flex-direction:column;align-items:center;gap:4px;color:#fff;background:none;border:0;cursor:pointer;')
    {{-- dark (not white-transparent) so the white icons stay visible on light video frames too --}}
    @php($railIcon = 'display:flex;height:44px;width:44px;align-items:center;justify-content:center;border-radius:9999px;background:rgba(0,0,0,.45);')

    {{-- ===================== username filter ===================== --}}
    {{-- Geometry inline; colours use the same standard utilities the nav arrows use
         (those compile in Filament's CSS), so the input themes in light/dark without
         disturbing the centred stage layout. --}}
    <div style="display:flex;justify-content:center;padding-bottom:10px;">
        <div style="position:relative;width:100%;max-width:430px;">
            <span style="position:absolute;inset-inline-start:12px;top:50%;transform:translateY(-50%);pointer-events:none;display:flex;color:#9ca3af;">
                <svg style="height:18px;width:18px;" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m21 21-4.34-4.34m0 0A8 8 0 1 0 5.34 5.34a8 8 0 0 0 11.32 11.32Z"/></svg>
            </span>
            <input type="text" wire:model.live.debounce.400ms="search"
                   placeholder="{{ __('reels::admin.filter_by_user') }}"
                   class="bg-white text-gray-900 ring-1 ring-gray-950/10 placeholder:text-gray-400 dark:bg-gray-800 dark:text-gray-100 dark:ring-white/10"
                   style="width:100%;border:0;outline:none;border-radius:9999px;padding:9px 38px;font-size:14px;">
            @if (filled($this->search))
                <button type="button" wire:click="$set('search', '')" title="{{ __('reels::admin.clear') }}"
                        style="position:absolute;inset-inline-end:10px;top:50%;transform:translateY(-50%);display:flex;height:22px;width:22px;align-items:center;justify-content:center;border-radius:9999px;border:0;cursor:pointer;background:rgba(0,0,0,.08);color:#6b7280;">
                    <svg style="height:14px;width:14px;" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12"/></svg>
                </button>
            @endif
        </div>
    </div>

    @php($reel = $this->current)

    @if (! $reel)
        <div style="max-width:28rem;margin-inline:auto;padding:5rem 0;text-align:center;font-size:.875rem;color:#9ca3af;border-radius:1rem;background:#fff;box-shadow:0 0 0 1px rgba(0,0,0,.05);">
            {{ filled($this->search) ? __('reels::admin.no_match') : __('reels::admin.empty') }}
        </div>
    @else
        @php($user = $reel->user)
        @php($name = $user?->name ?: __('reels::admin.user'))
        @php($src = $mediaUrl($reel->url))
        @php($poster = $frameUrl($reel))
        {{-- Neighbour URLs — preloaded (hidden) so scrolling to the next/prev reel is instant. --}}
        @php($_reels = $this->reels())
        @php($nextSrc = isset($_reels[$this->index + 1]) ? $mediaUrl($_reels[$this->index + 1]->url) : null)
        @php($prevSrc = ($this->index > 0 && isset($_reels[$this->index - 1])) ? $mediaUrl($_reels[$this->index - 1]->url) : null)

        {{-- Wheel over the stage changes reels, ONE at a time (FB/YT style): the
             move fires on the first wheel, then `lock` is held until wheel events
             stop for 450ms — so a single scroll gesture = a single move.
             `soundOn` (default ON) is the persistent sound preference; `onAir` is the
             current video's real muted state (drives the button icon). Both live on
             this wrapper (no wire:key) so they survive the Livewire re-render. --}}
        <div x-data="{ soundOn: true, onAir: false, lock: false, t: null, progress: 0, paused: false }"
             @wheel.prevent="clearTimeout(t); if (! lock) { lock = true; ($event.deltaY > 0 ? $wire.next() : $wire.prev()) } t = setTimeout(() => { lock = false }, 450)"
             style="display:flex;align-items:center;justify-content:center;gap:12px;padding:8px 0;">
            {{-- ===================== STAGE (single reel) ===================== --}}
            <div wire:key="reel-{{ $reel->id }}"
                 style="position:relative;height:80vh;width:100%;max-width:430px;margin-inline:auto;overflow:hidden;border-radius:1rem;background:#000;box-shadow:0 25px 50px -12px rgba(0,0,0,.5);">

                {{-- Always autoplaying + looping. We try to play WITH sound (soundOn);
                     if the browser blocks unmuted autoplay (no gesture yet) we fall back
                     to muted so it still plays, and the next reel (after any scroll/click)
                     comes through with sound. The button below toggles + persists sound. --}}
                <video x-ref="v" src="{{ $src }}"
                       @if ($poster) poster="{{ $poster }}" @endif
                       x-init="progress = 0; $nextTick(() => { const allow = soundOn && navigator.userActivation && navigator.userActivation.hasBeenActive; $el.muted = ! allow; $el.play()?.catch(() => { $el.muted = true; $el.play()?.catch(() => {}); }); })"
                       @click="$el.paused ? $el.play()?.catch(() => {}) : $el.pause()"
                       @play="paused = false"
                       @pause="paused = true"
                       @volumechange="onAir = ! $el.muted"
                       @timeupdate="progress = $el.duration ? ($el.currentTime / $el.duration * 100) : 0"
                       autoplay loop muted playsinline preload="auto"
                       style="position:absolute;inset:0;height:100%;width:100%;background:#000;object-fit:contain;cursor:pointer;"></video>

                {{-- big play icon shown while paused (click passes through to the video to resume) --}}
                <div x-show="paused" x-cloak style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;pointer-events:none;z-index:15;">
                    <span style="display:flex;height:64px;width:64px;align-items:center;justify-content:center;border-radius:9999px;background:rgba(0,0,0,.5);color:#fff;">
                        <svg style="height:34px;width:34px;" fill="currentColor" viewBox="0 0 24 24"><path d="M5.25 5.653c0-.856.917-1.398 1.667-.986l11.54 6.348a1.125 1.125 0 0 1 0 1.971l-11.54 6.347a1.125 1.125 0 0 1-1.667-.985V5.653Z"/></svg>
                    </span>
                </div>

                {{-- hidden neighbours: buffer next/prev in the background so navigation is instant --}}
                @if ($nextSrc)<video src="{{ $nextSrc }}" preload="auto" muted playsinline aria-hidden="true" tabindex="-1" style="position:absolute;width:1px;height:1px;opacity:0;pointer-events:none;"></video>@endif
                @if ($prevSrc)<video src="{{ $prevSrc }}" preload="auto" muted playsinline aria-hidden="true" tabindex="-1" style="position:absolute;width:1px;height:1px;opacity:0;pointer-events:none;"></video>@endif

                {{-- single sound on/off toggle (top-right) — icon reflects real state --}}
                <button type="button"
                        @click="if (onAir) { soundOn = false; $refs.v.muted = true; } else { soundOn = true; $refs.v.muted = false; $refs.v.volume = 1; $refs.v.play()?.catch(() => {}); }"
                        title="{{ __('reels::admin.sound') }}"
                        style="position:absolute;inset-inline-end:12px;top:12px;z-index:20;display:flex;height:42px;width:42px;align-items:center;justify-content:center;border-radius:9999px;background:rgba(0,0,0,.55);color:#fff;border:0;cursor:pointer;">
                    <svg x-show="!onAir" style="height:22px;width:22px;" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M17.25 9.75 19.5 12m0 0 2.25 2.25M19.5 12l2.25-2.25M19.5 12l-2.25 2.25M6.75 8.25l4.72-4.72a.75.75 0 0 1 1.28.53v15.88a.75.75 0 0 1-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 0 1 2.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75Z"/></svg>
                    <svg x-show="onAir" style="height:22px;width:22px;display:none;" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M19.114 5.636a9 9 0 0 1 0 12.728M16.463 8.288a5.25 5.25 0 0 1 0 7.424M6.75 8.25l4.72-4.72a.75.75 0 0 1 1.28.53v15.88a.75.75 0 0 1-1.28.53l-4.72-4.72H4.51c-.88 0-1.704-.507-1.938-1.354A9.01 9.01 0 0 1 2.25 12c0-.83.112-1.633.322-2.396C2.806 8.756 3.63 8.25 4.51 8.25H6.75Z"/></svg>
                </button>

                {{-- top gradient + author/description --}}
                <div style="position:absolute;inset-inline:0;top:0;height:40%;background:linear-gradient(to bottom,rgba(0,0,0,.7),transparent);pointer-events:none;"></div>

                <div style="position:absolute;inset-inline-start:16px;top:12px;inset-inline-end:80px;color:#fff;">
                    <div style="display:flex;align-items:center;gap:8px;">
                        <img src="{{ $avatarUrl($user) }}" alt="" style="height:36px;width:36px;border-radius:9999px;object-fit:cover;box-shadow:0 0 0 2px rgba(255,255,255,.6);">
                        <span style="font-size:.875rem;font-weight:600;text-shadow:0 1px 2px rgba(0,0,0,.6);">{{ $name }}</span>
                    </div>
                    @if (filled($reel->description))
                        <p style="margin-top:8px;font-size:13px;line-height:1.35;text-shadow:0 1px 2px rgba(0,0,0,.6);">{{ \Illuminate\Support\Str::limit($reel->description, 120) }}</p>
                    @endif
                    <div style="margin-top:4px;font-size:11px;color:rgba(255,255,255,.85);">
                        {{ $reel->created_at?->diffForHumans() }} · {{ $fmt($reel->view_num) }} {{ __('reels::admin.views') }}
                    </div>
                </div>

                {{-- right action rail --}}
                <div style="position:absolute;inset-inline-end:8px;bottom:24px;display:flex;flex-direction:column;align-items:center;gap:16px;color:#fff;">
                    <button type="button" wire:click="openLikes({{ $reel->id }})" style="{{ $railBtn }}">
                        <span style="{{ $railIcon }}">
                            <svg style="height:24px;width:24px;" fill="currentColor" viewBox="0 0 24 24"><path d="M11.645 20.91l-.007-.003a25.18 25.18 0 0 1-4.622-3.388C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0 1 12 5.052 5.5 5.5 0 0 1 16.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.766 9.272a25.175 25.175 0 0 1-4.622 3.388l-.007.004Z"/></svg>
                        </span>
                        <span style="font-size:12px;font-weight:600;text-shadow:0 1px 2px rgba(0,0,0,.6);">{{ $fmt($reel->like_num) }}</span>
                    </button>
                    <button type="button" wire:click="openComments({{ $reel->id }})" style="{{ $railBtn }}">
                        <span style="{{ $railIcon }}">
                            <svg style="height:24px;width:24px;" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z"/></svg>
                        </span>
                        <span style="font-size:12px;font-weight:600;text-shadow:0 1px 2px rgba(0,0,0,.6);">{{ $fmt($reel->comment_num) }}</span>
                    </button>
                    <div style="{{ $railBtn }}">
                        <span style="{{ $railIcon }}">
                            <svg style="height:24px;width:24px;" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M7.217 10.907a2.25 2.25 0 1 0 0 2.186m0-2.186c.18.324.283.696.283 1.093s-.103.77-.283 1.093m0-2.186 9.566-5.314m-9.566 7.5 9.566 5.314m0 0a2.25 2.25 0 1 0 3.935 2.186 2.25 2.25 0 0 0-3.935-2.186Zm0-12.814a2.25 2.25 0 1 0 3.933-2.185 2.25 2.25 0 0 0-3.933 2.185Z"/></svg>
                        </span>
                        <span style="font-size:12px;font-weight:600;text-shadow:0 1px 2px rgba(0,0,0,.6);">{{ $fmt($reel->share_num ?? 0) }}</span>
                    </div>
                    <button type="button" wire:click="deleteReel({{ $reel->id }})" wire:confirm="{{ __('reels::admin.delete_confirm') }}" style="{{ $railBtn }}" title="{{ __('reels::admin.delete') }}">
                        <span style="{{ $railIcon }}">
                            <svg style="height:22px;width:22px;" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21q.51.078 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562q.51-.088 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0"/></svg>
                        </span>
                    </button>
                    <span style="font-size:11px;color:rgba(255,255,255,.55);">#{{ $reel->id }}</span>
                </div>

                {{-- progress bar (bottom) — shows how much of the reel has played;
                     click anywhere on it to seek. --}}
                <div @click="const r = $el.getBoundingClientRect(); if ($refs.v.duration) { $refs.v.currentTime = Math.min(1, Math.max(0, ($event.clientX - r.left) / r.width)) * $refs.v.duration; }"
                     style="position:absolute;left:0;right:0;bottom:0;height:6px;z-index:20;cursor:pointer;background:rgba(255,255,255,.25);">
                    <div style="height:100%;background:#ef4444;transition:width .12s linear;" :style="`width: ${progress}%`"></div>
                </div>
            </div>

            {{-- ===================== up / down navigation ===================== --}}
            <div style="display:flex;flex-direction:column;align-items:center;gap:12px;">
                <button type="button" wire:click="prev" @disabled($this->index <= 0)
                        class="fi-icon-btn"
                        style="display:flex;height:44px;width:44px;align-items:center;justify-content:center;border-radius:9999px;background:#fff;color:#374151;box-shadow:0 1px 3px rgba(0,0,0,.15);{{ $this->index <= 0 ? 'opacity:.3;cursor:default;' : 'cursor:pointer;' }}">
                    <svg style="height:20px;width:20px;" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m4.5 15.75 7.5-7.5 7.5 7.5"/></svg>
                </button>
                <span style="font-size:12px;font-weight:500;color:#9ca3af;">{{ $this->index + 1 }} / {{ $this->total }}</span>
                <button type="button" wire:click="next" @disabled($this->index >= $this->total - 1)
                        class="fi-icon-btn"
                        style="display:flex;height:44px;width:44px;align-items:center;justify-content:center;border-radius:9999px;background:#fff;color:#374151;box-shadow:0 1px 3px rgba(0,0,0,.15);{{ $this->index >= $this->total - 1 ? 'opacity:.3;cursor:default;' : 'cursor:pointer;' }}">
                    <svg style="height:20px;width:20px;" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5"/></svg>
                </button>
            </div>
        </div>
    @endif

    {{-- ===================== Likes / Comments panel (Livewire) ===================== --}}
    @if ($this->likesFor || $this->commentsFor)
        @php($people = $this->likesFor ? $this->getLikers() : $this->getComments())
        <div style="position:fixed;inset:0;z-index:50;display:flex;align-items:center;justify-content:center;padding:16px;" wire:click="closePanels">
            <div style="position:absolute;inset:0;background:rgba(3,7,18,.5);"></div>

            <div style="position:relative;display:flex;max-height:80vh;width:100%;max-width:28rem;flex-direction:column;overflow:hidden;border-radius:1rem;background:#fff;box-shadow:0 25px 50px -12px rgba(0,0,0,.5);"
                 class="dark:!bg-gray-900" wire:click.stop>

                <div style="display:flex;align-items:center;gap:10px;border-bottom:1px solid rgba(0,0,0,.08);padding:14px 20px;">
                    <h3 style="font-size:1rem;font-weight:600;" class="text-gray-900 dark:text-white">
                        {{ $this->likesFor ? __('reels::admin.likes') : __('reels::admin.comments') }}
                    </h3>
                    <span style="border-radius:9999px;background:rgba(0,0,0,.06);padding:1px 8px;font-size:12px;font-weight:600;color:#4b5563;">{{ $people->count() }}</span>
                    <button type="button" wire:click="closePanels" style="margin-inline-start:auto;display:inline-flex;height:32px;width:32px;align-items:center;justify-content:center;border-radius:9999px;color:#9ca3af;cursor:pointer;background:none;border:0;">
                        <svg style="height:20px;width:20px;" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                <div style="flex:1;overflow-y:auto;padding:8px;">
                    @if ($this->likesFor)
                        @forelse ($people as $like)
                            <div style="display:flex;align-items:center;gap:12px;border-radius:12px;padding:8px 12px;">
                                <img src="{{ $avatarUrl($like->user) }}" alt="" style="height:40px;width:40px;border-radius:9999px;object-fit:cover;">
                                <div style="min-width:0;">
                                    <div style="font-size:.875rem;font-weight:500;" class="text-gray-900 dark:text-white">{{ $like->user?->name ?? __('reels::admin.user') }}</div>
                                    <div style="font-size:12px;color:#9ca3af;">{{ $like->user?->uuid }}</div>
                                </div>
                            </div>
                        @empty
                            <div style="padding:40px 0;text-align:center;font-size:.875rem;color:#9ca3af;">{{ __('reels::admin.no_likes') }}</div>
                        @endforelse
                    @else
                        @forelse ($people as $comment)
                            <div style="display:flex;align-items:flex-start;gap:12px;padding:8px 12px;">
                                <img src="{{ $avatarUrl($comment->user) }}" alt="" style="margin-top:2px;height:36px;width:36px;border-radius:9999px;object-fit:cover;">
                                <div style="min-width:0;flex:1;">
                                    <div style="border-radius:1rem;background:rgba(0,0,0,.05);padding:8px 12px;">
                                        <div style="font-size:.875rem;font-weight:500;" class="text-gray-900 dark:text-white">{{ $comment->user?->name ?? __('reels::admin.user') }}</div>
                                        <div style="white-space:pre-line;font-size:.875rem;" class="text-gray-700 dark:text-gray-200">{{ $comment->comment }}</div>
                                    </div>
                                    <div style="padding:4px 12px 0;font-size:12px;color:#9ca3af;">{{ $comment->created_at?->diffForHumans() }}</div>
                                </div>
                            </div>
                        @empty
                            <div style="padding:40px 0;text-align:center;font-size:.875rem;color:#9ca3af;">{{ __('reels::admin.no_comments') }}</div>
                        @endforelse
                    @endif
                </div>
            </div>
        </div>
    @endif
</x-filament-panels::page>
