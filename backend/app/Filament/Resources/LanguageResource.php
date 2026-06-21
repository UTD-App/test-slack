<?php

namespace App\Filament\Resources;

use App\Filament\Resources\LanguageResource\Pages;
use App\Models\Language;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Forms\Form;
use Filament\Tables\Actions\DeleteAction;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Actions\Action;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;

class LanguageResource extends BaseResource
{
    protected static ?string $model = Language::class;
    protected static ?string $navigationIcon = 'heroicon-o-language';
    protected static ?string $navigationLabel = null;
    protected static ?int $navigationSort = 20;

    protected static ?string $permissionPrefix = 'languages';

    public static function getModelLabel(): string { return __('admin.language'); }
    public static function getPluralModelLabel(): string { return __("admin.nav_languages"); }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Section::make()->schema([
                TextInput::make('code')
                    ->label(__('admin.language_code'))
                    ->placeholder('en, ar, fr, tr...')
                    ->required()
                    ->maxLength(10),
                TextInput::make('name')
                    ->label(__('admin.name_in_english'))
                    ->placeholder('Arabic, French...')
                    ->required(),
                TextInput::make('native_name')
                    ->label(__('admin.native_name'))
                    ->placeholder('العربية, Français...')
                    ->required(),
                Toggle::make('is_rtl')->label(__('admin.rtl_full')),
                Toggle::make('is_active')->label(__('admin.active'))->default(true),
                Toggle::make('is_default')->label(__('admin.default_language')),
            ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('code')->label(__('admin.code'))->badge()->sortable(),
                TextColumn::make('name')->label(__('admin.name'))->sortable(),
                TextColumn::make('native_name')->label(__('admin.native_name')),
                IconColumn::make('is_rtl')->label(__('admin.rtl'))->boolean(),
                IconColumn::make('is_active')->label(__('admin.active'))->boolean(),
                IconColumn::make('is_default')->label(__('admin.default'))->boolean(),
            ])
            ->actions([
                Action::make('translations')
                    ->label(__('admin.translate'))
                    ->icon('heroicon-o-pencil-square')
                    ->url(fn(Language $record) => static::getUrl('translations', ['record' => $record])),
                Action::make('content_translations')
                    ->label(__('admin.content_translations'))
                    ->icon('heroicon-o-document-text')
                    ->url(fn(Language $record) => static::getUrl('content-translations', ['record' => $record])),
                EditAction::make(),
                DeleteAction::make()
                    ->before(fn(Language $record) => throw_if(
                        $record->is_default,
                        \Exception::class,
                        __('admin.cannot_delete_default')
                    )),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index'        => Pages\ListLanguages::route('/'),
            'create'       => Pages\CreateLanguage::route('/create'),
            'edit'         => Pages\EditLanguage::route('/{record}/edit'),
            'translations' => Pages\ManageTranslations::route('/{record}/translations'),
            'content-translations' => Pages\ManageContentTranslations::route('/{record}/content-translations'),
        ];
    }
}
