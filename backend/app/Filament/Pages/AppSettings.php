<?php

namespace App\Filament\Pages;

use App\Models\Config;
use Filament\Forms\Components\Fieldset;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Tabs;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Form;
use Filament\Forms\Get;
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

    // The page title/heading is derived from the class name by default ("App
    // Settings") and ignores the locale — pin it to the translated nav label.
    public function getTitle(): string
    {
        return __('admin.nav_settings');
    }

    public static function canAccess(): bool
    {
        return filament()->auth()->user()?->can('settings.view') ?? false;
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
            // Firebase
            'firebase_server_key'  => $this->getSetting('firebase_server_key'),
            'firebase_project_id'  => $this->getSetting('firebase_project_id'),
            // Mail / SMTP (password-recovery OTP + transactional email)
            'mail_mailer'          => $this->getSetting('mail_mailer', 'smtp'),
            'mail_host'            => $this->getSetting('mail_host'),
            'mail_port'            => $this->getSetting('mail_port', '587'),
            'mail_encryption'      => $this->getSetting('mail_encryption', 'tls'),
            'mail_username'        => $this->getSetting('mail_username'),
            'mail_password'        => $this->getSetting('mail_password'),
            'mail_from_address'    => $this->getSetting('mail_from_address'),
            'mail_from_name'       => $this->getSetting('mail_from_name'),
            // Storage (GCS is the default provider)
            'storage_driver'       => $this->getSetting('storage_driver', 'gcs'),
            'storage_endpoint'     => $this->getSetting('storage_endpoint'),
            'storage_bucket'       => $this->getSetting('storage_bucket'),
            'storage_key'          => $this->getSetting('storage_key'),
            'storage_secret'       => $this->getSetting('storage_secret'),
            'storage_region'       => $this->getSetting('storage_region'),
            // GCS-specific (project id falls back to the Firebase one for existing setups)
            'storage_project_id'   => $this->getSetting('storage_project_id', $this->getSetting('firebase_project_id')),
            'storage_gcs_key_file' => $this->getSetting('storage_gcs_key_file'),
            // UTD Studio — both keys are copied FROM UTD Studio into this dashboard:
            // utd_secret (X-UTD-Secret) lets Studio READ the manifest; utd_stac_key
            // (X-Stac-Key) lets Studio PUSH the generated Stac screens.
            'utd_secret'           => $this->getSetting('utd_secret'),
            'utd_stac_key'         => $this->getSetting('utd_stac_key'),
            // Maintenance
            'maintenance_mode'     => (bool) $this->getSetting('maintenance_mode'),
            'maintenance_message'  => $this->getSetting('maintenance_message'),
            // App version & store links (per platform)
            'android_min_version'     => $this->getSetting('android_min_version'),
            'android_latest_version'  => $this->getSetting('android_latest_version'),
            'android_update_required' => (bool) $this->getSetting('android_update_required'),
            'android_store_url'       => $this->getSetting('android_store_url'),
            'ios_min_version'         => $this->getSetting('ios_min_version'),
            'ios_latest_version'      => $this->getSetting('ios_latest_version'),
            'ios_update_required'     => (bool) $this->getSetting('ios_update_required'),
            'ios_store_url'           => $this->getSetting('ios_store_url'),
            'huawei_min_version'      => $this->getSetting('huawei_min_version'),
            'huawei_latest_version'   => $this->getSetting('huawei_latest_version'),
            'huawei_update_required'  => (bool) $this->getSetting('huawei_update_required'),
            'huawei_store_url'        => $this->getSetting('huawei_store_url'),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form->schema([
            Tabs::make('settings')
                ->columnSpanFull()
                ->persistTabInQueryString()
                ->tabs([

                    Tabs\Tab::make(__('admin.general'))
                        ->icon('heroicon-o-information-circle')
                        ->schema([
                            TextInput::make('app_name')->label(__('admin.app_name'))->required(),
                            Textarea::make('app_description')->label(__('admin.app_description'))->rows(3),
                            FileUpload::make('app_logo')
                                ->label(__('admin.app_logo'))
                                ->image()
                                // The app logo is a small public branding asset — keep it on
                                // the local public disk (web-served via storage:link), NOT the
                                // app media disk which may be a read-only/unconfigured cloud
                                // bucket (GCS). Otherwise the field hangs on "awaiting size".
                                ->disk('public')
                                ->visibility('public')
                                ->directory('settings'),
                            TextInput::make('support_email')->label(__('admin.support_email'))->email(),
                            TextInput::make('support_phone')->label(__('admin.support_phone')),
                        ])->columns(2),

                    Tabs\Tab::make(__('admin.firebase_section'))
                        ->icon('heroicon-o-bell')
                        ->schema([
                            TextInput::make('firebase_server_key')
                                ->label(__('admin.firebase_server_key'))
                                ->password()->revealable(),
                            TextInput::make('firebase_project_id')
                                ->label(__('admin.firebase_project_id')),
                        ])->columns(2),

                    Tabs\Tab::make(__('admin.stac_section'))
                        ->icon('heroicon-o-paint-brush')
                        ->schema([
                            TextInput::make('utd_secret')
                                ->label(__('admin.manifest_secret'))
                                ->helperText(__('admin.manifest_secret_hint'))
                                ->password()
                                ->revealable(),
                            TextInput::make('utd_stac_key')
                                ->label(__('admin.stac_key'))
                                ->helperText(__('admin.stac_key_hint'))
                                ->password()
                                ->revealable(),
                        ])->columns(2),

                    Tabs\Tab::make(__('admin.mail_section'))
                        ->icon('heroicon-o-envelope')
                        ->schema([
                            Placeholder::make('mail_hint')
                                ->hiddenLabel()
                                ->content(__('admin.mail_section_hint'))
                                ->columnSpanFull(),
                            Select::make('mail_mailer')
                                ->label(__('admin.mail_mailer'))
                                ->options([
                                    'smtp' => 'SMTP',
                                    'log'  => __('admin.mail_mailer_log'),
                                ])
                                ->default('smtp')
                                ->native(false),
                            TextInput::make('mail_host')
                                ->label(__('admin.mail_host'))
                                ->placeholder('smtp.example.com'),
                            TextInput::make('mail_port')
                                ->label(__('admin.mail_port'))
                                ->numeric()
                                ->placeholder('465'),
                            Select::make('mail_encryption')
                                ->label(__('admin.mail_encryption'))
                                ->options([
                                    'ssl'  => 'SSL',
                                    'tls'  => 'TLS',
                                    'none' => __('admin.mail_encryption_none'),
                                ])
                                ->default('tls')
                                ->native(false),
                            TextInput::make('mail_username')
                                ->label(__('admin.mail_username')),
                            TextInput::make('mail_password')
                                ->label(__('admin.mail_password'))
                                ->password()
                                ->revealable(),
                            TextInput::make('mail_from_address')
                                ->label(__('admin.mail_from_address'))
                                ->email()
                                ->placeholder('noreply@example.com'),
                            TextInput::make('mail_from_name')
                                ->label(__('admin.mail_from_name')),
                        ])->columns(2),

                    Tabs\Tab::make(__('admin.storage_section'))
                        ->icon('heroicon-o-circle-stack')
                        ->schema([
                            // Provider picker — GCS is the default. Selecting a
                            // provider reveals only its relevant fields.
                            Select::make('storage_driver')
                                ->label(__('admin.storage_driver'))
                                ->options([
                                    'gcs'   => __('admin.storage_provider_gcs'),
                                    's3'    => __('admin.storage_provider_s3'),
                                    'local' => __('admin.storage_provider_local'),
                                ])
                                ->default('gcs')
                                ->required()
                                ->native(false)
                                ->live()
                                ->helperText(__('admin.storage_driver_hint'))
                                ->columnSpanFull(),

                            // Bucket — shared by GCS and S3.
                            TextInput::make('storage_bucket')
                                ->label(__('admin.storage_bucket'))
                                ->visible(fn (Get $get) => in_array($get('storage_driver'), ['gcs', 's3'], true)),

                            // --- Google Cloud Storage ---
                            TextInput::make('storage_project_id')
                                ->label(__('admin.storage_project_id'))
                                ->placeholder('my-gcp-project-id')
                                ->visible(fn (Get $get) => $get('storage_driver') === 'gcs'),
                            FileUpload::make('storage_gcs_key_file')
                                ->label(__('admin.storage_gcs_key_file'))
                                ->helperText(__('admin.storage_gcs_key_file_hint'))
                                // Private disk (storage/app, NOT the public symlink) — the
                                // service-account key must never be web-reachable.
                                ->disk('local')
                                ->directory('secure')
                                ->visibility('private')
                                ->acceptedFileTypes(['application/json'])
                                ->previewable(false)
                                ->columnSpanFull()
                                ->visible(fn (Get $get) => $get('storage_driver') === 'gcs'),

                            // --- Amazon S3 / S3-compatible (R2, DigitalOcean Spaces…) ---
                            TextInput::make('storage_endpoint')
                                ->label(__('admin.storage_endpoint'))
                                ->placeholder('https://s3.amazonaws.com or R2/DO endpoint')
                                ->visible(fn (Get $get) => $get('storage_driver') === 's3'),
                            TextInput::make('storage_region')
                                ->label(__('admin.storage_region'))
                                ->placeholder('us-east-1')
                                ->visible(fn (Get $get) => $get('storage_driver') === 's3'),
                            TextInput::make('storage_key')
                                ->label(__('admin.storage_key'))
                                ->password()->revealable()
                                ->visible(fn (Get $get) => $get('storage_driver') === 's3'),
                            TextInput::make('storage_secret')
                                ->label(__('admin.storage_secret'))
                                ->password()->revealable()
                                ->visible(fn (Get $get) => $get('storage_driver') === 's3'),
                        ])->columns(2),

                    Tabs\Tab::make(__('admin.maintenance_section'))
                        ->icon('heroicon-o-wrench-screwdriver')
                        ->schema([
                            Toggle::make('maintenance_mode')
                                ->label(__('admin.maintenance_mode'))
                                ->helperText(__('admin.maintenance_section_hint')),
                            Textarea::make('maintenance_message')
                                ->label(__('admin.maintenance_message'))
                                ->rows(2),
                        ]),

                    Tabs\Tab::make(__('admin.version_section'))
                        ->icon('heroicon-o-device-phone-mobile')
                        ->schema([
                            Placeholder::make('version_hint')
                                ->hiddenLabel()
                                ->content(__('admin.version_section_hint')),
                            $this->versionFieldset('android', __('admin.android')),
                            $this->versionFieldset('ios', __('admin.ios')),
                            $this->versionFieldset('huawei', __('admin.huawei')),
                        ]),

                ]),
        ])->statePath('data');
    }

    /**
     * One platform's force-update + store-link controls. The build number is an
     * integer (Android versionCode / iOS build); the gate compares it server-side.
     */
    private function versionFieldset(string $platform, string $label): Fieldset
    {
        return Fieldset::make($label)
            ->schema([
                TextInput::make("{$platform}_min_version")
                    ->label(__('admin.min_version'))
                    ->numeric()
                    ->helperText(__('admin.min_version_hint')),
                TextInput::make("{$platform}_latest_version")
                    ->label(__('admin.latest_version'))
                    ->numeric()
                    ->helperText(__('admin.latest_version_hint')),
                Toggle::make("{$platform}_update_required")
                    ->label(__('admin.update_required'))
                    ->helperText(__('admin.update_required_hint')),
                TextInput::make("{$platform}_store_url")
                    ->label(__('admin.store_url'))
                    ->url(),
            ])
            ->columns(2);
    }

    public function save(): void
    {
        // View-only admins (settings.view but not settings.update) can't persist.
        abort_unless(filament()->auth()->user()?->can('settings.update') ?? false, 403);

        $data = $this->form->getState();

        foreach ($data as $key => $value) {
            // Persist toggles as deterministic "1"/"0" strings (the value column
            // is text; raw bools would land as "1"/"" and read back wrong).
            if (is_bool($value)) {
                $value = $value ? '1' : '0';
            }

            Config::updateOrCreate(
                ['name' => $key],
                ['value' => $value]
            );
        }

        // Belt-and-suspenders: ensure the cached config map is dropped so the
        // app picks up these changes on its next /app-version call immediately.
        Config::flushMapCache();

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
