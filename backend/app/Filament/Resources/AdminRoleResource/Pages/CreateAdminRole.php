<?php

namespace App\Filament\Resources\AdminRoleResource\Pages;

use App\Filament\Resources\AdminRoleResource;
use App\Models\AdminRole;
use Filament\Resources\Pages\CreateRecord;
use Illuminate\Support\Str;

class CreateAdminRole extends CreateRecord
{
    protected static string $resource = AdminRoleResource::class;

    /** @var array<int, int> */
    protected array $permissionIds = [];

    protected function mutateFormDataBeforeCreate(array $data): array
    {
        // Pull the grouped permission selections out of $data (they aren't columns).
        $this->permissionIds = AdminRoleResource::extractPermissionIds($data);

        // `name` is the internal machine key (used by code/seeders); admins no
        // longer type it — derive a unique slug from the label (falls back to
        // "role-N" for non-latin labels where slug() comes back empty).
        $data['name'] = $this->uniqueRoleName($data['label'] ?? '');

        return $data;
    }

    private function uniqueRoleName(string $label): string
    {
        $base = Str::slug($label) ?: 'role';
        $name = $base;
        $suffix = 1;

        while (AdminRole::where('name', $name)->exists()) {
            $name = $base . '-' . (++$suffix);
        }

        return $name;
    }

    protected function afterCreate(): void
    {
        $this->record->permissions()->sync($this->permissionIds);
    }
}
