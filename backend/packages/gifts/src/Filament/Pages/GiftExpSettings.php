<?php

namespace Utd\Gifts\Filament\Pages;

use App\Filament\Concerns\GatedByPackage;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Contracts\HasForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Utd\Gifts\Support\GiftSettings;

/**
 * Admin page to tune the EXP conversion rates that drive sender/receiver levels:
 *   exp_per_coin    — EXP a sender gains per 1 coin spent
 *   exp_per_diamond — EXP a receiver gains per 1 diamond earned
 * Values are stored in gift_settings via Support\GiftSettings (cached). Changes
 * apply to FUTURE gifts only — historical exp is already banked (see GiftUserExp).
 */
class GiftExpSettings extends Page implements HasForms
{
    use GatedByPackage;
    use InteractsWithForms;

    protected static ?string $packageSlug = 'gifts';

    protected static ?string $navigationIcon = 'heroicon-o-sparkles';

    protected static ?int $navigationSort = 5;

    protected static string $view = 'gifts::filament.pages.gift-exp-settings';

    public ?array $data = [];

    public static function getNavigationGroup(): ?string
    {
        return __('gifts::admin.nav_gifts_group');
    }

    public static function getNavigationLabel(): string
    {
        return __('gifts::admin.nav_exp_settings');
    }

    public function getTitle(): string
    {
        return __('gifts::admin.nav_exp_settings');
    }

    public static function canAccess(): bool
    {
        if (! static::packageIsEnabled()) {
            return false;
        }

        return filament()->auth()->user()?->hasAnyRole(['super_admin', 'user_manager']) ?? false;
    }

    public function mount(): void
    {
        $this->form->fill([
            'exp_per_coin'    => GiftSettings::float('exp_per_coin', 1.0),
            'exp_per_diamond' => GiftSettings::float('exp_per_diamond', 1.0),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form
            ->schema([
                Section::make(__('gifts::admin.exp_settings_section'))
                    ->description(__('gifts::admin.exp_settings_hint'))
                    ->schema([
                        TextInput::make('exp_per_coin')
                            ->label(__('gifts::admin.exp_per_coin'))
                            ->helperText(__('gifts::admin.exp_per_coin_hint'))
                            ->numeric()
                            ->minValue(0)
                            ->step('any')
                            ->required(),
                        TextInput::make('exp_per_diamond')
                            ->label(__('gifts::admin.exp_per_diamond'))
                            ->helperText(__('gifts::admin.exp_per_diamond_hint'))
                            ->numeric()
                            ->minValue(0)
                            ->step('any')
                            ->required(),
                    ])
                    ->columns(2),
            ])
            ->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        GiftSettings::set('exp_per_coin', (float) $data['exp_per_coin']);
        GiftSettings::set('exp_per_diamond', (float) $data['exp_per_diamond']);

        Notification::make()
            ->title(__('gifts::admin.settings_saved'))
            ->success()
            ->send();
    }
}
