<?php

namespace App\Filament\Forms\Components;

use App\Contracts\Translator;
use App\Support\AppLanguages;
use Closure;
use Filament\Forms\Components\Actions;
use Filament\Forms\Components\Actions\Action;
use Filament\Forms\Components\Group;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Get;
use Filament\Forms\Set;
use Filament\Notifications\Notification;

/**
 * Reusable admin editor for a translatable JSON attribute (e.g. Page::$body
 * stored as {"en":"...","fr":"..."}). Renders ONE default-language field plus an
 * "add language" repeater of {lang, value} rows — each row has a one-click Google
 * Translate button, and the page can offer a "Translate all" via fillMissing().
 *
 * The DB stores a single locale=>value map; the FORM works with a split shape
 * ({name}_default + {name}_locales). Wire the split/merge in the Resource's
 * Create/Edit pages:
 *
 *   protected array $translatable = ['title', 'body'];
 *
 *   protected function mutateFormDataBeforeFill(array $data): array       // Edit
 *   { return TranslatableField::mutateBeforeFill($data, $this->translatable); }
 *
 *   protected function mutateFormDataBeforeCreate(array $data): array     // Create
 *   { return TranslatableField::mutateBeforeSave($data, $this->translatable); }
 *   protected function mutateFormDataBeforeSave(array $data): array       // Edit
 *   { return TranslatableField::mutateBeforeSave($data, $this->translatable); }
 *
 * @see \App\Support\Translatable for the read-side resolution + fallback.
 */
class TranslatableField
{
    /**
     * @param  Closure(string $statePath): \Filament\Forms\Components\Field  $fieldUsing
     *         Builds the inner editor (TextInput, CKEditor, …) bound to a path.
     * @param  bool  $html  Translate as HTML (preserves tags) — set for rich bodies.
     */
    public static function make(string $name, Closure $fieldUsing, bool $html = false): Group
    {
        return Group::make([
            // The always-present default-language value.
            $fieldUsing("{$name}_default")
                ->label(self::defaultLabel())
                ->required(),

            // Add-a-language repeater: each row picks a target language + value,
            // with a per-row "Translate" button that fills it from the default.
            Repeater::make("{$name}_locales")
                ->label(__('admin.translations'))
                ->addActionLabel(__('admin.add_language'))
                ->collapsible()
                ->reorderable(false)
                ->defaultItems(0)
                ->itemLabel(fn (array $state): ?string => self::names()[$state['lang'] ?? ''] ?? ($state['lang'] ?? null))
                ->schema([
                    Select::make('lang')
                        ->label(__('admin.language'))
                        ->options(fn (): array => self::localeOptions())
                        ->required()
                        ->live()
                        ->distinct()
                        ->disableOptionsWhenSelectedInSiblingRepeaterItems(),

                    $fieldUsing('value')->label(__('admin.content')),

                    Actions::make([
                        Action::make("translate_{$name}")
                            ->label(__('admin.translate'))
                            ->icon('heroicon-o-language')
                            ->color('gray')
                            ->action(function (Get $get, Set $set) use ($name, $html): void {
                                $source = (string) $get("../../{$name}_default");
                                $target = $get('lang');

                                if (trim($source) === '' || ! $target) {
                                    Notification::make()
                                        ->title(__('admin.translate_need_source_lang'))
                                        ->warning()
                                        ->send();

                                    return;
                                }

                                $service = app(Translator::class);
                                $translated = $service->translate($source, (string) $target, AppLanguages::defaultCode(), $html);

                                if ($service->lastError()) {
                                    Notification::make()->title(__('admin.translate_failed'))->danger()->send();

                                    return;
                                }

                                $set('value', $translated);
                            }),
                    ]),
                ]),
        ])->columnSpanFull();
    }

