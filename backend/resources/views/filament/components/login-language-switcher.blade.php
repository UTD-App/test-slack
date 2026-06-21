@php
    // Active languages drive the toggle (falls back to en/ar before the table is
    // seeded). Clicking a link reloads the login page with ?lang=<code>, which
    // SetAdminLocale captures into the session — so the guest sees the login form
    // in the chosen language (and RTL for Arabic) before signing in.
    $current = app()->getLocale();

    try {
        $langs = \App\Models\Language::where('is_active', true)
            ->orderByDesc('is_default')
            ->get(['code', 'native_name', 'name']);
    } catch (\Throwable $e) {
        $langs = collect();
    }

    if ($langs->isEmpty()) {
        $langs = collect([
            (object) ['code' => 'en', 'native_name' => 'English', 'name' => 'English'],
            (object) ['code' => 'ar', 'native_name' => 'العربية', 'name' => 'Arabic'],
        ]);
    }
@endphp

<div class="mt-6 flex items-center justify-center gap-2 text-sm">
    @foreach ($langs as $i => $lang)
        @if ($i > 0)
            <span class="text-gray-300 dark:text-gray-600">|</span>
        @endif
        <a
            href="?lang={{ $lang->code }}"
            @class([
                'rounded-md px-2 py-1 transition-colors',
                'font-bold text-gray-900 underline dark:text-white' => $current === $lang->code,
                'text-gray-500 hover:text-gray-800 dark:text-gray-400 dark:hover:text-gray-200' => $current !== $lang->code,
            ])
        >
            {{ $lang->native_name ?: ($lang->name ?: strtoupper($lang->code)) }}
        </a>
    @endforeach
</div>
