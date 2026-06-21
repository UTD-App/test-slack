<?php

namespace App\Filament\Resources;

use App\Facades\EmailTemplates;
use App\Filament\Resources\EmailTemplateResource\Pages;
use App\Models\EmailTemplate;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\TextInput;
use Kahusoftware\FilamentCkeditorField\CKEditor;
use Filament\Forms\Form;
use Filament\Tables\Actions\EditAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Support\HtmlString;

/**
 * Admin CRUD (edit-only) for transactional email templates. The editable set
 * comes from the EmailTemplateRegistry (Base + packages register types); there
 * is no create/delete — only editing each type's subject + raw HTML body per
 * locale. New email types appear here automatically.
 */
class EmailTemplateResource extends BaseResource
{
    protected static ?string $model = EmailTemplate::class;
    protected static ?string $navigationIcon = 'heroicon-o-envelope';
    protected static ?int $navigationSort = 26;

    protected static ?string $permissionPrefix = 'email_templates';

    /** Edit-only: types come from the registry, never created/deleted in the UI. */
    protected static array $permissionAbilities = ['view', 'update'];

    public static function getModelLabel(): string { return __('admin.email_template_single'); }
    public static function getPluralModelLabel(): string { return __('admin.email_templates'); }
    public static function getNavigationLabel(): string { return __('admin.nav_email_templates'); }

    public static function canCreate(): bool { return false; }

    public static function form(Form $form): Form
    {
        return $form->schema([
            Section::make()->schema([
                Placeholder::make('type_label')
                    ->label(__('admin.email_template_type'))
                    ->content(fn (?EmailTemplate $record) => static::typeLabel($record?->key)),
                Placeholder::make('placeholders')
                    ->label(__('admin.email_template_placeholders'))
                    ->content(fn (?EmailTemplate $record) => new HtmlString(static::placeholderHelp($record?->key)))
                    ->columnSpanFull(),

                TextInput::make('subject.en')->label(__('admin.email_template_subject_en')),
                TextInput::make('subject.ar')->label(__('admin.email_template_subject_ar')),

                // Full CKEditor 5 (rich toolbar + Source editing `<>` + General
                // HTML Support). Edit the email visually or via raw HTML source;
                // only {{placeholders}} are substituted at send time.
                CKEditor::make('body.en')
                    ->label(__('admin.email_template_body_en'))
                    ->helperText(__('admin.email_template_body_hint'))
                    ->columnSpanFull(),
                CKEditor::make('body.ar')
                    ->label(__('admin.email_template_body_ar'))
                    ->helperText(__('admin.email_template_body_hint'))
                    ->columnSpanFull(),
            ])->columns(2),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('key')
                    ->label(__('admin.email_template_type'))
                    ->badge()
                    ->formatStateUsing(fn (string $state) => static::typeLabel($state))
                    ->searchable(),
                TextColumn::make('subject.en')
                    ->label(__('admin.email_template_subject_en'))
                    ->limit(50),
                TextColumn::make('updated_at')
                    ->label(__('admin.updated_at'))
                    ->dateTime()
                    ->sortable(),
            ])
            ->actions([EditAction::make()]);
    }

    /** Friendly translated name for a template key (falls back to the key). */
    public static function typeLabel(?string $key): string
    {
        if (! $key) {
            return '';
        }

        return EmailTemplates::get($key)?->label() ?: $key;
    }

    /** HTML list of the {{placeholders}} a given template supports. */
    protected static function placeholderHelp(?string $key): string
    {
        $type  = $key ? EmailTemplates::get($key) : null;
        $items = $type?->placeholders ?? [];

        if (empty($items)) {
            return '<span style="opacity:.6">—</span>';
        }

        $rows = '';
        foreach ($items as $name => $desc) {
            $rows .= '<li><code>{{' . e($name) . '}}</code> — ' . e(__($desc)) . '</li>';
        }

        return '<ul style="margin:0;padding-inline-start:1.1rem;list-style:disc;">' . $rows . '</ul>';
    }

    public static function getPages(): array
    {
        return [
            'index' => Pages\ListEmailTemplates::route('/'),
            'edit'  => Pages\EditEmailTemplate::route('/{record}/edit'),
        ];
    }
}