    /**
     * DB locale=>value map → form split ({name}_default + {name}_locales rows).
     * Call from the Edit page's mutateFormDataBeforeFill().
     *
     * @param  array<string,mixed>  $data
     * @param  array<int,string>    $names
     * @return array<string,mixed>
     */
    public static function mutateBeforeFill(array $data, array $names): array
    {
        $default = AppLanguages::defaultCode();

        foreach ($names as $name) {
            $map = (isset($data[$name]) && is_array($data[$name])) ? $data[$name] : [];

            $data["{$name}_default"] = (string) ($map[$default] ?? '');

            $rows = [];
            foreach ($map as $code => $value) {
                if ($code === $default) {
                    continue;
                }
                $rows[] = ['lang' => $code, 'value' => (string) $value];
            }
            $data["{$name}_locales"] = $rows;

            unset($data[$name]);
        }

        return $data;
    }

    /**
     * Form split → DB locale=>value map. Lossless (keeps blank values; the
     * resolver handles blanks at read time). Call from the Create page's
     * mutateFormDataBeforeCreate() and the Edit page's mutateFormDataBeforeSave().
     *
     * @param  array<string,mixed>  $data
     * @param  array<int,string>    $names
     * @return array<string,mixed>
     */
    public static function mutateBeforeSave(array $data, array $names): array
    {
        $default = AppLanguages::defaultCode();

        foreach ($names as $name) {
            $map = [$default => (string) ($data["{$name}_default"] ?? '')];

            $rows = $data["{$name}_locales"] ?? [];
            if (is_array($rows)) {
                foreach ($rows as $row) {
                    $code = $row['lang'] ?? null;
                    if ($code && $code !== $default) {
                        $map[$code] = (string) ($row['value'] ?? '');
                    }
                }
            }

            $data[$name] = $map;
            unset($data["{$name}_default"], $data["{$name}_locales"]);
        }

        return $data;
    }

    /**
     * "Translate all": fill the BLANK rows of each attribute from its default
     * value (one Google call per attribute+target). Operates on the split form
     * state; the page re-fills the form afterwards so editors re-render.
     *
     * @param  array<string,mixed>  $state   the form state (split shape)
     * @param  array<string,bool>   $config  [attribute => isHtml]
     * @return array<string,mixed>           the updated form state
     */
    public static function fillMissing(array $state, array $config): array
    {
        $default = AppLanguages::defaultCode();
        $service = app(Translator::class);

        foreach ($config as $name => $html) {
            $source = (string) ($state["{$name}_default"] ?? '');
            if (trim($source) === '') {
                continue;
            }

            $rows = $state["{$name}_locales"] ?? [];
            if (! is_array($rows)) {
                continue;
            }

            // Group blank rows by target language so we translate once per target.
            $targets = [];
            foreach ($rows as $i => $row) {
                $code = $row['lang'] ?? null;
                $value = (string) ($row['value'] ?? '');
                if ($code && $code !== $default && trim($value) === '') {
                    $targets[$code][] = $i;
                }
            }

            foreach ($targets as $code => $indexes) {
                $translated = $service->translate($source, (string) $code, $default, (bool) $html);
                foreach ($indexes as $i) {
                    $rows[$i]['value'] = $translated;
                }
            }

            $state["{$name}_locales"] = $rows;
        }

        return $state;
    }

    /** Label for the default-language field: "English (default)". */
    private static function defaultLabel(): string
    {
        $code = AppLanguages::defaultCode();
        $name = self::names()[$code] ?? strtoupper($code);

        return $name . ' (' . __('admin.default') . ')';
    }

    /** Active non-default languages as [code => native name] for the row select. */
    private static function localeOptions(): array
    {
        $default = AppLanguages::defaultCode();
        $names = self::names();

        $options = [];
        foreach (AppLanguages::activeCodes() as $code) {
            if ($code === $default) {
                continue;
            }
            $options[$code] = $names[$code] ?? strtoupper($code);
        }

        return $options;
    }

    /** @return array<string,string> */
    private static function names(): array
    {
        return AppLanguages::names();
    }
}
