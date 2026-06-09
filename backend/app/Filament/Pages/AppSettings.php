<?php

namespace App\Filament\Pages;

use App\Models\Config;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

class AppSettings extends Page
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-cog-6-tooth';
    protected static ?string $navigationLabel = null;
    protected static ?int $navigationSort = 10;
    protected static string $view = 'filament.pages.app-settings';

    public static function getNavigationLabel(): string
    {
        return __('admin.nav_settings');
    }

    public static function canAccess(): bool
    {
        return filament()->auth()->user()?->hasAnyRole(['super_admin', 'settings_manager']) ?? false;
    }

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'app_name'        => $this->getSetting('app_name', config('app.name')),
            'app_description' => $this->getSetting('app_description'),
            'app_logo'        => $this->getSetting('app_logo'),
            'support_email'   => $this->getSetting('support_email'),
            'support_phone'   => $this->getSetting('support_phone'),
            'privacy_url'     => $this->getSetting('privacy_url'),
            'terms_url'       => $this->getSetting('terms_url'),
            // Firebase
            'firebase_server_key'  => $this->getSetting('firebase_server_key'),
            'firebase_project_id'  => $this->getSetting('firebase_project_id'),
            // Storage
            'storage_driver'       => $this->getSetting('storage_driver', 'local'),
            'storage_endpoint'     => $this->getSetting('storage_endpoint'),
            'storage_bucket'       => $this->getSetting('storage_bucket'),
            'storage_key'          => $this->getSetting('storage_key'),
            'storage_secret'       => $this->getSetting('storage_secret'),
            'storage_region'       => $this->getSetting('storage_region'),
            // Stac
            'utd_stac_key'         => $this->getSetting('utd_stac_key'),
            'utd_secret'           => $this->getSetting('utd_secret'),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form->schema([

            Section::make(__('admin.general'))->schema([
                TextInput::make('app_name')->label(__('admin.app_name'))->required(),
                Textarea::make('app_description')->label(__('admin.app_description'))->rows(3),
                FileUpload::make('app_logo')
                    ->label(__('admin.app_logo'))
                    ->image()
                    ->directory('settings'),
                TextInput::make('support_email')->label(__('admin.support_email'))->email(),
                TextInput::make('support_phone')->label(__('admin.support_phone')),
                TextInput::make('privacy_url')->label(__('admin.privacy_url'))->url(),
                TextInput::make('terms_url')->label(__('admin.terms_url'))->url(),
            ])->columns(2),

            Section::make(__('admin.firebase_section'))->schema([
                TextInput::make('firebase_server_key')
                    ->label(__('admin.firebase_server_key'))
                    ->password()->revealable(),
                TextInput::make('firebase_project_id')
                    ->label(__('admin.firebase_project_id')),
            ])->columns(2),

            Section::make(__('admin.stac_section'))->description(__('admin.stac_section_hint'))->schema([
                TextInput::make('utd_stac_key')
                    ->label(__('admin.stac_key'))
                    ->helperText(__('admin.stac_key_hint'))
                    ->password()
                    ->revealable(),
                TextInput::make('utd_secret')
                    ->label('UTD Manifest Secret')
                    ->helperText('مفتاح القراءة (X-UTD-Secret) اللي UTD Studio بيكتشف بيه الـ packages. يتولّد من UTD Studio.')
                    ->password()
                    ->revealable(),
            ])->columns(2),

            Section::make(__('admin.storage_section'))->description(__('admin.storage_section'))->schema([
                TextInput::make('storage_driver')
                    ->label(__('admin.storage_driver'))
                    ->placeholder('local'),
                TextInput::make('storage_endpoint')
                    ->label(__('admin.storage_endpoint'))
                    ->placeholder('https://s3.amazonaws.com or R2/DO endpoint'),
                TextInput::make('storage_bucket')->label(__('admin.storage_bucket')),
                TextInput::make('storage_key')->label(__('admin.storage_key'))->password()->revealable(),
                TextInput::make('storage_secret')->label(__('admin.storage_secret'))->password()->revealable(),
                TextInput::make('storage_region')->label(__('admin.storage_region'))->placeholder('us-east-1'),
            ])->columns(2),

        ])->statePath('data');
    }

    public function save(): void
    {
        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            Config::updateOrCreate(
                ['name' => $key],
                ['value' => $value]
            );
        }

        Notification::make()
            ->title(__('admin.settings_saved'))
            ->success()
            ->send();
    }

    private function getSetting(string $key, mixed $default = null): mixed
    {
        return Config::where('name', $key)->value('value') ?? $default;
    }
}
