<?php

namespace App\Filament\Resources\PageResource\Pages;

use App\Filament\Resources\PageResource;
use App\Support\AppLanguages;
use App\Support\Translatable\DefaultLocaleForm;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditPage extends EditRecord
{
    protected static string $resource = PageResource::class;

    /** Attributes edited here as the default-language value only. */
    protected array $translatable = ['title', 'body'];

    protected function getHeaderActions(): array
    {
        return [DeleteAction::make()];
    }

    protected function mutateFormDataBeforeFill(array $data): array
    {
        return DefaultLocaleForm::toForm($data, $this->translatable, AppLanguages::defaultCode());
    }

    /** Merge the edited default value back in, PRESERVING other-language translations. */
    protected function mutateFormDataBeforeSave(array $data): array
    {
        $existing = [];
        foreach ($this->translatable as $name) {
            $existing[$name] = $this->record->getAttribute($name);
        }

        return DefaultLocaleForm::toModel($data, $this->translatable, AppLanguages::defaultCode(), $existing);
    }
}
