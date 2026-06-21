<?php

namespace App\Filament\Resources\LanguageResource\Pages;

use App\Contracts\Translator;
use App\Filament\Resources\LanguageResource;
use App\Models\Language;
use App\Services\TranslatableContentRegistry;
use App\Support\AppLanguages;
use App\Support\Translatable;
use App\Support\Translatable\TranslatableContentWriter;
use App\Support\Translatable\TranslatableSource;
use Filament\Forms\Components\Actions as FormActions;
use Filament\Forms\Components\Actions\Action as FormAction;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Forms\Set;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\Page;
use Filament\Tables\Actions\Action;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Concerns\InteractsWithTable;
use Filament\Tables\Contracts\HasTable;
use Filament\Tables\Table;
use Illuminate\Support\Str;

/**
 * Per-language CONTENT translation gaps. Pick a language → see translatable
 * content (registered sources, Pages by default) MISSING that language → fill
 * each manually or via the AI engine ({@see Translator}), or bulk "AI-translate
 * all missing". The dynamic-content analogue of {@see ManageTranslations} (which
 * covers UI strings). Writes the same {locale => value} JSON the page editor does.
 */
class ManageContentTranslations extends Page implements HasTable
{
    use InteractsWithForms;
    use InteractsWithTable;

    protected static string $resource = LanguageResource::class;
    protected static string $view = 'filament.resources.language-resource.pages.manage-content-translations';

    public Language $record;
    public ?string $activeSource = null;
    public bool $showAll = false;

    // Force LengthAwarePaginator so page numbers appear (mirrors ManageTranslations).
    protected function paginateTableQuery(\Illuminate\Database\Eloquent\Builder $query): \Illuminate\Contracts\Pagination\LengthAwarePaginator
    {
        $perPage = $this->getTableRecordsPerPage();

        return $query->paginate(
            $perPage === 'all' ? $query->count() : $perPage,
            ['*'],
            $this->getTablePaginationPageName()
        );
    }

    public function mount(Language $record): void
    {
        $this->record = $record;
        $this->activeSource = request()->query('source')
            ?: array_key_first(app(TranslatableContentRegistry::class)->all());
    }

    private function source(): ?TranslatableSource
    {
        return $this->activeSource
            ? app(TranslatableContentRegistry::class)->get($this->activeSource)
            : null;
    }

    /** IDs of items missing at least one field translation for this language. */
    private function missingIds(TranslatableSource $src): array
    {
        $code = $this->record->code;

        return $src->query()->get()->filter(function ($model) use ($src, $code) {
            foreach ($src->fieldNames() as $field) {
                if (! Translatable::hasLocale($model->getAttribute($field), $code)) {
                    return true;
                }
            }

            return false;
        })->map->getKey()->all();
    }

