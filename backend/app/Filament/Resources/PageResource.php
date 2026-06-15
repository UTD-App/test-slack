<?php

namespace App\Filament\Resources;

use App\Filament\Resources\PageResource\Pages;
use App\Models\Page;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

/**
 * Admin CRUD for static content pages (privacy policy, about us, …). The app
 * fetches them by `key` via GET /page/{key}. Title/body are localized (en/ar).
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
        return $form->schema([
            Section::make()->schema([
                TextInput::make('key')
                    ->label(__('admin.key'))
                    ->helperText(__('admin.page_key_hint'))
                    ->required()
                    ->disabledOn('edit')
                    ->maxLength(100),
                TextInput::make('title.en')->label(__('admin.page_title_en'))->required(),
                TextInput::make('title.ar')->label(__('admin.page_title_ar'))->required(),
                Textarea::make('body.en')->label(__('admin.page_body_en'))->rows(12)->columnSpanFull(),
                Textarea::make('body.ar')->label(__('admin.page_body_ar'))->rows(12)->columnSpanFull(),
            ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('key')->label(__('admin.key'))->badge()->sortable()->searchable(),
                TextColumn::make('title.en')->label(__('admin.page_title_en'))->limit(40),
                TextColumn::make('title.ar')->label(__('admin.page_title_ar'))->limit(40),
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
