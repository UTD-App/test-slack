<?php

/**
 * UTD Studio manifest for the MOMENT package (server-driven feed).
 *
 * Exposes the moments feed as a design-time contract so UTD Studio can lay out
 * the feed screen visually — exactly like the Core/Chat manifests. The editor
 * reads this via GET /api/utd/manifest (X-UTD-Secret); it has NO hardcoded
 * knowledge of "moment". Adding/removing a field or action = editing THIS file.
 *
 * Runtime data is provided on the Flutter side by `registerMomentStacSources()`
 * (flutter/lib/src/stac/moment_stac_sources.dart). The keys below MUST match the
 * map that source returns for each row, so bindings resolve without any mapping:
 *   list source `moment.feed` → [{ description, image, user_name, user_avatar,
 *                                  like_num, comment_num, gifts_count, is_like,
 *                                  created_at, moment_id, user_id }]
 *
 * `action_elements` are the source of truth for actions:
 *   - `produces`      → the Stac `actionType` emitted on the client (moment.*)
 *   - `default_shape` → suggested editor widget (button | list_item | input | switch)
 *   - `context:'item'`→ the action runs inside a repeated row; the base injects the
 *                       pressed row under `item`, so the (package-owned) parser can
 *                       read its id. See flutter/lib/src/stac/moment_actions.dart.
 *
 * `default_screens` ships a ready-to-edit `feed` screen seeded by UTD Studio on
 * first Sync. It hosts the package's own `moment.feed` widget — a PackageWidget
 * that renders the REAL interactive feed in Flutter (see
 * flutter/lib/src/stac/moment_feed_parser.dart → MomentFeedView): like,
 * comments, likes, report, delete, image preview, gifts, pull-to-refresh and
 * infinite scroll all work natively. Plus a floating "add" button (route
 * /moment/add). Shape mirrors the Core manifest (utd_manifest_core.php).
 */

// ── Craft node helper (mirrors utd_manifest_core.php / the Studio scripts) ──
$node = function (string $name, bool $canvas, array $props, array $kids = [], ?string $parent = null): array {
    $n = [
        'type'        => ['resolvedName' => $name],
        'isCanvas'    => $canvas,
        'props'       => $props,
        'displayName' => $name,
        'hidden'      => false,
        'nodes'       => $kids,
        'linkedNodes' => [],
    ];
    if ($parent !== null) {
        $n['parent'] = $parent;
    }
    return $n;
};

// feed — the package draws its own feed (moment.feed PackageWidget, fills the
// screen) + a floating add button. No standard-widget card here: the base
// runtime only injects the row data (`item`) on a whole-row tap, so inner
// per-row buttons (like/comment) wouldn't resolve their id. Drawing the feed in
// Flutter keeps EVERY button working.
$feedWidgets = [
    'ROOT' => $node('Container', true, [
        'background' => '#ffffff', 'padding' => 0, 'gap' => 0, 'align' => 'stretch', 'flex' => 0,
    ], ['feed', 'fab'], null),
    'feed' => $node('PackageWidget', false, [
        'widgetType' => 'moment.feed',
        'label'      => 'موجز اللحظات',
        'props'      => new stdClass(),
        'flex'       => 1,
        'context'    => [],
        'variants'   => [],
    ], [], 'ROOT'),
    'fab'  => $node('Fab', false, [
        'glyph' => 'add', 'bg' => '#2563eb', 'route' => '/moment/add',
    ], [], 'ROOT'),
];