    public function table(Table $table): Table
    {
        $src = $this->source();

        if (! $src) {
            return $table->query(Language::query()->whereRaw('1 = 0'))->columns([]);
        }

        $langCode = $this->record->code;
        $default  = AppLanguages::defaultCode();

        $query = $src->query()->orderBy('id');
        if (! $this->showAll) {
            $query->whereKey($this->missingIds($src) ?: [-1]);
        }

        $columns = [
            TextColumn::make('__item')
                ->label(__('admin.item'))
                ->state(fn ($record) => $src->itemLabel($record))
                ->wrap(),
        ];

        foreach ($src->fieldNames() as $field) {
            $columns[] = TextColumn::make("__field_{$field}")
                ->label(__('admin.' . $field) !== 'admin.' . $field ? __('admin.' . $field) : ucfirst($field))
                ->badge()
                ->state(fn ($record) => Translatable::hasLocale($record->getAttribute($field), $langCode)
                    ? __('admin.translated')
                    : __('admin.not_translated'))
                ->color(fn ($record) => Translatable::hasLocale($record->getAttribute($field), $langCode)
                    ? 'success'
                    : 'warning');
        }

        return $table
            ->query($query)
            ->columns($columns)
            ->actions([
                Action::make('translate')
                    ->label(__('admin.translate'))
                    ->icon('heroicon-o-pencil')
                    ->modalWidth('3xl')
                    ->fillForm(fn ($record) => collect($src->fieldNames())
                        ->mapWithKeys(fn ($field) => [
                            $field => is_array($record->getAttribute($field))
                                ? ($record->getAttribute($field)[$langCode] ?? '')
                                : '',
                        ])->all())
                    ->form(fn ($record) => $this->translateForm($src, $record, $langCode, $default))
                    ->action(function ($record, array $data) use ($src, $langCode) {
                        TranslatableContentWriter::write($record, $src->fieldNames(), $langCode, $data);
                        Notification::make()->title(__('admin.translate_saved'))->success()->send();
                    }),

                Action::make('edit_in_editor')
                    ->label(__('admin.edit_in_editor'))
                    ->icon('heroicon-o-arrow-top-right-on-square')
                    ->url(fn ($record) => $src->editUrl($record))
                    ->openUrlInNewTab()
                    ->visible(fn ($record) => $src->editUrl($record) !== null),
            ])
            ->headerActions([
                Action::make('ai_translate_all_missing')
                    ->label(__('admin.ai_translate_all_missing'))
                    ->icon('heroicon-o-sparkles')
                    ->requiresConfirmation()
                    ->action(fn () => $this->aiTranslateAllMissing($src, $langCode, $default)),

                Action::make('toggle_show_all')
                    ->label($this->showAll ? __('admin.only_missing') : __('admin.show_all'))
                    ->icon('heroicon-o-funnel')
                    ->color('gray')
                    ->action(fn () => $this->showAll = ! $this->showAll),
            ])
            ->defaultPaginationPageOption(10)
            ->paginationPageOptions([10, 25, 50, 100])
            ->emptyStateHeading(__('admin.all_translated'))
            ->emptyStateIcon('heroicon-o-check-circle');
    }

    /** Build the per-field modal form (manual inputs + an "AI translate" button). */
    private function translateForm(TranslatableSource $src, $record, string $langCode, string $default): array
    {
        $schema = [
            FormActions::make([
                FormAction::make('ai_fill')
                    ->label(__('admin.ai_translate'))
                    ->icon('heroicon-o-sparkles')
                    ->action(function (Set $set) use ($src, $record, $langCode, $default) {
                        $translator = app(Translator::class);
                        foreach ($src->fieldNames() as $field) {
                            $source = Translatable::resolve($record->getAttribute($field), $default);
                            if ($source === null || trim($source) === '') {
                                continue;
                            }
                            $set($field, $translator->translate($source, $langCode, $default, $src->isHtml($field)));
                        }
                        if ($translator->lastError()) {
                            Notification::make()->title(__('admin.ai_failed'))->danger()->send();
                        }
                    }),
            ]),
        ];

        foreach ($src->fieldNames() as $field) {
            $sourceVal = (string) (Translatable::resolve($record->getAttribute($field), $default) ?? '');
            $label = __('admin.' . $field) !== 'admin.' . $field ? __('admin.' . $field) : ucfirst($field);

            $component = $src->isHtml($field)
                ? Textarea::make($field)->rows(10)
                : TextInput::make($field);

            $schema[] = $component
                ->label($label)
                ->helperText(__('admin.default') . ': ' . Str::limit(strip_tags($sourceVal), 160));
        }

        return $schema;
    }

    /** Fill every missing field of every item via the AI engine (fail-soft). */
    private function aiTranslateAllMissing(TranslatableSource $src, string $langCode, string $default): void
    {
        $translator = app(Translator::class);
        $count = 0;

        foreach ($src->query()->get() as $model) {
            $values = [];
            foreach ($src->fieldNames() as $field) {
                if (Translatable::hasLocale($model->getAttribute($field), $langCode)) {
                    continue;
                }
                $source = Translatable::resolve($model->getAttribute($field), $default);
                if ($source === null || trim($source) === '') {
                    continue;
                }
                $translated = $translator->translate($source, $langCode, $default, $src->isHtml($field));
                if ($translator->lastError()) {
                    continue; // skip this field; keep going
                }
                $values[$field] = $translated;
            }

            if ($values !== []) {
                TranslatableContentWriter::write($model, array_keys($values), $langCode, $values);
                $count++;
            }
        }

        Notification::make()->title(__('admin.ai_translated_count', ['count' => $count]))->success()->send();
    }

    public function getBreadcrumbs(): array
    {
        return [
            LanguageResource::getUrl() => __('admin.nav_languages'),
            '#' => $this->record->native_name . ' — ' . __('admin.content_translations'),
        ];
    }
}
