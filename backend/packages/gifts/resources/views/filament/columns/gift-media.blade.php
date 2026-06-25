{{--
    Reusable gift media cell for Filament admin tables.

    Renders a gift's visual by its `image_type`, the same artwork the Flutter app
    shows — crucially it PLAYS SVGA animations on the web via SVGAPlayer-Web (a
    .svga file is not a browser image, so a plain <img> shows nothing).

    @include with:
      'src'     => absolute media URL (Utd\Gifts\Support\Media::url(...))
      'type'    => lowercased image_type (svga|mp4|alpha|vap|png|svg|gif|…)
      'caption' => optional text shown under the media (e.g. gift name)
      'size'    => optional box size in px (default 48)
--}}
@php
    $src     = $src ?? null;
    $type    = strtolower((string) ($type ?? ''));
    $caption = $caption ?? null;
    $size    = (int) ($size ?? 48);
    $fallback = 'https://ui-avatars.com/api/?background=eee&color=999&name=%F0%9F%8E%81';
    $box = "width: {$size}px; height: {$size}px;";
@endphp

<div class="fi-ta-gift-media flex flex-col items-center gap-1 py-1">
    @if (blank($src))
        <img src="{{ $fallback }}" alt="" style="{{ $box }}"
             class="shrink-0 rounded-md object-contain" />

    @elseif ($type === 'svga')
        {{-- SVGAPlayer-Web renders the animation onto a canvas. wire:ignore keeps
             the player-owned DOM safe from Livewire morphs on table refresh. --}}
        <div
            wire:ignore
            x-data="{
                _player: null,
                async init() {
                    const src = @js($src);
                    try {
                        window.__svgaLoader = window.__svgaLoader || new Promise((resolve, reject) => {
                            if (window.SVGA) { resolve(); return; }
                            const s = document.createElement('script');
                            s.src = 'https://cdn.jsdelivr.net/npm/svgaplayerweb@2.3.1/build/svga.min.js';
                            s.onload = () => resolve();
                            s.onerror = () => reject(new Error('SVGA lib failed to load'));
                            document.head.appendChild(s);
                        });
                        await window.__svgaLoader;
                        const stage = this.$refs.stage;
                        stage.innerHTML = '';
                        this._player = new SVGA.Player(stage);
                        const parser = new SVGA.Parser(stage);
                        parser.load(src, (item) => {
                            this._player.setVideoItem(item);
                            this._player.startAnimation();
                        }, () => {});
                    } catch (e) { console.error('[gift-media svga]', e); }
                },
                destroy() { try { this._player && this._player.clear(); } catch (e) {} },
            }"
            class="shrink-0"
            style="{{ $box }}"
        >
            <div x-ref="stage" style="{{ $box }}"></div>
        </div>

    @elseif (in_array($type, ['mp4', 'alpha', 'vap'], true))
        <video src="{{ $src }}" autoplay loop muted playsinline
               style="{{ $box }}"
               class="shrink-0 rounded-md object-contain bg-black/5"></video>

    @else
        <img src="{{ $src }}" alt="" loading="lazy" style="{{ $box }}"
             onerror="this.onerror=null;this.src='{{ $fallback }}';"
             class="shrink-0 rounded-md object-contain" />
    @endif

    @if (filled($caption))
        <span class="max-w-[8rem] truncate text-xs text-gray-600 dark:text-gray-300" title="{{ $caption }}">
            {{ $caption }}
        </span>
    @endif
</div>
