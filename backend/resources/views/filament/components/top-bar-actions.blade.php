@php
    $languages     = \App\Models\Language::where('is_active', true)->get();
    $currentLocale = app()->getLocale();
    $pageUrl       = url()->current();
@endphp

<div class="flex items-center gap-0.5"
    x-data="{
        langOpen: false,
        fullscreen: false,
        init() {
            // Restore fullscreen from storage
            if (localStorage.getItem('admin_fullscreen') === '1') {
                document.documentElement.requestFullscreen?.().catch(() => {});
                this.fullscreen = true;
            }
            document.addEventListener('fullscreenchange', () => {
                this.fullscreen = !!document.fullscreenElement;
                localStorage.setItem('admin_fullscreen', this.fullscreen ? '1' : '0');
            });
        }
    }"
    @click.outside="langOpen = false">

    {{-- Notifications --}}
    <button title="Notifications"
        class="p-2 rounded-lg text-gray-500 hover:text-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-400 transition-colors">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0" />
        </svg>
    </button>

    {{-- Dark / Light mode — uses Filament's built-in Alpine store --}}
    <button
        x-data
        title="Toggle dark mode"
        @click="
            const html = document.documentElement;
            const isDark = html.classList.toggle('dark');
            localStorage.setItem('theme', isDark ? 'dark' : 'light');
        "
        class="p-2 rounded-lg text-gray-500 hover:text-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-400 transition-colors">
        {{-- Moon --}}
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 hidden dark:block" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z" />
        </svg>
        {{-- Sun --}}
        <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5 block dark:hidden" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z" />
        </svg>
    </button>

    {{-- Language --}}
    <div class="relative">
        <button @click="langOpen = !langOpen" title="Language"
            class="flex items-center gap-1 p-2 rounded-lg text-gray-500 hover:text-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-400 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" d="m10.5 21 5.25-11.25L21 21m-9-3h7.5M3 5.621a48.474 48.474 0 0 1 6-.371m0 0c1.12 0 2.233.038 3.334.114M9 5.25V3m3.334 2.364C11.176 10.658 7.69 15.08 3 17.502m9.334-12.138c.896.061 1.785.147 2.666.257m-4.589 8.495a18.023 18.023 0 0 1-3.827-5.802" />
            </svg>
            <span class="text-xs font-semibold uppercase">{{ $currentLocale }}</span>
        </button>

        <div x-show="langOpen"
            x-transition:enter="transition ease-out duration-100"
            x-transition:enter-start="opacity-0 scale-95"
            x-transition:enter-end="opacity-100 scale-100"
            x-transition:leave="transition ease-in duration-75"
            x-transition:leave-start="opacity-100 scale-100"
            x-transition:leave-end="opacity-0 scale-95"
            class="absolute {{ $currentLocale === 'ar' ? 'left-0' : 'right-0' }} top-11 z-50
                   w-44 rounded-xl bg-white dark:bg-gray-800 shadow-lg ring-1 ring-gray-200 dark:ring-gray-700 py-1">
            @foreach($languages as $lang)
                <a href="/admin/locale/{{ $lang->code }}"
                    class="flex items-center gap-2.5 px-4 py-2 text-sm transition-colors
                        {{ $currentLocale === $lang->code
                            ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-700 dark:text-blue-300 font-semibold'
                            : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700' }}">
                    <span class="text-base">{{ $lang->is_rtl ? '🔤' : '🔡' }}</span>
                    <span>{{ $lang->native_name }}</span>
                    @if($currentLocale === $lang->code)
                        <svg class="ms-auto w-4 h-4 text-blue-600" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor">
                            <path stroke-linecap="round" stroke-linejoin="round" d="m4.5 12.75 6 6 9-13.5" />
                        </svg>
                    @endif
                </a>
            @endforeach
        </div>
    </div>

    {{-- Fullscreen --}}
    <button @click="
            fullscreen = !fullscreen;
            fullscreen ? document.documentElement.requestFullscreen() : document.exitFullscreen();
        "
        title="Fullscreen"
        class="p-2 rounded-lg text-gray-500 hover:text-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 dark:text-gray-400 transition-colors">
        <svg x-show="!fullscreen" xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9M3.75 20.25v-4.5m0 4.5h4.5m-4.5 0L9 15M20.25 3.75h-4.5m4.5 0v4.5m0-4.5L15 9m5.25 11.25h-4.5m4.5 0v-4.5m0 4.5L15 15" />
        </svg>
        <svg x-show="fullscreen" xmlns="http://www.w3.org/2000/svg" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 9V4.5M9 9H4.5M9 9 3.75 3.75M9 15v4.5M9 15H4.5M9 15l-5.25 5.25M15 9h4.5M15 9V4.5M15 9l5.25-5.25M15 15h4.5M15 15v4.5m0-4.5 5.25 5.25" />
        </svg>
    </button>
</div>

{{-- Apply saved dark mode on load --}}
<script>
    (function() {
        const saved = localStorage.getItem('theme');
        if (saved === 'dark') document.documentElement.classList.add('dark');
        else if (saved === 'light') document.documentElement.classList.remove('dark');
    })();
</script>
