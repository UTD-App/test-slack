@php
    $name = $getDisplayName();
    $uid = $getUid();
    $uidDisplay = $getUidDisplay();
    $avatar = $getAvatarUrl();
    $copyMessage = $getCopyMessage();
@endphp

<div class="fi-ta-user flex items-center gap-3 py-1">
    <img
        src="{{ $avatar }}"
        alt="{{ $name }}"
        loading="lazy"
        class="h-9 w-9 shrink-0 rounded-full object-cover ring-1 ring-gray-950/10 dark:ring-white/20"
    />

    <div class="flex min-w-0 flex-col leading-tight">
        <span class="truncate text-sm font-semibold text-gray-950 dark:text-white">
            {{ $name }}
        </span>

        @if (filled($uid))
            <span
                role="button"
                title="{{ $copyMessage }}"
                class="inline-flex w-max cursor-pointer items-center gap-1 text-xs text-gray-500 transition hover:text-primary-600 dark:text-gray-400 dark:hover:text-primary-400"
                x-on:click.stop="
                    window.navigator.clipboard.writeText(@js($uid))
                    $tooltip(@js($copyMessage), { theme: $store.theme, timeout: 1500 })
                "
            >
                <span class="font-mono">UID: {{ $uidDisplay }}</span>
                @svg('heroicon-m-clipboard-document', 'h-3.5 w-3.5 shrink-0')
            </span>
        @endif
    </div>
</div>