return [
    'key'     => 'moment',
    'name'    => 'Moments',
    'icon'    => 'dynamic_feed',
    'screens' => ['feed'],

    // Per-row display bindings available on the feed screen.
    'elements' => [
        ['key' => 'description', 'label' => 'النص',            'type' => 'string',    'screen' => 'feed'],
        ['key' => 'image',       'label' => 'صورة المنشور',     'type' => 'image_url', 'screen' => 'feed'],
        ['key' => 'user_name',   'label' => 'اسم صاحب المنشور', 'type' => 'string',    'screen' => 'feed'],
        ['key' => 'user_avatar', 'label' => 'صورة صاحب المنشور','type' => 'image_url', 'screen' => 'feed'],
        ['key' => 'like_num',    'label' => 'عدد الإعجابات',     'type' => 'int',       'screen' => 'feed'],
        ['key' => 'comment_num', 'label' => 'عدد التعليقات',     'type' => 'int',       'screen' => 'feed'],
        ['key' => 'gifts_count', 'label' => 'عدد الهدايا',       'type' => 'int',       'screen' => 'feed'],
        ['key' => 'created_at',  'label' => 'التاريخ',           'type' => 'datetime',  'screen' => 'feed'],
        // hidden: used by logic/actions, not shown directly in the binding palette.
        ['key' => 'is_like',     'label' => 'معجب؟',            'type' => 'bool', 'screen' => 'feed', 'hidden' => true],
        ['key' => 'moment_id',   'label' => 'معرّف المنشور',     'type' => 'id',   'screen' => 'feed', 'hidden' => true],
        ['key' => 'user_id',     'label' => 'معرّف المستخدم',    'type' => 'id',   'screen' => 'feed', 'hidden' => true],
    ],

    // Repeating list source: a `utdList` bound to `moment.feed` renders one row
    // per moment, each row's children binding to the element keys above. Resolved
    // on the client by `registerMomentStacSources()`.
    'list_sources' => [
        [
            'key'      => 'moment.feed',
            'label'    => 'منشورات اللحظات',
            'screen'   => 'feed',
            'provides' => [
                ['key' => 'description', 'label' => 'النص',            'type' => 'string'],
                ['key' => 'image',       'label' => 'صورة المنشور',     'type' => 'image_url'],
                ['key' => 'user_name',   'label' => 'اسم صاحب المنشور', 'type' => 'string'],
                ['key' => 'user_avatar', 'label' => 'صورة صاحب المنشور','type' => 'image_url'],
                ['key' => 'like_num',    'label' => 'عدد الإعجابات',     'type' => 'int'],
                ['key' => 'comment_num', 'label' => 'عدد التعليقات',     'type' => 'int'],
                ['key' => 'gifts_count', 'label' => 'عدد الهدايا',       'type' => 'int'],
                ['key' => 'created_at',  'label' => 'التاريخ',           'type' => 'datetime'],
                ['key' => 'is_like',     'label' => 'معجب؟',            'type' => 'bool'],
                ['key' => 'moment_id',   'label' => 'معرّف المنشور',     'type' => 'id'],
                ['key' => 'user_id',     'label' => 'معرّف المستخدم',    'type' => 'id'],
            ],
        ],
    ],

    'action_elements' => [
        // Like / unlike the pressed moment (mutate). Reads the row id from `item`.
        [
            'key' => 'toggle_like', 'label' => 'إعجاب',
            'produces' => 'moment.toggleLike', 'default_shape' => 'button',
            'screen' => 'feed', 'context' => 'item',
        ],
        // Drill-down: open the author's moments page.
        [
            'key' => 'open_moment', 'label' => 'فتح منشورات صاحب اللحظة',
            'produces' => 'moment.open', 'default_shape' => 'list_item',
            'screen' => 'feed', 'context' => 'item', 'opens' => 'feed',
        ],
    ],

    // Package-drawn widgets (Studio palette). Each MUST have a matching Flutter
    // StacParser of the same `type` — here `moment.feed` (moment_feed_parser.dart).
    'widgets' => [
        ['type' => 'moment.feed', 'label' => 'موجز اللحظات', 'screen' => 'feed', 'icon' => 'dynamic_feed'],
    ],

    // ── Ready-to-edit default screen (seeded by UTD Studio on Sync) ──
    'default_screens' => [
        [
            'name'         => 'feed',
            'label'        => 'اللحظات',
            'icon'         => '📸',
            'version'      => '1.0.0',
            'nav'          => true,
            'navIcon'      => 'dynamic_feed',
            'order'        => 10,
            'role'         => null,
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => true, 'title' => 'اللحظات', 'bg' => '#ffffff', 'actions' => []]],
            'widgets'      => $feedWidgets,
        ],
    ],
];
