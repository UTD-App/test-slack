<?php

/**
 * UTD Studio manifest for the MOMENTS package (server-driven, fully editable).
 *
 * Exposes the moments feature as a design-time contract so UTD Studio can lay
 * out its screens visually — exactly like the Core/Chat manifests. The editor
 * reads this via GET /api/utd/manifest (X-UTD-Secret); it has NO hardcoded
 * knowledge of "moment". Adding/removing a field or action = editing THIS file.
 *
 * Authoring rules (docs/PACKAGE-AUTHORING-RULES.md): every visible piece is an
 * explicit Craft node the client can move/restyle/hide/delete — NO opaque
 * PackageWidget "black box". So both screens are built from
 * List/Container/Row/Text/Image/Icon, each dynamic value is a `binding`, and the
 * post-details page is its OWN default screen reached via `moment.open`.
 *
 * Runtime data + behaviour live on the Flutter side (flutter/lib/src/stac/):
 *   • registerMomentStacSources()  → moment.feed (list), moment.detail (object),
 *                                     moment.comments (list)
 *   • momentStacActionParsers()    → moment.toggleLike / open / postMenu /
 *                                     sendGift / addComment
 * The map keys returned by each source MUST match the binding keys below so the
 * designer's bindings resolve without any mapping.
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

// ── Screen A: feed — a List of explicit post cards (every part editable) ──
// Whole-row tap and the comment icon open the post detail (moment.open →
// /s/moment). The like / menu / gift buttons act on the pressed row (the base
// injects the row under `item` into per-row actions).
$feedWidgets = [
    'ROOT' => $node('Container', true, ['background' => '#f1f5f9', 'padding' => 0, 'gap' => 0, 'align' => 'stretch', 'flex' => 0], ['flist', 'fab'], null),

    'flist' => $node('List', true, ['source' => 'moment.feed', 'onItemTapAction' => 'moment.open', 'shrinkWrap' => false], ['card'], 'ROOT'),

    'card' => $node('Container', true, ['background' => '#ffffff', 'padding' => 12, 'gap' => 8, 'radius' => 12, 'align' => 'stretch'], ['hdr', 'body', 'media', 'acts'], 'flist'),

    // header: avatar + (name / time) + menu
    'hdr'  => $node('Row', true, ['gap' => 8, 'align' => 'center'], ['av', 'meta', 'menu'], 'card'),
    'av'   => $node('Image', false, ['binding' => 'moment.feed.user_avatar', 'src' => '', 'shape' => 'circle', 'width' => 44, 'height' => 44, 'fit' => 'cover'], [], 'hdr'),
    'meta' => $node('Container', true, ['flex' => 1, 'gap' => 2, 'align' => 'flex-start'], ['nm', 'tm'], 'hdr'),
    'nm'   => $node('Text', false, ['binding' => 'moment.feed.user_name', 'text' => '', 'fontSize' => 14, 'fontWeight' => 600, 'color' => '#0F172A', 'maxLines' => 1], [], 'meta'),
    'tm'   => $node('Text', false, ['binding' => 'moment.feed.created_at', 'text' => '', 'fontSize' => 12, 'fontWeight' => 400, 'color' => '#94A3B8', 'maxLines' => 1], [], 'meta'),
    'menu' => $node('Icon', false, ['name' => 'more_horiz', 'size' => 20, 'color' => '#94A3B8', 'onTapAction' => 'moment.postMenu'], [], 'hdr'),

    // body + media (media hides itself when the row has no image)
    'body'  => $node('Text', false, ['binding' => 'moment.feed.description', 'text' => '', 'fontSize' => 14, 'fontWeight' => 400, 'color' => '#0F172A', 'maxLines' => 0], [], 'card'),
    'media' => $node('Image', false, ['binding' => 'moment.feed.image', 'visibleBinding' => 'moment.feed.image', 'src' => '', 'height' => 220, 'fit' => 'cover', 'radius' => 8], [], 'card'),

    // actions: like / comment / gift, each with its count
    'acts' => $node('Row', true, ['gap' => 6, 'align' => 'center'], ['like', 'lc', 'cmt', 'cc', 'gift', 'gc'], 'card'),
    'like' => $node('Icon', false, ['name' => 'favorite_border', 'size' => 20, 'color' => '#EF4444', 'onTapAction' => 'moment.toggleLike'], [], 'acts'),
    'lc'   => $node('Text', false, ['binding' => 'moment.feed.like_num', 'text' => '0', 'fontSize' => 13, 'fontWeight' => 400, 'color' => '#64748B'], [], 'acts'),
    'cmt'  => $node('Icon', false, ['name' => 'chat_bubble_outline', 'size' => 20, 'color' => '#64748B', 'onTapAction' => 'moment.open'], [], 'acts'),
    'cc'   => $node('Text', false, ['binding' => 'moment.feed.comment_num', 'text' => '0', 'fontSize' => 13, 'fontWeight' => 400, 'color' => '#64748B'], [], 'acts'),
    'gift' => $node('Icon', false, ['name' => 'card_giftcard', 'size' => 20, 'color' => '#F59E0B', 'onTapAction' => 'moment.sendGift'], [], 'acts'),
    'gc'   => $node('Text', false, ['binding' => 'moment.feed.gifts_count', 'text' => '0', 'fontSize' => 13, 'fontWeight' => 400, 'color' => '#64748B'], [], 'acts'),

    // floating "add moment" button (lifts to the scaffold)
    'fab' => $node('Fab', false, ['glyph' => 'add', 'bg' => '#2563eb', 'route' => '/moment/add'], [], 'ROOT'),
];

// ── Screen B: moment — post detail (Scope) + comments (List) + composer ──
$momentWidgets = [
    'ROOT' => $node('Container', true, ['background' => '#ffffff', 'padding' => 0, 'gap' => 0, 'align' => 'stretch', 'flex' => 0], ['scope', 'div', 'clist', 'composer'], null),

    // the opened post (bound to the single-object source moment.detail)
    'scope'  => $node('Scope', true, ['source' => 'moment.detail'], ['dcard'], 'ROOT'),
    'dcard'  => $node('Container', true, ['padding' => 12, 'gap' => 8, 'align' => 'stretch'], ['dhdr', 'dbody', 'dmedia'], 'scope'),
    'dhdr'   => $node('Row', true, ['gap' => 8, 'align' => 'center'], ['dav', 'dmeta'], 'dcard'),
    'dav'    => $node('Image', false, ['binding' => 'moment.detail.user_avatar', 'src' => '', 'shape' => 'circle', 'width' => 44, 'height' => 44, 'fit' => 'cover'], [], 'dhdr'),
    'dmeta'  => $node('Container', true, ['flex' => 1, 'gap' => 2, 'align' => 'flex-start'], ['dnm', 'dtm'], 'dhdr'),
    'dnm'    => $node('Text', false, ['binding' => 'moment.detail.user_name', 'text' => '', 'fontSize' => 15, 'fontWeight' => 600, 'color' => '#0F172A', 'maxLines' => 1], [], 'dmeta'),
    'dtm'    => $node('Text', false, ['binding' => 'moment.detail.created_at', 'text' => '', 'fontSize' => 12, 'fontWeight' => 400, 'color' => '#94A3B8', 'maxLines' => 1], [], 'dmeta'),
    'dbody'  => $node('Text', false, ['binding' => 'moment.detail.description', 'text' => '', 'fontSize' => 15, 'fontWeight' => 400, 'color' => '#0F172A', 'maxLines' => 0], [], 'dcard'),
    'dmedia' => $node('Image', false, ['binding' => 'moment.detail.image', 'visibleBinding' => 'moment.detail.image', 'src' => '', 'height' => 240, 'fit' => 'cover', 'radius' => 8], [], 'dcard'),

    'div' => $node('Divider', false, ['color' => '#e5e7eb', 'thickness' => 1], [], 'ROOT'),

    // comments list (fills the space between the post and the composer)
    'clist' => $node('List', true, ['source' => 'moment.comments', 'shrinkWrap' => false], ['crow'], 'ROOT'),
    'crow'  => $node('Row', true, ['gap' => 8, 'align' => 'flex-start', 'padding' => 8], ['cav', 'cmeta'], 'clist'),
    'cav'   => $node('Image', false, ['binding' => 'moment.comments.author_avatar', 'src' => '', 'shape' => 'circle', 'width' => 36, 'height' => 36, 'fit' => 'cover'], [], 'crow'),
    'cmeta' => $node('Container', true, ['flex' => 1, 'gap' => 2, 'align' => 'flex-start'], ['cnm', 'cbody', 'ctm'], 'crow'),
    'cnm'   => $node('Text', false, ['binding' => 'moment.comments.author_name', 'text' => '', 'fontSize' => 13, 'fontWeight' => 600, 'color' => '#0F172A', 'maxLines' => 1], [], 'cmeta'),
    'cbody' => $node('Text', false, ['binding' => 'moment.comments.body', 'text' => '', 'fontSize' => 14, 'fontWeight' => 400, 'color' => '#334155', 'maxLines' => 0], [], 'cmeta'),
    'ctm'   => $node('Text', false, ['binding' => 'moment.comments.created_at', 'text' => '', 'fontSize' => 11, 'fontWeight' => 400, 'color' => '#94A3B8', 'maxLines' => 1], [], 'cmeta'),

    // composer: live text field + send (reads the field by id, posts on the open moment)
    'composer' => $node('Row', true, ['gap' => 8, 'align' => 'center', 'padding' => 8, 'background' => '#f8fafc'], ['cfield', 'csend'], 'ROOT'),
    'cfield'   => $node('TextField', false, ['fieldId' => 'commentField', 'placeholder' => 'اكتب تعليقًا…', 'live' => true, 'flex' => 1, 'fillColor' => '#f1f5f9', 'radius' => 20], [], 'composer'),
    'csend'    => $node('Icon', false, ['name' => 'send', 'size' => 24, 'color' => '#2563eb', 'onTapAction' => 'moment.addComment', 'onTapParams' => ['commentField' => 'commentField']], [], 'composer'),
];

return [
    'key'     => 'moment',
    'name'    => 'Moments',
    'icon'    => 'dynamic_feed',
    'screens' => ['feed', 'moment'],

    // Bindable fields the designer sees in the Studio palette, per screen. Every
    // `binding` used in the trees above MUST be declared here (else it won't show
    // as a bindable attribute) AND have a matching Flutter source key.
    'elements' => [
        // feed (post card)
        ['key' => 'user_name',   'label' => 'اسم صاحب المنشور',  'type' => 'string',    'screen' => 'feed'],
        ['key' => 'user_avatar', 'label' => 'صورة صاحب المنشور', 'type' => 'image_url', 'screen' => 'feed'],
        ['key' => 'description', 'label' => 'نص المنشور',         'type' => 'string',    'screen' => 'feed'],
        ['key' => 'image',       'label' => 'صورة المنشور',       'type' => 'image_url', 'screen' => 'feed'],
        ['key' => 'like_num',    'label' => 'عدد الإعجابات',       'type' => 'int',       'screen' => 'feed'],
        ['key' => 'comment_num', 'label' => 'عدد التعليقات',       'type' => 'int',       'screen' => 'feed'],
        ['key' => 'gifts_count', 'label' => 'عدد الهدايا',         'type' => 'int',       'screen' => 'feed'],
        ['key' => 'created_at',  'label' => 'التاريخ',             'type' => 'datetime',  'screen' => 'feed'],
        ['key' => 'is_like',     'label' => 'معجب؟',              'type' => 'bool', 'screen' => 'feed', 'hidden' => true],
        ['key' => 'is_owner',    'label' => 'مالك المنشور؟',       'type' => 'bool', 'screen' => 'feed', 'hidden' => true],
        ['key' => 'moment_id',   'label' => 'معرّف المنشور',       'type' => 'id',   'screen' => 'feed', 'hidden' => true],
        ['key' => 'user_id',     'label' => 'معرّف المستخدم',      'type' => 'id',   'screen' => 'feed', 'hidden' => true],

        // moment (detail post)
        ['key' => 'user_name',   'label' => 'اسم صاحب المنشور',  'type' => 'string',    'screen' => 'moment'],
        ['key' => 'user_avatar', 'label' => 'صورة صاحب المنشور', 'type' => 'image_url', 'screen' => 'moment'],
        ['key' => 'description', 'label' => 'نص المنشور',         'type' => 'string',    'screen' => 'moment'],
        ['key' => 'image',       'label' => 'صورة المنشور',       'type' => 'image_url', 'screen' => 'moment'],
        ['key' => 'created_at',  'label' => 'التاريخ',             'type' => 'datetime',  'screen' => 'moment'],
        // moment (a comment row)
        ['key' => 'author_name',   'label' => 'اسم المُعلّق',     'type' => 'string',    'screen' => 'moment'],
        ['key' => 'author_avatar', 'label' => 'صورة المُعلّق',    'type' => 'image_url', 'screen' => 'moment'],
        ['key' => 'body',          'label' => 'نص التعليق',       'type' => 'string',    'screen' => 'moment'],
        ['key' => 'comment_id',    'label' => 'معرّف التعليق',    'type' => 'id', 'screen' => 'moment', 'hidden' => true],
    ],

    // Single-object source: the opened post (Scope → utdObject). Resolved on the
    // client by registerMomentStacSources() from MomentStacBridge.currentMoment.
    'object_sources' => [
        [
            'key'      => 'moment.detail',
            'label'    => 'المنشور المفتوح',
            'screen'   => 'moment',
            'provides' => [
                ['key' => 'user_name',   'label' => 'اسم صاحب المنشور',  'type' => 'string'],
                ['key' => 'user_avatar', 'label' => 'صورة صاحب المنشور', 'type' => 'image_url'],
                ['key' => 'description', 'label' => 'نص المنشور',         'type' => 'string'],
                ['key' => 'image',       'label' => 'صورة المنشور',       'type' => 'image_url'],
                ['key' => 'created_at',  'label' => 'التاريخ',             'type' => 'datetime'],
                ['key' => 'like_num',    'label' => 'عدد الإعجابات',       'type' => 'int'],
                ['key' => 'comment_num', 'label' => 'عدد التعليقات',       'type' => 'int'],
                ['key' => 'gifts_count', 'label' => 'عدد الهدايا',         'type' => 'int'],
            ],
        ],
    ],

    // Repeating list sources: a `List` bound to one of these renders one row per
    // record, each row's children binding to the keys it provides.
    'list_sources' => [
        [
            'key'      => 'moment.feed',
            'label'    => 'منشورات اللحظات',
            'screen'   => 'feed',
            'provides' => [
                ['key' => 'user_name',   'label' => 'اسم صاحب المنشور',  'type' => 'string'],
                ['key' => 'user_avatar', 'label' => 'صورة صاحب المنشور', 'type' => 'image_url'],
                ['key' => 'description', 'label' => 'نص المنشور',         'type' => 'string'],
                ['key' => 'image',       'label' => 'صورة المنشور',       'type' => 'image_url'],
                ['key' => 'like_num',    'label' => 'عدد الإعجابات',       'type' => 'int'],
                ['key' => 'comment_num', 'label' => 'عدد التعليقات',       'type' => 'int'],
                ['key' => 'gifts_count', 'label' => 'عدد الهدايا',         'type' => 'int'],
                ['key' => 'created_at',  'label' => 'التاريخ',             'type' => 'datetime'],
                ['key' => 'is_like',     'label' => 'معجب؟',              'type' => 'bool'],
                ['key' => 'is_owner',    'label' => 'مالك المنشور؟',       'type' => 'bool'],
                ['key' => 'moment_id',   'label' => 'معرّف المنشور',       'type' => 'id'],
                ['key' => 'user_id',     'label' => 'معرّف المستخدم',      'type' => 'id'],
            ],
        ],
        [
            'key'      => 'moment.comments',
            'label'    => 'تعليقات المنشور',
            'screen'   => 'moment',
            'provides' => [
                ['key' => 'author_name',   'label' => 'اسم المُعلّق',  'type' => 'string'],
                ['key' => 'author_avatar', 'label' => 'صورة المُعلّق', 'type' => 'image_url'],
                ['key' => 'body',          'label' => 'نص التعليق',    'type' => 'string'],
                ['key' => 'created_at',    'label' => 'التاريخ',        'type' => 'datetime'],
                ['key' => 'comment_id',    'label' => 'معرّف التعليق', 'type' => 'id'],
                ['key' => 'user_id',       'label' => 'معرّف المستخدم','type' => 'id'],
            ],
        ],
    ],

    // `action_elements` are the source of truth for actions:
    //   produces      → the Stac actionType emitted on the client (moment.*)
    //   default_shape → suggested editor widget
    //   context:'item'→ runs inside a repeated row; the base injects the pressed
    //                   row under `item` so the (package) parser reads its id.
    'action_elements' => [
        [
            'key' => 'toggle_like', 'label' => 'إعجاب',
            'produces' => 'moment.toggleLike', 'default_shape' => 'button',
            'screen' => 'feed', 'context' => 'item',
        ],
        [
            'key' => 'open_moment', 'label' => 'فتح المنشور',
            'produces' => 'moment.open', 'default_shape' => 'list_item',
            'screen' => 'feed', 'context' => 'item', 'opens' => 'moment',
        ],
        [
            'key' => 'post_menu', 'label' => 'قائمة المنشور (إبلاغ/حذف)',
            'produces' => 'moment.postMenu', 'default_shape' => 'button',
            'screen' => 'feed', 'context' => 'item',
        ],
        [
            'key' => 'send_gift', 'label' => 'إرسال هدية',
            'produces' => 'moment.sendGift', 'default_shape' => 'button',
            'screen' => 'feed', 'context' => 'item',
        ],
        [
            'key' => 'add_comment', 'label' => 'إضافة تعليق',
            'produces' => 'moment.addComment', 'default_shape' => 'button', 'screen' => 'moment',
            'params' => [
                ['key' => 'commentField', 'label' => 'حقل التعليق', 'type' => 'field_ref'],
            ],
        ],
    ],

    // ── Ready-to-edit default screens (seeded by UTD Studio on Sync) ──
    'default_screens' => [
        [
            'name'         => 'feed',
            'label'        => 'اللحظات',
            'icon'         => '📸',
            'version'      => '2.0.0',
            'nav'          => true,
            'navIcon'      => 'dynamic_feed',
            'order'        => 10,
            'role'         => null,
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => 'moment',
            'chrome'       => ['appBar' => ['enabled' => true, 'title' => 'اللحظات', 'bg' => '#ffffff', 'actions' => []]],
            'widgets'      => $feedWidgets,
        ],
        [
            'name'         => 'moment',
            'label'        => 'تفاصيل المنشور',
            'icon'         => '📝',
            'version'      => '2.0.0',
            'nav'          => false,
            'navIcon'      => 'dynamic_feed',
            'order'        => 11,
            'role'         => null,
            'requiresAuth' => true,
            'showOnce'     => false,
            'opens'        => null,
            'chrome'       => ['appBar' => ['enabled' => true, 'title' => 'المنشور', 'bg' => '#ffffff', 'actions' => []]],
            'widgets'      => $momentWidgets,
        ],
    ],
];
