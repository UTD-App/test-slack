{{--
  Two "this month" summary cards shown ABOVE the gifts-received / gifts-sent
  table on a user's admin profile. Inline styles only — Filament purges Tailwind
  for package blades. Values are pre-computed (one bounded aggregate query) in the
  RelationManager, so this stays cheap even for whales.
--}}
<div style="display:grid;grid-template-columns:1fr 1fr;gap:.75rem;margin:0 0 1rem;">
    <div style="display:flex;align-items:center;gap:.85rem;padding:1rem 1.15rem;border-radius:1rem;
                background:linear-gradient(135deg,#6d28d9,#9333ea);color:#fff;box-shadow:0 6px 18px rgba(109,40,217,.25);">
        <div style="font-size:1.7rem;line-height:1;">🎁</div>
        <div style="min-width:0;">
            <div style="font-size:.78rem;opacity:.9;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ $giftsLabel }}</div>
            <div style="font-size:1.65rem;font-weight:800;line-height:1.1;">{{ $giftsValue }}</div>
        </div>
    </div>

    <div style="display:flex;align-items:center;gap:.85rem;padding:1rem 1.15rem;border-radius:1rem;
                background:linear-gradient(135deg,#d97706,#f59e0b);color:#fff;box-shadow:0 6px 18px rgba(217,119,6,.25);">
        <div style="font-size:1.7rem;line-height:1;">🪙</div>
        <div style="min-width:0;">
            <div style="font-size:.78rem;opacity:.9;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">{{ $coinsLabel }}</div>
            <div style="font-size:1.65rem;font-weight:800;line-height:1.1;">{{ $coinsValue }}</div>
        </div>
    </div>
</div>
