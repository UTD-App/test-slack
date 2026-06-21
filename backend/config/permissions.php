<?php

/**
 * Base ADMIN permission catalog (admin dashboard only).
 *
 * Compact map: group => [abilities]. Synced into the `admin_permissions` table by
 * `php artisan utd:sync-packages` via AdminPermissionRegistry::register(). Each
 * entry expands to a permission key `<group>.<ability>` (e.g. users.view, users.ban).
 *
 * Packages add their OWN admin permissions through the `adminPermissions()` hook on
 * BaseModuleServiceProvider (same shape), so the platform stays modular.
 *
 * Labels: group heading -> admin.permgroup_<group>; ability -> admin.ability_<ability>.
 */
return [
    'users'         => ['view', 'ban'],                       // read-only list + ban/unban
    'admin_users'   => ['view', 'create', 'update', 'delete'],
    'admin_roles'   => ['view', 'create', 'update', 'delete'],
    'settings'      => ['view', 'update'],                    // settings page
    'social_media'  => ['view', 'update'],                    // social/contact links page
    'languages'     => ['view', 'create', 'update', 'delete'],
    'pages'         => ['view', 'create', 'update', 'delete'],
    'email_templates' => ['view', 'update'],                  // edit-only (registry-driven)
    'menu'          => ['view', 'create', 'update', 'delete'],
    'stac'          => ['view'],                              // read-only (writes via Studio API)
    'packages'      => ['view', 'update'],                    // enable/disable + reorder
    'notifications' => ['view', 'broadcast'],                 // read-only feed + announcement
    'audit'         => ['view'],                              // read-only admin audit trail
];
