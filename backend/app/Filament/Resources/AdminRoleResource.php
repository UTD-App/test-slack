<?php

namespace App\Filament\Resources;

use App\Filament\Resources\AdminRoleResource\Pages;
use App\Models\AdminRole;
use App\Services\AdminPermissionRegistry;
use App\Services\PackageRegistry;
use Filament\Forms\Components\CheckboxList;
use Filament\Forms\Components\Grid;
use Filament\Forms\Components\Section;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Form;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

/**
 * Manage admin ROLES and the granular permissions each one grants (the
 * dashboard's access-control screen). A role is a bundle of admin_permissions;
 * AdminUser access resolves through these (see AuthServiceProvider's Gate).
 *
 * The permission matrix is grouped by PACKAGE → one collapsible card per package
 * (base expanded, the rest collapsed so the screen stays short), each holding a
 * responsive grid of per-resource ability lists. This scales cleanly as more
 * packages are installed. The matrix fields are NOT model attributes — they are
 * hydrated from / synced to the role's permissions relationship by the
 * Create/Edit pages.
 *
 * `super_admin` is protected: it bypasses every check, so its matrix is shown
 * read-only and it cannot be deleted.
 */
class AdminRoleResource extends BaseResource
{
    protected static ?string $model = AdminRole::class;
    protected static ?string $navigationIcon = 'heroicon-o-key';
    protected static ?int $navigationSort = 6;

    protected static ?string $permissionPrefix = 'admin_roles';
    protected static ?string $navigationGroup = 'Access Control';

    public static function getNavigationGroup(): ?string { return __('admin.nav_access_control'); }
    public static function getModelLabel(): string { return __('admin.admin_role'); }
    public static function getPluralModelLabel(): string { return __('admin.admin_roles'); }

    public static function form(Form $form): Form
    {
        // Group the catalog by PACKAGE first, base before the rest.
        $byPackage = app(AdminPermissionRegistry::class)->all()->groupBy('package');

        // The permission catalog is upsert-only and is never pruned, so a package that
        // was once installed leaves its rows behind in admin_permissions. Without this
        // filter those orphan rows render as "ghost" cards for modules that are no
        // longer present (or are currently disabled). Only show cards for packages that
        // are actually live — installed & enabled, plus base.
        $visible = static::visiblePackageSlugs();
        $byPackage = $byPackage->filter(fn ($perms, string $package): bool => in_array($package, $visible, true));

        $packages = $byPackage->keys()
            ->sort(fn ($a, $b) => $a === 'base' ? -1 : ($b === 'base' ? 1 : strcmp($a, $b)))
            ->values();

        $packageCards = [];
        foreach ($packages as $package) {
            $perms = $byPackage[$package];

            // Each resource = one labelled ability list; laid out in a responsive grid.
            $resourceLists = [];
            foreach ($perms->groupBy('group') as $group => $groupPerms) {
                $resourceLists[] = CheckboxList::make('perm_' . $group)
                    ->label(static::groupLabel($group))
                    ->options($groupPerms->mapWithKeys(fn ($p) => [$p->id => __($p->label_key)])->all())
                    ->columns(2)
                    ->bulkToggleable()
                    // super_admin bypasses everything → its matrix is read-only.
                    ->disabled(fn (?Model $record): bool => $record?->name === 'super_admin');
            }

            $packageCards[] = Section::make(static::packageLabel($package))
                ->description(__('admin.permissions') . ': ' . $perms->count())
                ->icon($package === 'base' ? 'heroicon-o-cube' : 'heroicon-o-puzzle-piece')
                ->collapsible()
                ->collapsed($package !== 'base')
                ->compact()
                ->schema([
                    Grid::make(['default' => 1, 'lg' => 2, 'xl' => 3])->schema($resourceLists),
                ]);
        }

        return $form->schema([
            Section::make(__('admin.role_details'))
                ->schema([
                    TextInput::make('label')
                        ->label(__('admin.role_label'))
                        ->required()
                        ->maxLength(120),
                    Textarea::make('description')
                        ->label(__('admin.role_description'))
                        ->helperText(__('admin.role_description_hint'))
                        ->rows(2)
                        ->maxLength(255)
                        // super_admin is structural — keep its details read-only too.
                        ->disabled(fn (?Model $record): bool => $record?->name === 'super_admin')
                        ->columnSpanFull(),
                ])
                ->columns(1),
            ...$packageCards,
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('label')->label(__('admin.role_label'))->weight('bold')->sortable()->searchable(),
                TextColumn::make('description')->label(__('admin.role_description'))->limit(60)->wrap()->placeholder('—'),
                TextColumn::make('permissions_count')->counts('permissions')->label(__('admin.permissions')),
                TextColumn::make('users_count')->counts('users')->label(__('admin.nav_admin_users')),
            ])
            ->defaultSort('id');
    }

