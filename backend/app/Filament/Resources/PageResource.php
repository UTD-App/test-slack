<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PageResource\Pages;
use App\Models\Page;
use App\Support\AppLanguages;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Kahusoftware\FilamentCkeditorField\CKEditor;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/**
 * Admin CRUD for static content pages (privacy policy, about us, …). The app
 * fetches them by `key` via GET /page/{key}, which resolves title/body to the
 * request locale. This editor edits ONLY the default-language content (kept
 * clean); translations into other languages are managed centrally in the
 * Languages → "Content translations" page. Saving here preserves existing
 * translations (see CreatePage/EditPage + {@see \App\Support\Translatable\DefaultLocaleForm}).
 */
class PageResource extends BaseResource
{
    protected static ?string $model = Page::class;
    protected static ?string $navigationIcon = 'heroicon-o-document-text';
    protected static ?int $navigationSort = 25;

    protected static ?string $permissionPrefix = 'pages';

    public static function getModelLabel(): string { return __('admin.page_single'); }
    public static function getPluralModelLabel(): string { return __('admin.pages'); }
    public static function getNavigationLabel(): string { return __('admin.nav_pages'); }

    public static function form(Form $form): Form
    {
        $defaultName = AppLanguages::names()[AppLanguages::defaultCode()]
            ?? strtoupper(AppLanguages::defaultCode());

        return $form->schema([
            Section::make()->schema([
                TextInput::make('key')
                    ->label(__('admin.key'))
                    ->helperText(__('admin.page_key_hint'))
                    ->required()
                    ->disabledOn('edit')
                    ->maxLength(100)
                    ->columnSpanFull(),

                Placeholder::make('translations_hint')
                    ->hiddenLabel()
                    ->content(__('admin.page_translations_hint'))
                    ->columnSpanFull(),

                // Default-language content only. CKEditor 5 (rich toolbar + Source
                // editing `<>` + General HTML Support) for the body; the app's
                // ContentPage (a WebView) renders the HTML as written.
                TextInput::make('title_default')
                    ->label(__('admin.title') . ' (' . $defaultName . ')')
                    ->required()
                    ->columnSpanFull(),

                CKEditor::make('body_default')
                    ->label(__('admin.content') . ' (' . $defaultName . ')')
                    ->helperText(__('admin.page_body_html_hint'))
                    ->columnSpanFull(),
            ])->columns(1),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('key')->label(__('admin.key'))->badge()->sortable()->searchable(),
                TextColumn::make('title')
                    ->label(__('admin.title'))
                    ->state(fn (Page $record): string => $record->tr('title'))
                    ->limit(40),
                TextColumn::make('updated_at')->label(__('admin.updated_at'))->dateTime()->sortable(),
            ])
            ->actions([EditAction::make(), DeleteAction::make()]);
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListPages::route('/'),
            'create' => Pages\CreatePage::route('/create'),
            'edit'   => Pages\EditPage::route('/{record}/edit'),
        ];
    }
}
