<?php

namespace App\Filament\Resources\PageResource\Pages;

use App\Filament\Resources\PageResource;
use App\Support\AppLanguages;
use App\Support\Translatable\DefaultLocaleForm;
use Filament\Resources\Pages\CreateRecord;

class CreatePage extends CreateRecord
{
    protected static string $resource = PageResource::class;

    /** Attributes edited here as the default-language value only. */
    protected array $translatable = ['title', 'body'];

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        return DefaultLocaleForm::toModel($data, $this->translatable, AppLanguages::defaultCode());
    }
}
