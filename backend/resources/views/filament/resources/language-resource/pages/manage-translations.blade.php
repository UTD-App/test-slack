<x-filament-panels::page>
    @php
        // Active tab comes from the Livewire #[Url] property (survives pagination/
        // search/poll), NOT request()->query() which is empty on AJAX requests.
        $activeTab   = $this->activeTab ?? 'admin';
        $adminGroups = ['admin', 'dashboard', 'auth', 'validation', 'passwords', 'pagination'];

        // Counts come from the LANG FILES (the source of truth for UI strings),
        // not the legacy `translations` DB table which no longer reflects them.
        $loader      = app(\App\Services\TranslationLoader::class);
        $fileVals    = $loader->scanLangFiles($record->code);
        $keysByGroup = \App\Models\TranslationKey::pluck('group', 'key'); // key => group
        $isFilled    = fn ($k) => isset($fileVals[$k]) && $fileVals[$k] !== '';

        $totalKeys       = $keysByGroup->count();
        $translatedCount = $keysByGroup->keys()->filter(fn ($k) => $isFilled($k))->count();
        $untranslated    = $totalKeys - $translatedCount;
        $progress        = $totalKeys > 0 ? round(($translatedCount / $totalKeys) * 100) : 0;

        $adminUntrans = $keysByGroup->filter(fn ($g, $k) => in_array($g, $adminGroups) && ! $isFilled($k))->count();
        $appUntrans   = $keysByGroup->filter(fn ($g, $k) => ! in_array($g, $adminGroups) && ! $isFilled($k))->count();
    @endphp

    {{-- Stats --}}
    <div class="mb-5 flex flex-wrap items-center gap-3">
        <x-filament::badge :color="$record->is_rtl ? 'warning' : 'success'" size="lg">
            {{ $record->code }} — {{ $record->native_name }}
        </x-filament::badge>
        <div class="flex items-center gap-2 bg-gray-50 dark:bg-gray-800 px-3 py-1.5 rounded-xl border border-gray-200 dark:border-gray-700">
            <div class="w-24 h-2 bg-gray-200 dark:bg-gray-700 rounded-full overflow-hidden">
                <div class="h-full rounded-full {{ $progress >= 80 ? 'bg-green-500' : ($progress >= 50 ? 'bg-yellow-500' : 'bg-red-500') }}"
                    style="width: {{ $progress }}%"></div>
            </div>
            <span class="text-sm font-bold {{ $progress >= 80 ? 'text-green-600' : ($progress >= 50 ? 'text-yellow-600' : 'text-red-600') }}">{{ $progress }}%</span>
        </div>
        @if($untranslated > 0)
            <span class="px-3 py-1.5 rounded-xl text-sm font-medium bg-red-50 text-red-700 dark:bg-red-900/20 dark:text-red-400 border border-red-200 dark:border-red-800">
                ⚠ {{ __('admin.untranslated_count', ['count' => $untranslated]) }}
            </span>
        @else
            <span class="px-3 py-1.5 rounded-xl text-sm font-medium bg-green-50 text-green-700 dark:bg-green-900/20 dark:text-green-400 border border-green-200 dark:border-green-800">
                ✓ {{ __('admin.complete') }}
            </span>
        @endif
    </div>

    {{-- Tabs (switch via Livewire so the table keeps its tab on pagination/search) --}}
    <div class="mb-5">
        <div class="inline-flex gap-1 p-1 bg-gray-100 dark:bg-gray-800 rounded-xl">
            @foreach(['admin' => ['icon' => '🖥', 'label' => __('admin.tab_dashboard'), 'count' => $adminUntrans], 'app' => ['icon' => '📱', 'label' => __('admin.tab_app'), 'count' => $appUntrans]] as $key => $tab)
                <button type="button" wire:click="$set('activeTab', '{{ $key }}')"
                    class="relative flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all
                        {{ $activeTab === $key ? 'bg-white dark:bg-gray-700 text-blue-700 dark:text-blue-300 shadow-sm' : 'text-gray-500 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200' }}">
                    <span>{{ $tab['icon'] }}</span><span>{{ $tab['label'] }}</span>
                    @if($tab['count'] > 0)
                        <span class="ms-0.5 inline-flex h-5 min-w-5 items-center justify-center rounded-full px-1 text-xs font-bold"
                              style="background-color:#ef4444;color:#ffffff;">{{ $tab['count'] > 99 ? '99+' : $tab['count'] }}</span>
                    @endif
                </button>
            @endforeach
        </div>
    </div>

    {{-- Filament table — pagination is INSIDE this component --}}
    {{ $this->table }}
</x-filament-panels::page>
