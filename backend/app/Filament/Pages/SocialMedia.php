<?php

namespace App\Filament\Pages;

use App\Models\Config;
use App\Support\SocialPlatforms;
use Filament\Forms\Components\ColorPicker;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Form;
use Filament\Forms\Get;
use Filament\Notifications\Notification;
use Filament\Pages\Page;

/**
 * Social Media — the admin-managed list of contact/social links shown on the
 * app's "Contact Us" screen. A standalone dashboard page: add/edit/remove/reorder
 * links freely. Pick a known platform (icon + color come from the shared
 * {@see SocialPlatforms} registry) or choose "Other" and upload a custom icon
 * + color for any platform.
 *
 * Storage is a single JSON `social_links` config row (no dedicated table); the
 * public /app-version API reads it via AppVersionController. Legacy per-platform
 * `social_{key}` rows are migrated into the list on first load.
 */
class SocialMedia extends Page
{
    use InteractsWithForms;

    protected static ?string $navigationIcon = 'heroicon-o-share';
    protected static ?int $navigationSort = 11;
    protected static string $view = 'filament.pages.social-media';

    public static function getNavigationLabel(): string
    {
        return __('admin.nav_social_media');
    }

    public function getTitle(): string
    {
        return __('admin.nav_social_media');
    }

    public function getSubheading(): ?string
    {
        return __('admin.contact_section_hint');
    }

    public static function canAccess(): bool
    {
        return filament()->auth()->user()?->can('social_media.view') ?? false;
    }

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'social_links' => $this->loadSocialLinks(),
        ]);
    }

    public function form(Form $form): Form
    {
        return $form->schema([
            Repeater::make('social_links')
                ->hiddenLabel()
                ->addActionLabel(__('admin.social_add_link'))
                ->reorderable()
                ->reorderableWithButtons()
                ->collapsible()
                ->cloneable()
                ->itemLabel(fn (array $state): ?string => self::socialItemLabel($state))
                ->columnSpanFull()
                ->columns(2)
                ->schema([
                    Select::make('platform')
                        ->label(__('admin.social_platform'))
                        ->options(SocialPlatforms::options())
                        ->default(array_key_first(SocialPlatforms::KNOWN))
                        ->required()
                        ->native(false)
                        ->live(),
                    TextInput::make('value')
                        ->label(__('admin.social_value'))
                        ->required()
                        ->placeholder('https://… / +201234567890'),
                    // Custom-only fields (platform = "custom").
                    TextInput::make('label')
                        ->label(__('admin.social_custom_label'))
                        ->required(fn (Get $get) => $get('platform') === SocialPlatforms::CUSTOM)
                        ->visible(fn (Get $get) => $get('platform') === SocialPlatforms::CUSTOM),
                    ColorPicker::make('color')
                        ->label(__('admin.social_custom_color'))
                        ->visible(fn (Get $get) => $get('platform') === SocialPlatforms::CUSTOM),
                    FileUpload::make('icon')
                        ->label(__('admin.social_custom_icon'))
                        ->image()
                        // Same public-disk pattern as app_logo: the app media disk
                        // may be a read-only cloud bucket, so keep these small icons
                        // on the local public disk (web-served via storage:link).
                        ->disk('public')
                        ->visibility('public')
                        ->directory('settings/social')
                        ->columnSpanFull()
                        ->visible(fn (Get $get) => $get('platform') === SocialPlatforms::CUSTOM),
                ]),
        ])->statePath('data');
    }

    public function save(): void
    {
        // View-only admins (social_media.view but not .update) can't persist.
        abort_unless(filament()->auth()->user()?->can('social_media.update') ?? false, 403);

        $state = $this->form->getState();

        Config::updateOrCreate(
            ['name' => 'social_links'],
            ['value' => $this->encodeSocialLinks($state['social_links'] ?? [])]
        );

        // Drop the legacy per-platform rows (social_facebook, …) — they were
        // migrated into `social_links` on first load and are now dead.
        Config::whereIn('name', self::legacySocialKeys())->delete();

        // Bust the cached config map so the app's next /app-version call is fresh.
        Config::flushMapCache();

        Notification::make()
            ->title(__('admin.settings_saved'))
            ->success()
            ->send();
    }

    /**
     * Initial state for the repeater. Prefers the JSON `social_links` row; if it's
     * absent (an install that predates this feature) it migrates the legacy
     * per-platform rows (social_facebook, …) into repeater rows on read.
     *
     * @return array<int,array<string,mixed>>
     */
    private function loadSocialLinks(): array
    {
        $raw = Config::where('name', 'social_links')->value('value');
        if (is_string($raw) && $raw !== '') {
            $decoded = json_decode($raw, true);
            if (is_array($decoded)) {
                return array_values($decoded);
            }
        }

        $rows = [];
        foreach (array_keys(SocialPlatforms::KNOWN) as $key) {
            $value = Config::where('name', 'social_' . $key)->value('value');
            if (is_string($value) && trim($value) !== '') {
                $rows[] = ['platform' => $key, 'value' => $value];
            }
        }

        return $rows;
    }

    /**
     * Normalize the repeater state into the JSON stored in `social_links`: drop
     * empty rows and keep only the meaningful keys per item (custom-only
     * icon/color/label are omitted for known platforms).
     */
    private function encodeSocialLinks(mixed $value): string
    {
        $links = [];
        foreach ((is_array($value) ? $value : []) as $row) {
            if (! is_array($row)) {
                continue;
            }

            $platform = (string) ($row['platform'] ?? '');
            $link     = trim((string) ($row['value'] ?? ''));
            if ($platform === '' || $link === '') {
                continue;
            }

            $item = ['platform' => $platform, 'value' => $link];

            if ($platform === SocialPlatforms::CUSTOM) {
                foreach (['label', 'icon', 'color'] as $k) {
                    $v = trim((string) ($row[$k] ?? ''));
                    if ($v !== '') {
                        $item[$k] = $v;
                    }
                }
            }

            $links[] = $item;
        }

        return json_encode($links, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }

    /** Collapsed-row title for a contact link (its label, or platform name). */
    private static function socialItemLabel(array $state): ?string
    {
        $platform = (string) ($state['platform'] ?? '');
        if ($platform === '') {
            return null;
        }

        $label = trim((string) ($state['label'] ?? ''));

        return $label !== '' ? $label : SocialPlatforms::label($platform);
    }

    /**
     * The legacy per-platform config keys (social_facebook, …) replaced by the
     * single `social_links` JSON row.
     *
     * @return array<int,string>
     */
    private static function legacySocialKeys(): array
    {
        return array_map(
            static fn (string $key): string => 'social_' . $key,
            array_keys(SocialPlatforms::KNOWN)
        );
    }
}
