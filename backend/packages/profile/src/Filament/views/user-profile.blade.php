@php
    use Utd\Profile\Filament\ProfileInfolist;

    /** @var array $d */
    $d = $getState() ?? [];
    $genderLabel = [1 => '♂', 2 => '♀'][$d['gender'] ?? 0] ?? null;
    $hasLevels = !empty($d['levels']['sender']) || !empty($d['levels']['receiver']);
@endphp

<style>
    .up-wrap{display:flex;flex-direction:column;gap:16px;font-family:ui-sans-serif,system-ui,-apple-system,sans-serif;}
    .up-hd{position:relative;overflow:hidden;border-radius:18px;padding:24px;color:#fff;
        background:linear-gradient(135deg,#6d5efc 0%,#4338ca 55%,#3730a3 100%);box-shadow:0 10px 30px rgba(67,56,202,.28);}
    .up-hd::after{content:"";position:absolute;top:-60px;inset-inline-end:-40px;width:200px;height:200px;border-radius:50%;background:rgba(255,255,255,.10);}
    .up-hd-row{position:relative;display:flex;align-items:center;gap:20px;flex-wrap:wrap;}
    .up-ava{width:104px;height:104px;border-radius:50%;object-fit:cover;flex:0 0 auto;
        border:4px solid rgba(255,255,255,.5);box-shadow:0 6px 18px rgba(0,0,0,.20);background:rgba(255,255,255,.15);}
    .up-ava-ph{display:flex;align-items:center;justify-content:center;font-size:42px;}
    .up-id{flex:1 1 240px;min-width:0;}
    .up-name{font-size:24px;font-weight:800;line-height:1.15;display:flex;flex-wrap:wrap;align-items:center;gap:8px;}
    .up-flag{width:24px;height:16px;border-radius:3px;object-fit:cover;}
    .up-chips{display:flex;flex-wrap:wrap;gap:8px;align-items:center;margin-top:10px;}
    .up-chip{background:rgba(255,255,255,.18);border-radius:999px;padding:4px 11px;font-size:12px;font-weight:600;display:inline-flex;align-items:center;gap:5px;}
    .up-lv{background:rgba(255,255,255,.22);border-radius:999px;padding:4px 11px;font-size:12px;font-weight:700;display:inline-flex;align-items:center;gap:5px;}
    .up-lv img{width:16px;height:16px;}
    .up-bio{position:relative;margin:14px 0 0;font-size:14px;line-height:1.5;color:rgba(255,255,255,.92);max-width:680px;}

    .up-covers{display:flex;gap:10px;overflow-x:auto;padding-bottom:4px;}
    .up-covers img{height:130px;border-radius:14px;object-fit:cover;flex:0 0 auto;
        border:1px solid #e7e8ee;box-shadow:0 4px 12px rgba(16,24,40,.08);}

    .up-stats{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;}
    .up-two{display:grid;grid-template-columns:1fr 1fr;gap:16px;align-items:start;}
    .up-two.one{grid-template-columns:1fr;}
    .up-card{background:#fff;border:1px solid #edeef2;border-radius:16px;box-shadow:0 1px 3px rgba(16,24,40,.05);}
    .up-stat{padding:16px;text-align:center;}
    .up-stat-n{font-size:22px;font-weight:800;color:#111827;}
    .up-stat-l{font-size:12px;color:#6b7280;margin-top:2px;}

    .up-sec{padding:18px 20px;}
    .up-sec-t{font-size:14px;font-weight:700;color:#111827;margin:0 0 16px;display:flex;align-items:center;gap:8px;}
    .up-count{margin-inline-start:auto;font-size:13px;font-weight:700;color:#4f46e5;}

    .up-strip{display:flex;gap:18px;overflow-x:auto;padding-bottom:6px;}
    .up-person{width:68px;flex:0 0 auto;text-align:center;text-decoration:none;}
    .up-person img{width:58px;height:58px;border-radius:50%;object-fit:cover;border:2px solid #e7e8ee;transition:border-color .15s;}
    .up-person:hover img{border-color:#6366f1;}
    .up-person .v{font-size:12px;font-weight:800;color:#4f46e5;margin-top:5px;}
    .up-person .n{font-size:11px;color:#6b7280;margin-top:1px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}

    .up-gifts{display:flex;flex-wrap:wrap;gap:14px;}
    .up-gift{width:58px;text-align:center;}
    .up-gift .b{width:54px;height:54px;border-radius:13px;background:#f4f4f7;display:flex;align-items:center;justify-content:center;margin:0 auto;font-size:24px;}
    .up-gift img{width:44px;height:44px;object-fit:contain;}
    .up-gift .q{font-size:12px;color:#6b7280;margin-top:5px;font-weight:600;}

    .up-info{display:grid;grid-template-columns:repeat(2,1fr);gap:18px;}
    .up-info dt{font-size:11px;color:#9ca3af;text-transform:uppercase;letter-spacing:.03em;}
    .up-info dd{font-size:14px;font-weight:600;color:#111827;margin:3px 0 0;word-break:break-word;}
    .up-badge{display:inline-flex;padding:2px 11px;border-radius:999px;font-size:12px;font-weight:700;}
    .up-badge.ok{background:#dcfce7;color:#15803d;}
    .up-badge.no{background:#fee2e2;color:#b91c1c;}

    @media(max-width:760px){.up-stats{grid-template-columns:repeat(2,1fr);}.up-two{grid-template-columns:1fr;}.up-info{grid-template-columns:1fr;}}
</style>

<div class="up-wrap">

    {{-- Cover images (swipeable banner on the app; thumbnail strip here) --}}
    @if (!empty($d['covers']))
        <div class="up-covers">
            @foreach ($d['covers'] as $cover)
                <img src="{{ $cover }}" alt="" loading="lazy">
            @endforeach
        </div>
    @endif

    {{-- Header --}}
    <div class="up-hd">
        <div class="up-hd-row">
            @if (!empty($d['avatar']))
                <img class="up-ava" src="{{ $d['avatar'] }}" alt=""
                     onerror="this.onerror=null;this.src='https://ui-avatars.com/api/?background=ffffff&color=4338ca&name={{ urlencode($d['name'] ?? 'U') }}';">
            @else
                <div class="up-ava up-ava-ph">👤</div>
            @endif

            <div class="up-id">
                <div class="up-name">
                    <span>{{ $d['name'] ?? '—' }}</span>
                    @if ($genderLabel)<span class="up-chip">{{ $genderLabel }}</span>@endif
                    @if (!empty($d['flag']))<img class="up-flag" src="{{ $d['flag'] }}" alt="">@endif
                </div>
                <div class="up-chips">
                    <span class="up-chip">🆔 {{ $d['uuid'] ?? '—' }}</span>
                    @if (!empty($d['country']))<span class="up-chip">📍 {{ $d['country'] }}</span>@endif
                    @if (!empty($d['online']))<span class="up-chip">🕓 {{ $d['online'] }}</span>@endif
                </div>
                @if ($hasLevels)
                    <div class="up-chips">
                        @if (!empty($d['levels']['sender']))
                            <span class="up-lv">@if(!empty($d['levels']['sender_img']))<img src="{{ $d['levels']['sender_img'] }}">@endif LV.{{ $d['levels']['sender'] }}</span>
                        @endif
                        @if (!empty($d['levels']['receiver']))
                            <span class="up-lv">@if(!empty($d['levels']['receiver_img']))<img src="{{ $d['levels']['receiver_img'] }}">@endif LV.{{ $d['levels']['receiver'] }}</span>
                        @endif
                    </div>
                @endif
                @if (!empty($d['bio']))<p class="up-bio">{{ $d['bio'] }}</p>@endif
            </div>
        </div>
    </div>

    {{-- Stats --}}
    <div class="up-stats">
        @foreach (($d['stats'] ?? []) as $stat)
            <div class="up-card up-stat">
                <div class="up-stat-n">{{ ProfileInfolist::fmt($stat['value']) }}</div>
                <div class="up-stat-l">{{ __('profile::profile.' . $stat['label']) }}</div>
            </div>
        @endforeach
    </div>

    {{-- Account info (first) + Top supporters, side by side --}}
    <div class="up-two @if (empty($d['supporters'])) one @endif">
        {{-- Account info --}}
        <div class="up-card up-sec">
            <h3 class="up-sec-t">{{ __('admin.account_info') }}</h3>
            <dl class="up-info">
                <div><dt>{{ __('admin.email') }}</dt><dd>{{ $d['email'] ?: '—' }}</dd></div>
                <div><dt>{{ __('admin.phone') }}</dt><dd>{{ $d['phone'] ?: '—' }}</dd></div>
                <div><dt>{{ __('admin.birthday') }}</dt><dd>{{ $d['birthday'] ?: '—' }}</dd></div>
                <div><dt>{{ __('admin.joined') }}</dt><dd>{{ $d['joined'] ?: '—' }}</dd></div>
                <div><dt>{{ __('admin.status') }}</dt><dd>
                    <span class="up-badge {{ ($d['status'] ?? false) ? 'ok' : 'no' }}">{{ ($d['status'] ?? false) ? __('admin.active') : __('admin.banned') }}</span>
                </dd></div>
            </dl>
        </div>

        {{-- Top supporters --}}
        @if (!empty($d['supporters']))
            <div class="up-card up-sec">
                <h3 class="up-sec-t">❤️ {{ __('profile::profile.top_supporters') }}</h3>
                <div class="up-strip">
                    @foreach ($d['supporters'] as $s)
                        <a class="up-person" href="{{ $s['url'] ?? '#' }}">
                            <img src="{{ $s['avatar'] }}" onerror="this.onerror=null;this.src='https://ui-avatars.com/api/?background=eef&color=4338ca&name={{ urlencode($s['name'] ?? 'U') }}';">
                            <div class="v">{{ ProfileInfolist::fmt($s['total'] ?? 0) }}</div>
                            <div class="n">{{ $s['name'] }}</div>
                        </a>
                    @endforeach
                </div>
            </div>
        @endif
    </div>

    {{-- Friends --}}
    @if (!empty($d['friends']))
        <div class="up-card up-sec">
            <h3 class="up-sec-t">👥 {{ __('profile::profile.friends') }}</h3>
            <div class="up-strip">
                @foreach ($d['friends'] as $f)
                    <a class="up-person" href="{{ $f['url'] ?? '#' }}">
                        <img src="{{ $f['avatar'] }}" onerror="this.onerror=null;this.src='https://ui-avatars.com/api/?background=eef&color=4338ca&name={{ urlencode($f['name'] ?? 'U') }}';">
                        <div class="n">{{ $f['name'] }}</div>
                    </a>
                @endforeach
            </div>
        </div>
    @endif

</div>
