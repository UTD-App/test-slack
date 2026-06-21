<?php

namespace App\Filament\Resources\EmailTemplateResource\Pages;

use App\Filament\Resources\EmailTemplateResource;
use App\Models\EmailTemplate;
use Filament\Resources\Pages\ListRecords;

class ListEmailTemplates extends ListRecords
{
    protected static string $resource = EmailTemplateResource::class;

    public function mount(): void
    {
        // Make sure every registered template type has a (default-filled) row so
        // the list shows them all, even before anyone has edited one.
        EmailTemplate::ensureRegisteredRows();

        parent::mount();
    }
}
