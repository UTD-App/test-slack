<?php

namespace App\Filament\Resources\LanguageResource\Pages;

use App\Contracts\Translator;
use App\Jobs\AiTranslateMissingTranslations;
use App\Filament\Resources\LanguageResource;
use App\Models\Language;
use App\Models\TranslationKey;
use App\Services\TranslationLoader;
use Filament\Actions\Action;
use Filament\Forms\Components\Actions as FormActions;
use Filament\Forms\Components\Actions\Action as FormAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Form;
use Filament\Forms\Set;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\Page;
use Filament\Tables;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Str;

class ManageTranslations extends Page implements HasTable
{
    use InteractsWithForms;
    use InteractsWithTable;

    // Force LengthAwarePaginator so page numbers appear
    protected function paginateTableQuery(\Illuminate\Database\Eloquent\Builder $query): \Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        $perPage = $this->getTableRecordsPerPage();
        return $query->paginate(
            $perPage === 'all' ? $query->count() : $perPage,
            ['*'],
            $this->getTablePaginationPageName()
        );
    }

    protected static string $resource = LanguageResource::class;
    protected static string $view = 'filament.resources.language-resource.pages.manage-translations';

    public Language $record;
    public ?string $selectedGroup = null;

    public function mount(Language $record): void
    {
        $this->record = $record;
        app(TranslationLoader::class)->syncKeysFromFiles();
    }

    private array $adminGroups = ['admin', 'dashboard', 'auth', 'validation', 'passwords', 'pagination'];

    public function table(Table $table): Table
    {
        $activeTab = request()->query('tab', 'admin');

        // UI translations live in lang/<code>/*.php — read the locale's flat map
        // once and resolve each row's value from it (replaces the old DB lookup).
        $fileValues = app(TranslationLoader::class)->scanLangFiles($this->record->code);

        return $table
            ->query(
                TranslationKey::query()
                    ->when($activeTab === 'admin',
                        fn($q) => $q->whereIn('group', $this->adminGroups),
                        fn($q) => $q->whereNotIn('group', $this->adminGroups)
                    )
                    ->when($this->selectedGroup, fn($q) => $q->where('group', $this->selectedGroup))
                    ->orderBy('group')
                    ->orderBy('key')
            )
            ->columns([
                TextColumn::make('group')
                    ->label(__('admin.group'))
                    ->badge()
                    ->color(fn($state) => match($state) {
                        'admin'     => 'primary',
                        'dashboard' => 'info',
                        'auth'      => 'warning',
                        'app'       => 'success',
                        default     => 'gray',
                    })
                    ->sortable(),
                TextColumn::make('key')
                    ->label(__('admin.key'))
                    ->searchable()
                    ->limit(50),
                TextColumn::make('value')
                    ->label(__('admin.translation_col', ['code' => strtoupper($this->record->code)]))
                    ->state(fn(TranslationKey $record) => $fileValues[$record->key] ?? null)
                    ->placeholder(__('admin.not_translated'))
                    ->wrap()
                    ->color(fn($state) => $state ? 'success' : 'warning'),
            ])
            ->actions([
                Tables\Actions\Action::make('translate')
                    ->label(__('admin.translate'))
                    ->icon('heroicon-o-pencil')
                    ->fillForm(fn(TranslationKey $record) => [
                        'value' => app(TranslationLoader::class)
                            ->getFileValue($this->record->code, $record->key),
                    ])
                    ->form(fn(TranslationKey $record) => $this->editForm($record))
                    ->action(function (TranslationKey $record, array $data) {
                        $loader = app(TranslationLoader::class);
                        $loader->writeGroupValues(
                            $this->record->code,
                            $record->group,
                            [$record->key => $data['value']]
                        );
                        $loader->clearCache($this->record->code);
                        Notification::make()->title(__('admin.translation_saved'))->success()->send();
                    }),
            ])
            ->headerActions([
                Tables\Actions\Action::make('ai_translate_all_missing')
                    ->label(__('admin.ai_translate_all_missing'))
                    ->icon('heroicon-o-sparkles')
                    ->color('primary')
                    ->requiresConfirmation()
                    ->modalDescription(fn() => __('admin.translation_in', ['lang' => $this->record->native_name]))
                    // Runs in the background (one Gemini call per key → minutes for
                    // a full tab; doing it inline timed out). Values appear on the
                    // page as batches finish — refresh to see them. Requires a
                    // queue worker (php artisan queue:work).
                    ->action(function () {
                        AiTranslateMissingTranslations::dispatch(
                            $this->record->id,
                            request()->query('tab', 'admin'),
                            $this->selectedGroup,
                        );
                        Notification::make()
                            ->title(__('admin.ai_translate_started'))
                            ->success()
                            ->send();
                    }),

                Tables\Actions\Action::make('sync_keys')
                    ->label(__('admin.sync_keys'))
                    ->icon('heroicon-o-arrow-path')
                    ->action(function () {
                        $count = app(TranslationLoader::class)->syncKeysFromFiles();
                        Notification::make()
                            ->title(__('admin.synced_keys', ['count' => $count]))
                            ->success()
                            ->send();
                    }),

                Tables\Actions\Action::make('import_json')
                    ->label(__('admin.import_json'))
                    ->icon('heroicon-o-arrow-up-tray')
                    ->form([
                        FileUpload::make('file')
                            ->label(__('admin.json_file'))
                            ->acceptedFileTypes(['application/json'])
                            ->required()
                            ->disk('local')
                            ->directory('imports'),
                    ])
                    ->action(function (array $data) {
                        $path    = storage_path("app/{$data['file']}");
                        $content = json_decode(file_get_contents($path), true);

                        if (!is_array($content)) {
                            Notification::make()->title(__('admin.invalid_json'))->danger()->send();
                            return;
                        }

                        $loader   = app(TranslationLoader::class);
                        $byGroup  = [];
                        $imported = 0;
                        foreach ($content as $key => $value) {
                            if (!is_string($value)) {
                                continue;
                            }
                            $group = explode('.', $key)[0] ?: 'app';
                            // Keep the key catalog in sync so it lists on the page.
                            TranslationKey::firstOrCreate(['key' => $key], ['group' => $group]);
                            $byGroup[$group][$key] = $value;
                            $imported++;
                        }

                        foreach ($byGroup as $group => $vals) {
                            $loader->writeGroupValues($this->record->code, $group, $vals);
                        }
                        $loader->clearCache($this->record->code);

                        Notification::make()
                            ->title(__('admin.imported', ['count' => $imported]))
                            ->success()
                            ->send();
                    }),

                Tables\Actions\Action::make('filter_group')
                    ->label($this->selectedGroup ? __('admin.group_label', ['group' => $this->selectedGroup]) : __('admin.all_groups'))
                    ->icon('heroicon-o-funnel')
                    ->form([
                        Select::make('group')
                            ->label(__('admin.filter_group'))
                            ->options(
                                TranslationKey::distinct()->pluck('group', 'group')->prepend(__('admin.all_groups'), '')
                            )
                            ->nullable(),
                    ])
                    ->action(function (array $data) {
                        $this->selectedGroup = $data['group'] ?: null;
                    }),
            ])
            ->defaultPaginationPageOption(10)
            ->paginationPageOptions([10, 25, 50, 100])
            // Auto-refresh so a running background AI-translate is visible live —
            // rows flip to "translated" without a manual reload.
            ->poll('10s')
            ->emptyStateHeading(__('admin.no_keys_yet'))
            ->emptyStateDescription(__('admin.no_keys_hint'))
            ->emptyStateIcon('heroicon-o-language');
    }

    /**
     * The per-key edit modal: an "AI translate" button (fills the value from the
     * English source via the {@see Translator} engine) above the manual input.
     * The English string for a UI key is its value in lang/en/*.php.
     */
    private function editForm(TranslationKey $record): array
    {
        $english = app(TranslationLoader::class)->scanLangFiles('en')[$record->key] ?? '';
        $target  = $this->record->code;

        return [
            FormActions::make([
                FormAction::make('ai_fill')
                    ->label(__('admin.ai_translate'))
                    ->icon('heroicon-o-sparkles')
                    ->visible($english !== '' && $target !== 'en')
                    ->action(function (Set $set) use ($english, $target) {
                        $translator = app(Translator::class);
                        $set('value', $translator->translate($english, $target, 'en'));
                        if ($translator->lastError()) {
                            Notification::make()->title(__('admin.ai_failed'))->danger()->send();
                        }
                    }),
            ]),

            TextInput::make('value')
                ->label(__('admin.translation_in', ['lang' => $this->record->native_name]))
                ->helperText($english !== '' ? __('admin.default') . ': ' . Str::limit($english, 160) : null)
                ->required(),
        ];
    }

    public function getBreadcrumbs(): array
    {
        return [
            LanguageResource::getUrl() => 'Languages',
            '#' => $this->record->name . ' — Translations',
        ];
    }
}