    /** @var array<string, string>|null  permissionPrefix => translated plural label */
    protected static ?array $resourceLabelMap = null;

    /**
     * Heading for a permission group, resolved in order:
     *   1. an explicit curated `admin.permgroup_<group>` label (base groups), then
     *   2. the matching Filament resource's own translated plural label — so an
     *      auto-discovered package group (e.g. gift_categories) reuses the label it
     *      already shows in the sidebar ("فئات الهدايا") with NO extra translation
     *      work, then
     *   3. a humanised fallback (gift_logs → "Gift Logs").
     */
    public static function groupLabel(string $group): string
    {
        $key = 'admin.permgroup_' . $group;
        $label = __($key);
        if ($label !== $key) {
            return $label;
        }

        $map = static::resourceLabelByPrefix();
        if (isset($map[$group])) {
            return $map[$group];
        }

        return Str::headline($group);
    }

    /**
     * Build (and memoise) a map of each registered resource's permissionPrefix to
     * its translated plural label, so permission groups can reuse the resource's
     * existing i18n instead of duplicating it.
     *
     * @return array<string, string>
     */
    protected static function resourceLabelByPrefix(): array
    {
        if (static::$resourceLabelMap !== null) {
            return static::$resourceLabelMap;
        }

        $map = [];
        foreach (\Filament\Facades\Filament::getPanel('admin')->getResources() as $resource) {
            if (! is_subclass_of($resource, BaseResource::class)) {
                continue;
            }

            $prefix = $resource::getPermissionPrefix();
            if (! $prefix) {
                continue;
            }

            try {
                $map[$prefix] = $resource::getPluralModelLabel();
            } catch (\Throwable) {
                // A misbehaving resource shouldn't break the whole role matrix.
            }
        }

        return static::$resourceLabelMap = $map;
    }

    /**
     * Heading for a package card: explicit `admin.pkg_<slug>` when present, else a
     * humanised fallback (so a freshly installed package reads nicely with no
     * translation work).
     */
    public static function packageLabel(string $package): string
    {
        $key = 'admin.pkg_' . $package;
        $label = __($key);

        return $label === $key ? Str::headline($package) : $label;
    }

    /**
     * Package slugs whose permission cards are shown in the matrix: the live set
     * (installed + enabled, always including base). Grants for packages outside this
     * set are hidden from the form, so the save path must preserve them rather than
     * sync them away (see EditAdminRole::afterSave).
     *
     * @return array<int, string>
     */
    public static function visiblePackageSlugs(): array
    {
        return app(PackageRegistry::class)->enabledSlugs();
    }

    public static function canDelete(Model $record): bool
    {
        // super_admin is structural — never deletable.
        if ($record->name === 'super_admin') {
            return false;
        }
        return parent::canDelete($record);
    }

    /**
     * Collect selected permission ids from the grouped `perm_<group>` fields and
     * strip those keys from $data (they are not model attributes).
     *
     * @param  array<string, mixed>  $data
     * @return array<int, int>
     */
    public static function extractPermissionIds(array &$data): array
    {
        $ids = [];
        foreach (array_keys($data) as $key) {
            if (str_starts_with($key, 'perm_')) {
                $ids = array_merge($ids, (array) $data[$key]);
                unset($data[$key]);
            }
        }

        return array_values(array_unique(array_map('intval', $ids)));
    }

    /**
     * Spread a role's current permission ids back into the `perm_<group>` form
     * fields (for hydrating the Edit form).
     *
     * @return array<string, array<int, int>>
     */
    public static function hydratePermissionFields(AdminRole $role): array
    {
        $role->loadMissing('permissions');

        $data = [];
        foreach (array_keys(app(AdminPermissionRegistry::class)->grouped()) as $group) {
            $data['perm_' . $group] = $role->permissions
                ->where('group', $group)
                ->pluck('id')
                ->all();
        }

        return $data;
    }

    public static function getPages(): array
    {
        return [
            'index'  => Pages\ListAdminRoles::route('/'),
            'create' => Pages\CreateAdminRole::route('/create'),
            'edit'   => Pages\EditAdminRole::route('/{record}/edit'),
        ];
    }
}
