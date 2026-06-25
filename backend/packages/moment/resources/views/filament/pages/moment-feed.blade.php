<x-filament-panels::page>
    @php($moments = $this->getMoments())
    @php($giftCounts = $this->giftCountsFor($moments->pluck('id')->all()))
    @php($uploader = app(\App\Contracts\MediaUploader::class))
    @php($avatarUrl = function ($u) {
        $name = $u?->name ?: __('moment::admin.user');
        return ($u?->avatar && \Illuminate\Support\Str::startsWith($u->avatar, 'http'))
            ? $u->avatar
            : 'https://ui-avatars.com/api/?name=' . urlencode($name) . '&background=4f46e5&color=fff';
    })
    @php($imgUrl = fn ($path) => \Illuminate\Support\Str::startsWith($path, 'http') ? $path : $uploader->url($path))

    <div
        x-data="{
            lbOpen: false,
            lbSrc: '',
            loading: false,
            observer: null,
            init() {
                this.observer = new IntersectionObserver(
                    (entries) => { if (entries.some(e => e.isIntersecting)) this.maybeLoad() },
                    { rootMargin: '900px 0px' }
                )
                this.$nextTick(() => this.attach())
            },
            attach() {
                const s = this.$refs.sentinel
                if (s) this.observer.observe(s)
            },
            maybeLoad() {
                const s = this.$refs.sentinel
                if (!s || this.loading || s.dataset.hasMore !== '1') return
                this.loading = true
                this.$wire.loadMore().then(() => {
                    this.loading = false
                    // keep going while the sentinel is still near the viewport
                    // (tall screens / fast flicks); the attribute reflects the latest state.
                    this.$nextTick(() => {
                        const el = this.$refs.sentinel
                        if (el && el.dataset.hasMore === '1'
                            && el.getBoundingClientRect().top < window.innerHeight + 900) {
                            this.maybeLoad()
                        }
                    })
                })
            },
        }"
        class="mx-auto w-full max-w-xl space-y-4"
    >

        {{-- ============================ FILTERS TOOLBAR ============================ --}}
        <div x-data="{ open: false }" wire:key="moment-filters"
             class="rounded-2xl bg-white p-3 shadow-sm ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10">
            <div class="flex items-center gap-2">
                <div class="relative flex-1">
                    <svg class="pointer-events-none absolute inset-y-0 start-3 my-auto h-4 w-4 text-gray-400" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z" /></svg>
                    <input type="search" wire:model.live.debounce.400ms="search"
                           placeholder="{{ __('moment::admin.search_placeholder') }}"
                           class="w-full rounded-xl border-0 bg-gray-100 py-2 ps-9 pe-3 text-sm text-gray-900 placeholder:text-gray-400 focus:ring-2 focus:ring-primary-500 dark:bg-white/5 dark:text-white">
                </div>
                <button type="button" @click="open = !open"
                        :class="open && 'ring-2 ring-primary-500'"
                        class="relative inline-flex shrink-0 items-center gap-1.5 rounded-xl bg-gray-100 px-3 py-2 text-sm font-medium text-gray-700 transition hover:bg-gray-200 dark:bg-white/5 dark:text-gray-200 dark:hover:bg-white/10">
                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M10.5 6h9.75M10.5 6a1.5 1.5 0 1 1-3 0m3 0a1.5 1.5 0 1 0-3 0M3.75 6H7.5m3 12h9.75m-9.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-3.75 0H7.5m9-6h3.75m-3.75 0a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m-9.75 0h9.75" /></svg>
                    <span>{{ __('moment::admin.filters') }}</span>
                    @if ($this->getActiveFilterCount())
                        <span class="ms-0.5 inline-flex h-5 min-w-[1.25rem] items-center justify-center rounded-full bg-primary-500 px-1.5 text-xs font-bold text-white">{{ $this->getActiveFilterCount() }}</span>
                    @endif
                </button>
            </div>

            <div x-show="open" x-collapse x-cloak class="mt-3 border-t border-gray-100 pt-3 dark:border-white/10">
                <div class="grid grid-cols-2 gap-3 sm:grid-cols-3">
                    <label class="block">
                        <span class="mb-1 block text-xs font-medium text-gray-500 dark:text-gray-400">{{ __('moment::admin.date_from') }}</span>
                        <input type="date" wire:model.live="dateFrom" class="w-full rounded-lg border-gray-200 bg-white text-sm shadow-sm focus:border-primary-500 focus:ring-primary-500 dark:border-white/10 dark:bg-white/5 dark:text-white">
                    </label>
                    <label class="block">
                        <span class="mb-1 block text-xs font-medium text-gray-500 dark:text-gray-400">{{ __('moment::admin.date_to') }}</span>
                        <input type="date" wire:model.live="dateTo" class="w-full rounded-lg border-gray-200 bg-white text-sm shadow-sm focus:border-primary-500 focus:ring-primary-500 dark:border-white/10 dark:bg-white/5 dark:text-white">
                    </label>
                    <label class="block">
                        <span class="mb-1 block text-xs font-medium text-gray-500 dark:text-gray-400">{{ __('moment::admin.content_type') }}</span>
                        <select wire:model.live="contentType" class="w-full rounded-lg border-gray-200 bg-white text-sm shadow-sm focus:border-primary-500 focus:ring-primary-500 dark:border-white/10 dark:bg-white/5 dark:text-white">
                            <option value="all">{{ __('moment::admin.ct_all') }}</option>
                            <option value="media">{{ __('moment::admin.ct_media') }}</option>
                            <option value="text">{{ __('moment::admin.ct_text') }}</option>
                            <option value="video">{{ __('moment::admin.ct_video') }}</option>
                        </select>
                    </label>
                    <label class="block">
                        <span class="mb-1 block text-xs font-medium text-gray-500 dark:text-gray-400">{{ __('moment::admin.min_likes') }}</span>
                        <input type="number" min="0" wire:model.live.debounce.500ms="minLikes" placeholder="0" class="w-full rounded-lg border-gray-200 bg-white text-sm shadow-sm focus:border-primary-500 focus:ring-primary-500 dark:border-white/10 dark:bg-white/5 dark:text-white">
                    </label>
                    <label class="block">
                        <span class="mb-1 block text-xs font-medium text-gray-500 dark:text-gray-400">{{ __('moment::admin.min_comments') }}</span>
                        <input type="number" min="0" wire:model.live.debounce.500ms="minComments" placeholder="0" class="w-full rounded-lg border-gray-200 bg-white text-sm shadow-sm focus:border-primary-500 focus:ring-primary-500 dark:border-white/10 dark:bg-white/5 dark:text-white">
                    </label>
                    @if ($this->giftsAvailable())
                        <label class="block">
                            <span class="mb-1 block text-xs font-medium text-gray-500 dark:text-gray-400">{{ __('moment::admin.min_gifts') }}</span>
                            <input type="number" min="0" wire:model.live.debounce.500ms="minGifts" placeholder="0" class="w-full rounded-lg border-gray-200 bg-white text-sm shadow-sm focus:border-primary-500 focus:ring-primary-500 dark:border-white/10 dark:bg-white/5 dark:text-white">
                        </label>
                    @endif
                </div>

                <div class="mt-3 flex flex-wrap items-center gap-x-5 gap-y-2 border-t border-gray-100 pt-3 dark:border-white/10">
                    <label class="inline-flex cursor-pointer items-center gap-2 text-sm text-gray-700 dark:text-gray-200">
                        <input type="checkbox" wire:model.live="reportedOnly" class="rounded border-gray-300 text-primary-600 focus:ring-primary-500 dark:border-white/20 dark:bg-white/5">
                        {{ __('moment::admin.reported_only') }}
                    </label>
                    @if ($this->giftsAvailable())
                        <label class="inline-flex cursor-pointer items-center gap-2 text-sm text-gray-700 dark:text-gray-200">
                            <input type="checkbox" wire:model.live="hasGifts" class="rounded border-gray-300 text-primary-600 focus:ring-primary-500 dark:border-white/20 dark:bg-white/5">
                            {{ __('moment::admin.has_gifts_only') }}
                        </label>
                    @endif
                    <button type="button" wire:click="resetFilters"
                            class="ms-auto inline-flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-medium text-gray-500 transition hover:bg-gray-100 hover:text-gray-700 dark:hover:bg-white/5 dark:hover:text-gray-200">
                        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M16.023 9.348h4.992v-.001M2.985 19.644v-4.992m0 0h4.992m-4.993 0 3.181 3.183a8.25 8.25 0 0 0 13.803-3.7M4.031 9.865a8.25 8.25 0 0 1 13.803-3.7l3.181 3.182m0-4.991v4.99" /></svg>
                        {{ __('moment::admin.reset_filters') }}
                    </button>
                </div>
            </div>
        </div>

        @forelse ($moments as $moment)
            @php($user = $moment->user)
            @php($name = $user?->name ?: __('moment::admin.user'))
            @php($imgs = $moment->images)

            <article wire:key="moment-{{ $moment->id }}"
                     class="rounded-2xl bg-white p-4 shadow-sm ring-1 ring-gray-950/5 transition hover:shadow-md dark:bg-gray-900 dark:ring-white/10">

                {{-- Header --}}
                <header class="flex items-center gap-3">
                    <img src="{{ $avatarUrl($user) }}" alt="{{ $name }}"
                         class="h-10 w-10 shrink-0 rounded-full object-cover ring-1 ring-gray-950/5 dark:ring-white/10">
                    <div class="min-w-0 flex-1 leading-tight">
                        <div class="truncate text-sm font-semibold text-gray-900 dark:text-white">{{ $name }}</div>
                        <div class="text-xs text-gray-400">{{ $moment->created_at?->diffForHumans() }}</div>
                    </div>
                    <button type="button" wire:click="deleteMoment({{ $moment->id }})" wire:confirm="{{ __('moment::admin.delete_confirm') }}"
                            class="-me-1 inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-full text-gray-300 transition hover:bg-danger-50 hover:text-danger-600 dark:text-gray-600 dark:hover:bg-danger-500/10"
                            title="{{ __('moment::admin.delete') }}">
                        <svg class="h-[18px] w-[18px]" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21q.51.078 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562q.51-.088 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>
                    </button>
                </header>

                {{-- Text --}}
                @if (filled($moment->description))
                    <p class="mt-3 whitespace-pre-line text-[15px] leading-relaxed text-gray-800 dark:text-gray-100">{{ $moment->description }}</p>
                @endif

                {{-- Images: Facebook-style album grid (1 full, 2 side-by-side, 3 big-left+2,
                     4 grid, 5+ with overlay). Inline styles on purpose: the Filament panel
                     has no custom theme, so grid-cols/aspect utility classes aren't compiled. --}}
                @if ($imgs->isNotEmpty())
                    @php($imgCount = $imgs->count())
                    @php($visible = $imgCount >= 5 ? $imgs->take(4) : $imgs)
                    @php($gridStyle = $imgCount === 1 ? 'grid-template-columns:1fr;' : ($imgCount === 2 ? 'grid-template-columns:1fr 1fr; height:15rem;' : ($imgCount === 3 ? 'grid-template-columns:1fr 1fr; grid-template-rows:1fr 1fr; height:20rem;' : 'grid-template-columns:1fr 1fr; grid-template-rows:1fr 1fr; height:22rem;')))
                    <div class="mt-3 overflow-hidden rounded-xl ring-1 ring-gray-950/5 dark:ring-white/10"
                         style="display:grid; gap:3px; {{ $gridStyle }}">
                        @foreach ($visible as $img)
                            @php($src = $imgUrl($img->image))
                            @php($spanLeft = $imgCount === 3 && $loop->first)
                            @php($isOverflow = $imgCount >= 5 && $loop->last)
                            @php($imgStyle = ($imgCount === 1 ? 'display:block; width:100%; max-height:30rem; object-fit:cover;' : 'display:block; width:100%; height:100%; object-fit:cover;') . ($spanLeft ? ' grid-row:1 / 3;' : ''))
                            @if ($isOverflow)
                                <div style="position:relative;">
                                    <img src="{{ $src }}" alt="" loading="lazy"
                                         @click="lbSrc = @js($src); lbOpen = true"
                                         class="cursor-zoom-in bg-gray-100 transition hover:opacity-95 dark:bg-gray-800"
                                         style="{{ $imgStyle }}">
                                    <div @click="lbSrc = @js($src); lbOpen = true"
                                         style="position:absolute; inset:0; display:flex; align-items:center; justify-content:center; cursor:zoom-in; background:rgba(0,0,0,.5); color:#fff; font-size:1.6rem; font-weight:700;">
                                        +{{ $imgCount - 4 }}
                                    </div>
                                </div>
                            @else
                                <img src="{{ $src }}" alt="" loading="lazy"
                                     @click="lbSrc = @js($src); lbOpen = true"
                                     class="cursor-zoom-in bg-gray-100 transition hover:opacity-95 dark:bg-gray-800"
                                     style="{{ $imgStyle }}">
                            @endif
                        @endforeach
                    </div>
                @endif

                {{-- Actions --}}
                <div class="mt-3 flex items-center gap-6 border-t border-gray-100 pt-3 text-sm text-gray-500 dark:border-white/5">
                    <button type="button" wire:click="openLikes({{ $moment->id }})"
                            class="group inline-flex items-center gap-1.5 transition hover:text-rose-500">
                        <svg class="h-5 w-5 transition group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke-width="1.6" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z" /></svg>
                        <span class="font-medium">{{ $moment->likes_count }}</span>
                    </button>
                    <button type="button" wire:click="openComments({{ $moment->id }})"
                            class="group inline-flex items-center gap-1.5 transition hover:text-primary-500">
                        <svg class="h-5 w-5 transition group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke-width="1.6" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z" /></svg>
                        <span class="font-medium">{{ $moment->comments_count }}</span>
                    </button>
                    @if ($this->giftsAvailable())
                        <button type="button" wire:click="openGifts({{ $moment->id }})"
                                class="group inline-flex items-center gap-1.5 transition hover:text-amber-500">
                            <svg class="h-5 w-5 transition group-hover:scale-110" fill="none" viewBox="0 0 24 24" stroke-width="1.6" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 11.25v8.25a1.5 1.5 0 0 1-1.5 1.5H5.25a1.5 1.5 0 0 1-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 1 0 9.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1 1 14.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" /></svg>
                            <span class="font-medium">{{ $giftCounts[$moment->id] ?? 0 }}</span>
                        </button>
                    @endif
                    <div class="ms-auto flex items-center gap-3">
                        @if ($moment->reports_count)
                            <span class="inline-flex items-center gap-1 rounded-full bg-danger-50 px-2 py-0.5 text-xs font-semibold text-danger-600 dark:bg-danger-500/10 dark:text-danger-400"
                                  title="{{ __('moment::admin.post_reports') }}">
                                <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M3 3v1.5M3 21v-6m0 0 2.77-.693a9 9 0 0 1 6.208.682l.108.054a9 9 0 0 0 6.086.71l3.114-.732a48.524 48.524 0 0 1-.005-10.499l-3.11.732a9 9 0 0 1-6.085-.711l-.108-.054a9 9 0 0 0-6.208-.682L3 4.5M3 15V4.5" /></svg>
                                {{ $moment->reports_count }}
                            </span>
                        @endif
                        @if ($moment->comment_reports_count)
                            <span class="inline-flex items-center gap-1 rounded-full bg-warning-50 px-2 py-0.5 text-xs font-semibold text-warning-600 dark:bg-warning-500/10 dark:text-warning-400"
                                  title="{{ __('moment::admin.comment_reports_count') }}">
                                <svg class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z" /></svg>
                                {{ $moment->comment_reports_count }}
                            </span>
                        @endif
                        <span class="text-xs text-gray-300 dark:text-gray-600">#{{ $moment->id }}</span>
                    </div>
                </div>

            </article>
        @empty
            <div class="rounded-2xl bg-white py-16 text-center text-sm text-gray-400 ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10">
                {{ __('moment::admin.empty') }}
            </div>
        @endforelse

        {{-- Infinite scroll: this always-present sentinel auto-triggers loadMore() as it
             nears the viewport. `data-has-more` is re-rendered each round so the observer
             (attached once) keeps working across loads and author filtering. --}}
        <div x-ref="sentinel" wire:key="feed-sentinel"
             data-has-more="{{ $moments->hasMorePages() ? '1' : '0' }}"
             class="py-6">
            @if ($moments->hasMorePages())
                <div class="flex items-center justify-center gap-2 text-sm text-gray-400">
                    <svg class="h-5 w-5 animate-spin text-primary-500" fill="none" viewBox="0 0 24 24">
                        <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                        <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 0 1 8-8V0C5.373 0 0 5.373 0 12h4z"></path>
                    </svg>
                    <span>{{ __('moment::admin.loading_more') }}</span>
                </div>
            @elseif ($moments->isNotEmpty())
                <div class="flex items-center justify-center gap-3 text-xs text-gray-300 dark:text-gray-600">
                    <span class="h-px w-8 bg-current opacity-40"></span>
                    {{ __('moment::admin.all_caught_up') }}
                    <span class="h-px w-8 bg-current opacity-40"></span>
                </div>
            @endif
        </div>

        {{-- ============================ IMAGE LIGHTBOX (Alpine) ============================ --}}
        <template x-teleport="body">
            <div x-show="lbOpen" x-transition.opacity style="display:none"
                 @click="lbOpen = false" @keydown.escape.window="lbOpen = false"
                 class="fixed inset-0 z-[60] flex cursor-zoom-out items-center justify-center bg-black/80 p-4">
                <img :src="lbSrc" alt="" class="max-h-[92vh] max-w-[92vw] rounded-lg shadow-2xl">
                <button type="button" @click="lbOpen = false"
                        class="absolute end-4 top-4 inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/10 text-white transition hover:bg-white/20">
                    <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
                </button>
            </div>
        </template>
    </div>

    {{-- ===================== Likes / Comments / Gifts panel (Livewire) ===================== --}}
    @if ($this->likesFor || $this->commentsFor || $this->giftsFor)
        @php($people = $this->likesFor ? $this->getLikers() : ($this->commentsFor ? $this->getComments() : $this->getGifts()))
        @php($giftTotal = $this->giftsFor ? $people->sum(fn ($g) => (int) ($g->total_price ?? 0)) : 0)
        @php($panelMomentId = $this->getPanelMomentId())
        @php($pc = $this->panelCounts())
        @php($reactionEmoji = ['like' => '👍', 'love' => '❤️', 'haha' => '😂', 'wow' => '😮', 'sad' => '😢', 'angry' => '😡'])
        @php($profileUrl = function ($u) {
            return ($u && \App\Filament\Resources\UserResource::canAccess())
                ? \App\Filament\Resources\UserResource::getUrl('view', ['record' => $u->getKey()])
                : null;
        })
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4"
             x-data @keydown.escape.window="$wire.closePanels()"
             wire:click="closePanels">
            <div class="absolute inset-0 bg-gray-950/50 backdrop-blur-sm"></div>

            <div class="relative flex max-h-[88vh] min-h-[60vh] w-full max-w-2xl flex-col overflow-hidden rounded-3xl bg-white shadow-2xl ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10"
                 wire:click.stop>

                {{-- Tabbed header (command-palette style): switch lists in place --}}
                <div class="flex items-center gap-3 border-b border-gray-100 px-5 py-4 dark:border-white/10">
                    <div class="flex flex-1 items-center gap-1.5 overflow-x-auto rounded-2xl bg-gray-100 p-1.5 dark:bg-white/5">
                        <button type="button" wire:click="openLikes({{ $panelMomentId }})"
                                class="inline-flex shrink-0 items-center gap-2 whitespace-nowrap rounded-xl px-4 py-2 text-sm font-semibold transition {{ $this->likesFor ? 'bg-white text-rose-600 shadow-sm dark:bg-white/10 dark:text-rose-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200' }}">
                            <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24"><path d="M11.645 20.91l-.007-.003a25.18 25.18 0 0 1-4.622-3.388C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0 1 12 5.052 5.5 5.5 0 0 1 16.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.766 9.272a25.175 25.175 0 0 1-4.622 3.388l-.007.004Z" /></svg>
                            {{ __('moment::admin.likes') }}
                            <span class="rounded-full bg-gray-200/80 px-2 py-0.5 text-xs font-bold text-gray-600 dark:bg-white/10 dark:text-gray-300">{{ $pc['likes'] }}</span>
                        </button>
                        <button type="button" wire:click="openComments({{ $panelMomentId }})"
                                class="inline-flex shrink-0 items-center gap-2 whitespace-nowrap rounded-xl px-4 py-2 text-sm font-semibold transition {{ $this->commentsFor ? 'bg-white text-primary-600 shadow-sm dark:bg-white/10 dark:text-primary-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200' }}">
                            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m9-1.5a8.96 8.96 0 0 1-4.255 7.625L12 21l-2.755-3.625A8.96 8.96 0 1 1 21 9.75Z" /></svg>
                            {{ __('moment::admin.comments') }}
                            <span class="rounded-full bg-gray-200/80 px-2 py-0.5 text-xs font-bold text-gray-600 dark:bg-white/10 dark:text-gray-300">{{ $pc['comments'] }}</span>
                        </button>
                        @if ($this->giftsAvailable())
                            <button type="button" wire:click="openGifts({{ $panelMomentId }})"
                                    class="inline-flex shrink-0 items-center gap-2 whitespace-nowrap rounded-xl px-4 py-2 text-sm font-semibold transition {{ $this->giftsFor ? 'bg-white text-amber-600 shadow-sm dark:bg-white/10 dark:text-amber-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200' }}">
                                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 11.25v8.25a1.5 1.5 0 0 1-1.5 1.5H5.25a1.5 1.5 0 0 1-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 1 0 9.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1 1 14.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" /></svg>
                                {{ __('moment::admin.gifts') }}
                                <span class="rounded-full bg-gray-200/80 px-2 py-0.5 text-xs font-bold text-gray-600 dark:bg-white/10 dark:text-gray-300">{{ $pc['gifts'] }}</span>
                            </button>
                        @endif
                    </div>
                    <button type="button" wire:click="closePanels" class="inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-gray-400 transition hover:bg-gray-200/70 hover:text-gray-700 dark:hover:bg-white/10">
                        <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                @if ($this->giftsFor)
                    <div class="flex items-center justify-between gap-2 border-b border-gray-100 px-6 py-3.5 dark:border-white/10">
                        <span class="inline-flex items-center gap-1.5 text-sm font-bold text-amber-600 dark:text-amber-400">
                            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 11.25v8.25a1.5 1.5 0 0 1-1.5 1.5H5.25a1.5 1.5 0 0 1-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 1 0 9.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1 1 14.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" /></svg>
                            {{ number_format($giftTotal) }}
                            <span class="text-xs font-medium text-gray-400">{{ __('moment::admin.total_value') }}</span>
                        </span>
                        <div class="inline-flex rounded-lg bg-gray-100 p-0.5 dark:bg-white/5">
                            <button type="button" wire:click="sortGifts('newest')"
                                    class="rounded-md px-3 py-1 text-xs font-semibold transition {{ $this->giftSort === 'newest' ? 'bg-white text-primary-600 shadow-sm dark:bg-white/10 dark:text-primary-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400' }}">
                                {{ __('moment::admin.sort_newest') }}
                            </button>
                            <button type="button" wire:click="sortGifts('top')"
                                    class="rounded-md px-3 py-1 text-xs font-semibold transition {{ $this->giftSort === 'top' ? 'bg-white text-primary-600 shadow-sm dark:bg-white/10 dark:text-primary-400' : 'text-gray-500 hover:text-gray-700 dark:text-gray-400' }}">
                                {{ __('moment::admin.sort_top') }}
                            </button>
                        </div>
                    </div>
                @endif

                <div class="flex-1 space-y-1 overflow-y-auto p-3">
                    @if ($this->likesFor)
                        @forelse ($people as $like)
                            @php($lUrl = $profileUrl($like->user))
                            <div class="flex items-center gap-4 rounded-xl px-4 py-3 transition hover:bg-gray-50 dark:hover:bg-white/5">
                                <a @if ($lUrl) href="{{ $lUrl }}" @endif class="shrink-0">
                                    <img src="{{ $avatarUrl($like->user) }}" alt="" class="h-11 w-11 rounded-full object-cover ring-1 ring-gray-950/5 dark:ring-white/10">
                                </a>
                                <div class="min-w-0">
                                    @if ($lUrl)
                                        <a href="{{ $lUrl }}" class="block truncate text-sm font-medium text-primary-600 hover:underline dark:text-primary-400">{{ $like->user?->name ?? __('moment::admin.user') }}</a>
                                    @else
                                        <div class="truncate text-sm font-medium text-gray-900 dark:text-white">{{ $like->user?->name ?? __('moment::admin.user') }}</div>
                                    @endif
                                    <div class="truncate text-xs text-gray-400">{{ $like->user?->uuid }}</div>
                                </div>
                                @php($rt = $like->reaction_type ?: 'like')
                                <span class="ms-auto inline-flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-gray-100 text-xl leading-none dark:bg-white/5"
                                      title="{{ __('moment::admin.reaction_' . $rt) }}">{{ $reactionEmoji[$rt] ?? '👍' }}</span>
                            </div>
                        @empty
                            <div class="flex min-h-[40vh] flex-col items-center justify-center gap-3 px-6 py-16 text-center text-sm text-gray-400">{{ __('moment::admin.no_likes') }}</div>
                        @endforelse
                    @elseif ($this->commentsFor)
                        @forelse ($people as $comment)
                            @php($cUrl = $profileUrl($comment->user))
                            @php($cDepth = min((int) ($comment->depth ?? 0), 4))
                            <div wire:key="comment-{{ $comment->id }}"
                                 @if ($cDepth) style="margin-inline-start: {{ $cDepth * 1.75 }}rem" @endif
                                 class="flex items-start gap-3 rounded-xl px-4 py-2.5 transition hover:bg-gray-50 dark:hover:bg-white/5">
                                @if ($cDepth)
                                    <span class="mt-4 h-4 w-2.5 shrink-0 rounded-bl-md border-b-2 border-s-2 border-gray-200 dark:border-white/10"></span>
                                @endif
                                <a @if ($cUrl) href="{{ $cUrl }}" @endif class="shrink-0">
                                    <img src="{{ $avatarUrl($comment->user) }}" alt="" class="mt-0.5 rounded-full object-cover ring-1 ring-gray-950/5 dark:ring-white/10 {{ $cDepth ? 'h-9 w-9' : 'h-11 w-11' }}">
                                </a>
                                <div class="min-w-0 flex-1">
                                    <div class="rounded-2xl bg-gray-100 px-4 py-2.5 dark:bg-white/5 {{ $cDepth ? 'border-s-2 border-primary-400/60' : '' }}">
                                        @if ($cDepth && $comment->parentComment)
                                            <div class="mb-1.5 inline-flex max-w-full items-center gap-1 rounded-md bg-gray-200/70 px-1.5 py-0.5 text-[11px] font-medium text-gray-500 dark:bg-white/10 dark:text-gray-300">
                                                <svg class="h-3 w-3 shrink-0" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M9 15 3 9m0 0 6-6M3 9h12a6 6 0 0 1 0 12h-3" /></svg>
                                                <span class="truncate">{{ __('moment::admin.replying_to') }} <span class="font-semibold text-gray-700 dark:text-gray-200">{{ $comment->parentComment->user?->name ?? __('moment::admin.user') }}</span></span>
                                            </div>
                                        @endif
                                        <div class="flex items-start justify-between gap-2">
                                            @if ($cUrl)
                                                <a href="{{ $cUrl }}" class="truncate text-sm font-medium text-primary-600 hover:underline dark:text-primary-400">{{ $comment->user?->name ?? __('moment::admin.user') }}</a>
                                            @else
                                                <span class="truncate text-sm font-medium text-gray-900 dark:text-white">{{ $comment->user?->name ?? __('moment::admin.user') }}</span>
                                            @endif
                                            <div class="flex shrink-0 items-center gap-0.5">
                                                @if ($comment->user && $comment->user->status)
                                                    <button type="button"
                                                            wire:click="banCommenter({{ $comment->user->id }})"
                                                            wire:confirm="{{ __('moment::admin.ban_commenter_confirm') }}"
                                                            title="{{ __('moment::admin.ban_commenter') }}"
                                                            class="inline-flex h-7 w-7 items-center justify-center rounded-full text-gray-400 transition hover:bg-danger-50 hover:text-danger-600 dark:hover:bg-danger-500/10">
                                                        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M18.364 18.364A9 9 0 0 0 5.636 5.636m12.728 12.728A9 9 0 1 1 5.636 5.636m12.728 12.728L5.636 5.636" /></svg>
                                                    </button>
                                                @endif
                                                <button type="button"
                                                        wire:click="deleteComment({{ $comment->id }})"
                                                        wire:confirm="{{ __('moment::admin.delete_comment_confirm') }}"
                                                        title="{{ __('moment::admin.delete_comment') }}"
                                                        class="inline-flex h-7 w-7 items-center justify-center rounded-full text-gray-400 transition hover:bg-danger-50 hover:text-danger-600 dark:hover:bg-danger-500/10">
                                                    <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.7" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="m14.74 9-.346 9m-4.788 0L9.26 9m9.968-3.21q.51.078 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 0 1-2.244 2.077H8.084a2.25 2.25 0 0 1-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 0 0-3.478-.397m-12 .562q.51-.088 1.022-.165m0 0a48.11 48.11 0 0 1 3.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 0 0-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 0 0-7.5 0" /></svg>
                                                </button>
                                            </div>
                                        </div>
                                        <div class="whitespace-pre-line text-sm text-gray-700 dark:text-gray-200">{{ $comment->comment }}</div>
                                    </div>
                                    <div class="px-4 pt-1.5 text-xs text-gray-400">
                                        @if ($comment->user?->uuid)<span class="font-mono">{{ $comment->user->uuid }}</span> · @endif{{ $comment->created_at?->diffForHumans() }}
                                    </div>
                                </div>
                            </div>
                        @empty
                            <div class="flex min-h-[40vh] flex-col items-center justify-center gap-3 px-6 py-16 text-center text-sm text-gray-400">{{ __('moment::admin.no_comments') }}</div>
                        @endforelse
                    @else
                        @forelse ($people as $gift)
                            @php($gUrl = $profileUrl($gift->sender))
                            <div class="flex items-center gap-4 rounded-xl px-4 py-3 transition hover:bg-gray-50 dark:hover:bg-white/5">
                                @if ($this->giftSort === 'top')
                                    <span @class([
                                        'flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-xs font-bold',
                                        'bg-amber-400 text-white shadow-sm shadow-amber-400/40' => $loop->iteration === 1,
                                        'bg-gray-300 text-white' => $loop->iteration === 2,
                                        'bg-orange-400 text-white' => $loop->iteration === 3,
                                        'bg-gray-100 text-gray-500 dark:bg-white/10 dark:text-gray-400' => $loop->iteration > 3,
                                    ])>{{ $loop->iteration }}</span>
                                @endif
                                <a @if ($gUrl) href="{{ $gUrl }}" @endif class="shrink-0">
                                    <img src="{{ $avatarUrl($gift->sender) }}" alt="" class="h-11 w-11 rounded-full object-cover ring-1 ring-gray-950/5 dark:ring-white/10">
                                </a>
                                <div class="min-w-0 flex-1">
                                    @if ($gUrl)
                                        <a href="{{ $gUrl }}" class="block truncate text-sm font-medium text-primary-600 hover:underline dark:text-primary-400">{{ $gift->sender?->name ?? __('moment::admin.user') }}</a>
                                    @else
                                        <div class="truncate text-sm font-medium text-gray-900 dark:text-white">{{ $gift->sender?->name ?? __('moment::admin.user') }}</div>
                                    @endif
                                    <div class="truncate text-xs text-gray-400">
                                        @if ($gift->sender?->uuid)<span class="font-mono">{{ $gift->sender->uuid }}</span> · @endif{{ $gift->created_at?->diffForHumans() }}
                                    </div>
                                </div>
                                <div class="shrink-0 text-end">
                                    <div class="flex items-center justify-end gap-1.5 text-sm font-medium text-gray-900 dark:text-white">
                                        <svg class="h-4 w-4 text-amber-500" fill="none" viewBox="0 0 24 24" stroke-width="1.6" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M21 11.25v8.25a1.5 1.5 0 0 1-1.5 1.5H5.25a1.5 1.5 0 0 1-1.5-1.5v-8.25M12 4.875A2.625 2.625 0 1 0 9.375 7.5H12m0-2.625V7.5m0-2.625A2.625 2.625 0 1 1 14.625 7.5H12m0 0V21m-8.625-9.75h18c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125h-18c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125Z" /></svg>
                                        <span class="max-w-[8rem] truncate">{{ $gift->gift_name }}</span>
                                        @if ((int) ($gift->gift_num ?? 1) > 1)
                                            <span class="text-gray-400">×{{ $gift->gift_num }}</span>
                                        @endif
                                    </div>
                                    <div class="mt-0.5 text-xs font-medium text-amber-600 dark:text-amber-400">{{ number_format((int) $gift->total_price) }}</div>
                                </div>
                            </div>
                        @empty
                            <div class="flex min-h-[40vh] flex-col items-center justify-center gap-3 px-6 py-16 text-center text-sm text-gray-400">{{ __('moment::admin.no_gifts') }}</div>
                        @endforelse
                    @endif
                </div>

                {{-- Footer hint bar (command-palette style) --}}
                <div class="flex items-center gap-6 border-t border-gray-100 bg-gray-50/60 px-6 py-3.5 text-xs text-gray-400 dark:border-white/10 dark:bg-white/[0.02]">
                    <span class="inline-flex items-center gap-1.5">
                        <kbd class="inline-flex h-5 min-w-[1.25rem] items-center justify-center rounded border border-gray-200 bg-white px-1 font-sans text-[11px] font-semibold text-gray-500 shadow-sm dark:border-white/10 dark:bg-white/5 dark:text-gray-400">↵</kbd>
                        {{ __('moment::admin.open_profile') }}
                    </span>
                    <span class="inline-flex items-center gap-1.5">
                        <kbd class="inline-flex h-5 items-center justify-center rounded border border-gray-200 bg-white px-1.5 font-sans text-[11px] font-semibold text-gray-500 shadow-sm dark:border-white/10 dark:bg-white/5 dark:text-gray-400">Esc</kbd>
                        {{ __('moment::admin.close') }}
                    </span>
                </div>
            </div>
        </div>
    @endif
</x-filament-panels::page>
