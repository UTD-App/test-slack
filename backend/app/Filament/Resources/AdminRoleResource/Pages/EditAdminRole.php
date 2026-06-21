<?php

namespace App\Filament\Resources\AdminRoleResource\Pages;

use App\Filament\Resources\AdminRoleResource;
use Filament\Actions\DeleteAction;
use Filament\Resources\Pages\EditRecord;

class EditAdminRole extends EditRecord
{
    protected static string $resource = AdminRoleResource::class;

    /** @var array<int, int> */
    protected array $permissionIds = [];

    protected function mutateFormDataBeforeFill(array $data): array
    {
        // Spread the role's current grants into the grouped perm_<group> fields.
        return array_merge($data, AdminRoleResource::hydratePermissionFields($this->record));
    }

    protected function mutateFormDataBeforeSave(array $data): array
    {
        $this->permissionIds = AdminRoleResource::extractPermissionIds($data);

        return $data;
    }

    protected function afterSave(): void
    {
        // super_admin's matrix is read-only (and it bypasses everything), so a
        // disabled/empty submit must never strip its grants.
        if ($this->record->name === 'super_admin') {
            return;
        }

        // The matrix only renders cards for live packages, so $permissionIds covers
        // visible packages only. Preserve any grants belonging to hidden packages
        // (e.g. a temporarily disabled module) so the sync doesn't silently drop them.
        $hiddenGrants = $this->record->permissions()
            ->whereNotIn('package', AdminRoleResource::visiblePackageSlugs())
            ->pluck('admin_permissions.id')
            ->all();

        $this->record->permissions()->sync(array_merge($this->permissionIds, $hiddenGrants));
    }

    protected function getHeaderActions(): array
    {
        return [
            DeleteAction::make()
                ->visible(fn (): bool => $this->record->name !== 'super_admin'),
        ];
    }
}
