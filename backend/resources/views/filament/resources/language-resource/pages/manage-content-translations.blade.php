<x-filament-panels::page>
    @php
        $sources = app(\App\Services\TranslatableContentRegistry::class)->all();
        $activeSource = $this->activeSource;
        $pageUrl = url('/admin/languages/' . $record->id . '/content-translations');
    @endphp

    {{-- Language badge --}}
    <div class="mb-5 flex flex-wrap items-center gap-3">
        <x-filament::badge :color="$record->is_rtl ? 'warning' : 'success'" size="lg">
            {{ $record->code }} — {{ $record->native_name }}
        </x-filament::badge>
        <span class="text-sm text-gray-500 dark:text-gray-400">
            {{ __('admin.content_translations') }}
        </span>
    </div>

    {{-- Source tabs (one per registered translatable-content source) --}}
    @if(count($sources) > 1)
        <div class="mb-5">
            <div class="inline-flex gap-1 p-1 bg-gray-100 dark:bg-gray-800 rounded-xl">
                @foreach($sources as $key => $src)
                    <a href="{{ $pageUrl }}?source={{ $key }}&page=1"
                        class="flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all
                            {{ $activeSource === $key ? 'bg-white dark:bg-gray-700 text-blue-700 dark:text-blue-300 shadow-sm' : 'text-gray-500 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200' }}">
                        {{ $src->label() }}
                    </a>
                @endforeach
            </div>
        </div>
    @endif

    {{-- Filament table — pagination is INSIDE this component --}}
    {{ $this->table }}
</x-filament-panels::page>
