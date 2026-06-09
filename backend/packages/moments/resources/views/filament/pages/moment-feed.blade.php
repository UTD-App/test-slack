<x-filament-panels::page>
    @php($moments = $this->getMoments())
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

                {{-- Images --}}
                @if ($imgs->isNotEmpty())
                    <div class="mt-3 grid gap-1 overflow-hidden rounded-xl ring-1 ring-gray-950/5 dark:ring-white/10 {{ $imgs->count() === 1 ? 'grid-cols-1' : 'grid-cols-2' }}">
                        @foreach ($imgs as $img)
                            @php($src = $imgUrl($img->image))
                            <img src="{{ $src }}" alt="" loading="lazy"
                                 @click="lbSrc = @js($src); lbOpen = true"
                                 class="w-full cursor-zoom-in bg-gray-100 object-cover transition hover:opacity-95 dark:bg-gray-800 {{ $imgs->count() === 1 ? 'max-h-80' : 'aspect-square' }}">
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
                    <span class="ms-auto text-xs text-gray-300 dark:text-gray-600">#{{ $moment->id }}</span>
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

    {{-- ===================== Likes / Comments panel (Livewire) ===================== --}}
    @if ($this->likesFor || $this->commentsFor)
        @php($people = $this->likesFor ? $this->getLikers() : $this->getComments())
        <div class="fixed inset-0 z-50 flex items-center justify-center p-4" wire:click="closePanels">
            <div class="absolute inset-0 bg-gray-950/50 backdrop-blur-sm"></div>

            <div class="relative flex max-h-[80vh] w-full max-w-md flex-col overflow-hidden rounded-2xl bg-white shadow-2xl ring-1 ring-gray-950/5 dark:bg-gray-900 dark:ring-white/10"
                 wire:click.stop>

                <div class="flex items-center gap-2.5 border-b border-gray-100 px-5 py-3.5 dark:border-white/10">
                    @if ($this->likesFor)
                        <span class="inline-flex h-7 w-7 items-center justify-center rounded-full bg-rose-500 text-white">
                            <svg class="h-4 w-4" fill="currentColor" viewBox="0 0 24 24"><path d="M11.645 20.91l-.007-.003a25.18 25.18 0 0 1-4.622-3.388C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0 1 12 5.052 5.5 5.5 0 0 1 16.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.766 9.272a25.175 25.175 0 0 1-4.622 3.388l-.007.004Z" /></svg>
                        </span>
                        <h3 class="text-base font-semibold text-gray-900 dark:text-white">{{ __('moment::admin.likes') }}</h3>
                    @else
                        <span class="inline-flex h-7 w-7 items-center justify-center rounded-full bg-primary-500 text-white">
                            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M7.5 8.25h9m-9 3H12m9-1.5a8.96 8.96 0 0 1-4.255 7.625L12 21l-2.755-3.625A8.96 8.96 0 1 1 21 9.75Z" /></svg>
                        </span>
                        <h3 class="text-base font-semibold text-gray-900 dark:text-white">{{ __('moment::admin.comments') }}</h3>
                    @endif
                    <span class="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-semibold text-gray-600 dark:bg-white/10 dark:text-gray-300">{{ $people->count() }}</span>
                    <button type="button" wire:click="closePanels" class="ms-auto inline-flex h-8 w-8 items-center justify-center rounded-full text-gray-400 transition hover:bg-gray-100 hover:text-gray-600 dark:hover:bg-white/10">
                        <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor"><path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" /></svg>
                    </button>
                </div>

                <div class="flex-1 overflow-y-auto p-2">
                    @if ($this->likesFor)
                        @forelse ($people as $like)
                            <div class="flex items-center gap-3 rounded-xl px-3 py-2 transition hover:bg-gray-50 dark:hover:bg-white/5">
                                <img src="{{ $avatarUrl($like->user) }}" alt="" class="h-10 w-10 rounded-full object-cover ring-1 ring-gray-950/5 dark:ring-white/10">
                                <div class="min-w-0">
                                    <div class="truncate text-sm font-medium text-gray-900 dark:text-white">{{ $like->user?->name ?? __('moment::admin.user') }}</div>
                                    <div class="truncate text-xs text-gray-400">{{ $like->user?->uuid }}</div>
                                </div>
                                <span class="ms-auto text-rose-500">
                                    <svg class="h-5 w-5" fill="currentColor" viewBox="0 0 24 24"><path d="M11.645 20.91l-.007-.003a25.18 25.18 0 0 1-4.622-3.388C4.688 15.36 2.25 12.174 2.25 8.25 2.25 5.322 4.714 3 7.688 3A5.5 5.5 0 0 1 12 5.052 5.5 5.5 0 0 1 16.313 3c2.973 0 5.437 2.322 5.437 5.25 0 3.925-2.438 7.111-4.766 9.272a25.175 25.175 0 0 1-4.622 3.388l-.007.004Z" /></svg>
                                </span>
                            </div>
                        @empty
                            <div class="py-10 text-center text-sm text-gray-400">{{ __('moment::admin.no_likes') }}</div>
                        @endforelse
                    @else
                        @forelse ($people as $comment)
                            <div class="flex items-start gap-3 px-3 py-2">
                                <img src="{{ $avatarUrl($comment->user) }}" alt="" class="mt-0.5 h-9 w-9 rounded-full object-cover ring-1 ring-gray-950/5 dark:ring-white/10">
                                <div class="min-w-0 flex-1">
                                    <div class="rounded-2xl bg-gray-100 px-3 py-2 dark:bg-white/5">
                                        <div class="text-sm font-medium text-gray-900 dark:text-white">{{ $comment->user?->name ?? __('moment::admin.user') }}</div>
                                        <div class="whitespace-pre-line text-sm text-gray-700 dark:text-gray-200">{{ $comment->comment }}</div>
                                    </div>
                                    <div class="px-3 pt-1 text-xs text-gray-400">{{ $comment->created_at?->diffForHumans() }}</div>
                                </div>
                            </div>
                        @empty
                            <div class="py-10 text-center text-sm text-gray-400">{{ __('moment::admin.no_comments') }}</div>
                        @endforelse
                    @endif
                </div>
            </div>
        </div>
    @endif
</x-filament-panels::page>
