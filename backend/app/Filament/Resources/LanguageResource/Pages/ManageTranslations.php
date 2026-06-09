<?php

namespace App\Filament\Resources\LanguageResource\Pages;

use App\Filament\Resources\LanguageResource;
use App\Models\Language;
use App\Models\Translation;
use App\Models\TranslationKey;
use App\Services\TranslationLoader;
use Filament\Actions\Action;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Form;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\Page;
use Filament\Tables;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

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

        return $table
            ->query(
                TranslationKey::query()
                    ->when($activeTab === 'admin',
                        fn($q) => $q->whereIn('group', $this->adminGroups),
                        fn($q) => $q->whereNotIn('group', $this->adminGroups)
                    )
                    ->when($this->selectedGroup, fn($q) => $q->where('group', $this->selectedGroup))
                    ->with(['translations' => fn($q) => $q->where('language_id', $this->record->id)])
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
                TextColumn::make('translations.0.value')
                    ->label('Translation (' . strtoupper($this->record->code) . ')')
                    ->placeholder(__('admin.not_translated'))
                    ->wrap()
                    ->color(fn($state) => $state ? 'success' : 'warning'),
            ])
            ->actions([
                Tables\Actions\Action::make('translate')
                    ->label(__('admin.translate'))
                    ->icon('heroicon-o-pencil')
                    ->fillForm(fn(TranslationKey $record) => [
                        'value' => Translation::where('language_id', $this->record->id)
                            ->where('translation_key_id', $record->id)
                            ->value('value'),
                    ])
                    ->form([
                        TextInput::make('value')
                            ->label('Translation in ' . $this->record->native_name)
                            ->required(),
                    ])
                    ->action(function (TranslationKey $record, array $data) {
                        Translation::updateOrCreate(
                            ['language_id' => $this->record->id, 'translation_key_id' => $record->id],
                            ['value' => $data['value']]
                        );
                        app(TranslationLoader::class)->clearCache($this->record->code);
                        Notification::make()->title(__('admin.translation_saved'))->success()->send();
                    }),
            ])
            ->headerActions([
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

                        $imported = 0;
                        foreach ($content as $key => $value) {
                            $group   = explode('.', $key)[0] ?? 'app';
                            $keyModel = TranslationKey::firstOrCreate(
                                ['key' => $key],
                                ['group' => $group]
                            );
                            Translation::updateOrCreate(
                                ['language_id' => $this->record->id, 'translation_key_id' => $keyModel->id],
                                ['value' => $value]
                            );
                            $imported++;
                        }

                        app(TranslationLoader::class)->clearCache($this->record->code);

                        Notification::make()
                            ->title(__('admin.imported', ['count' => $imported]))
                            ->success()
                            ->send();
                    }),

                Tables\Actions\Action::make('filter_group')
                    ->label($this->selectedGroup ? "Group: {$this->selectedGroup}" : 'All Groups')
                    ->icon('heroicon-o-funnel')
                    ->form([
                        Select::make('group')
                            ->label('Filter by Group')
                            ->options(
                                TranslationKey::distinct()->pluck('group', 'group')->prepend('All', '')
                            )
                            ->nullable(),
                    ])
                    ->action(function (array $data) {
                        $this->selectedGroup = $data['group'] ?: null;
                    }),
            ])
            ->defaultPaginationPageOption(10)
            ->paginationPageOptions([10, 25, 50, 100])
            ->emptyStateHeading(__('admin.no_keys_yet'))
            ->emptyStateDescription(__('admin.no_keys_hint'))
            ->emptyStateIcon('heroicon-o-language');
    }

    public function getBreadcrumbs(): array
    {
        return [
            LanguageResource::getUrl() => 'Languages',
            '#' => $this->record->name . ' — Translations',
        ];
    }
}
