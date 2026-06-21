@props([
    'currentPageOptionProperty' => 'tableRecordsPerPage',
    'extremeLinks' => false,
    'paginator',
    'pageOptions' => [],
])

@php
    use Illuminate\Contracts\Pagination\CursorPaginator;
    use Illuminate\Pagination\LengthAwarePaginator;

    $isRtl    = __('filament-panels::layout.direction') === 'rtl';
    $isSimple = ! $paginator instanceof LengthAwarePaginator;
    $cur      = $paginator->currentPage();
    $last     = $isSimple ? null : $paginator->lastPage();

    // Build compact page window: first 2, ±2 around current, last 2
    $pages = collect();
    if (! $isSimple && $last) {
        $pages->push(1);
        if ($last > 1) $pages->push(2);
        for ($i = max(3, $cur - 2); $i <= min($last - 2, $cur + 2); $i++) {
            $pages->push($i);
        }
        if ($last > 3) $pages->push($last - 1);
        if ($last > 2) $pages->push($last);
        $pages = $pages->unique()->filter(fn($p) => $p >= 1 && $p <= $last)->sort()->values();
    }

    $prevClick = null;
    $nextClick = null;
    if (! $paginator->onFirstPage()) {
        $prevClick = $paginator instanceof CursorPaginator
            ? "setPage('{$paginator->previousCursor()->encode()}', '{$paginator->getCursorName()}')"
            : "previousPage('{$paginator->getPageName()}')";
    }
    if ($paginator->hasMorePages()) {
        $nextClick = $paginator instanceof CursorPaginator
            ? "setPage('{$paginator->nextCursor()->encode()}', '{$paginator->getCursorName()}')"
            : "nextPage('{$paginator->getPageName()}')";
    }
@endphp

{{-- Single row: [‹] [1][2]...[n] [›]  [per-page] --}}
<div {{ $attributes->class(['fi-pagination flex items-center gap-2 flex-nowrap min-w-0']) }}>

    {{-- Prev arrow --}}
    @if ($prevClick)
        <button wire:click="{{ $prevClick }}"
            class="fi-pagination-item shrink-0 flex h-8 w-8 items-center justify-center rounded-lg text-gray-500 hover:bg-gray-100 dark:hover:bg-white/10 transition-colors">
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="{{ $isRtl ? 'M9 5l7 7-7 7' : 'M15 19l-7-7 7-7' }}" />
            </svg>
        </button>
    @else
        <div class="shrink-0 h-8 w-8"></div>
    @endif

    {{-- Page numbers --}}
    @if ($pages->count() > 0 && ! $isSimple && $paginator->hasPages())
        <ol class="fi-pagination-items flex items-center rounded-lg bg-white shadow-sm ring-1 ring-gray-950/10 dark:bg-white/5 dark:ring-white/20 min-w-0 overflow-hidden">
            @php $prev = null; @endphp
            @foreach ($pages as $p)
                @if ($prev !== null && $p - $prev > 1)
                    <x-filament::pagination.item disabled label="…" />
                @endif
                <x-filament::pagination.item
                    :active="$p === $cur"
                    :label="$p"
                    :wire:click="'gotoPage(' . $p . ', \'' . $paginator->getPageName() . '\')'"
                    :wire:key="$this->getId() . '.pagination.' . $paginator->getPageName() . '.' . $p" />
                @php $prev = $p; @endphp
            @endforeach
        </ol>
    @elseif (! $isSimple)
        <span class="text-sm text-gray-500 dark:text-gray-400 shrink-0">
            {{ \Illuminate\Support\Number::format($paginator->firstItem() ?? 0) }}–{{ \Illuminate\Support\Number::format($paginator->lastItem() ?? 0) }}
            / {{ \Illuminate\Support\Number::format($paginator->total()) }}
        </span>
    @endif

    {{-- Spacer --}}
    <div class="flex-1"></div>

    {{-- Next arrow --}}
    @if ($nextClick)
        <button wire:click="{{ $nextClick }}"
            class="fi-pagination-item shrink-0 flex h-8 w-8 items-center justify-center rounded-lg text-gray-500 hover:bg-gray-100 dark:hover:bg-white/10 transition-colors">
            <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="{{ $isRtl ? 'M15 19l-7-7 7-7' : 'M9 5l7 7-7 7' }}" />
            </svg>
        </button>
    @else
        <div class="shrink-0 h-8 w-8"></div>
    @endif

    {{-- Per-page — Alpine.js custom dropdown, no native select, no blur issues --}}
    @if (count($pageOptions) > 1)
        @php
            $currentUrl     = url()->current();
            $currentPerPage = (int) request()->query($currentPageOptionProperty, $pageOptions[0]);
        @endphp
        <div class="fi-pagination-records-per-page-select shrink-0 flex items-center gap-1.5"
            x-data="{ open: false }"
            @click.outside="open = false">

            <span class="text-sm text-gray-500 dark:text-gray-400">
                {{ __('filament::components/pagination.fields.records_per_page.label') }}
            </span>

            <div class="relative">
                <button type="button"
                    x-ref="perPageBtn"
                    @click.stop="open = !open"
                    class="inline-flex items-center gap-1.5 rounded-lg border border-gray-300 dark:border-gray-600
                           bg-white dark:bg-gray-800 px-2.5 py-1 text-sm font-medium text-gray-700 dark:text-gray-300
                           hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors shadow-sm">
                    <span>{{ $currentPerPage === 0 ? __('filament::components/pagination.fields.records_per_page.options.all') : $currentPerPage }}</span>
                    <svg class="h-3.5 w-3.5 text-gray-400" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                        <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
                    </svg>
                </button>

                <template x-teleport="body">
                <div x-show="open"
                    x-transition:enter="transition ease-out duration-100"
                    x-transition:enter-start="opacity-0 scale-95"
                    x-transition:enter-end="opacity-100 scale-100"
                    x-transition:leave="transition ease-in duration-75"
                    x-transition:leave-start="opacity-100 scale-100"
                    x-transition:leave-end="opacity-0 scale-95"
                    x-anchor.bottom-end.offset.5="$refs.perPageBtn"
                    @click.outside="open = false"
                    class="z-50 min-w-[80px] rounded-xl bg-white dark:bg-gray-800
                           shadow-lg ring-1 ring-gray-200 dark:ring-gray-700 py-1 overflow-hidden">
                    @foreach ($pageOptions as $option)
                        @php $isAll = $option === 'all'; $label = $isAll ? __('filament::components/pagination.fields.records_per_page.options.all') : $option; @endphp
                        <a href="{{ $currentUrl }}?{{ http_build_query(array_merge(request()->query(), [$currentPageOptionProperty => $option, 'page' => 1])) }}"
                            @click="open = false"
                            class="flex items-center justify-between px-3 py-1.5 text-sm transition-colors cursor-pointer
                                {{ ($isAll ? 0 : (int)$option) === $currentPerPage
                                    ? 'bg-primary-50 dark:bg-primary-900/20 text-primary-700 dark:text-primary-300 font-semibold'
                                    : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700' }}">
                            {{ $label }}
                            @if(($isAll ? 0 : (int)$option) === $currentPerPage)
                                <svg class="h-3.5 w-3.5 text-primary-600" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor">
                                    <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                                </svg>
                            @endif
                        </a>
                    @endforeach
                </div>
                </template>
            </div>
        </div>
    @endif
</div>
