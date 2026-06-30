<?php

// Arabic values for the Wallet UI strings (the Flutter `wallet.*` keys). Nested
// arrays flatten to dot-keys (e.g. tx_type.admin_charge -> `wallet.tx_type.admin_charge`).

return [
    'title'           => 'المحفظة',
    'coins'           => 'كوينز',
    'transactions'    => 'المعاملات',
    'no_transactions' => 'لا توجد معاملات بعد',
    'filter'          => 'تصفية',
    'clear_filter'    => 'مسح',
    'something_wrong' => 'حدث خطأ ما',
    'retry'           => 'إعادة المحاولة',

    // تسميات أنواع المعاملات — تطابق تعداد CoinTransactionType (+ سبب
    // admin_deduct المستخدم في ChargeService). يرجع التطبيق إلى النص المُنسَّق
    // عند غياب المفتاح، فتُعرض الأنواع الجديدة أيضًا.
    'tx_type' => [
        'admin_charge'               => 'شحن إداري',
        'admin_deduct'               => 'خصم إداري',
        'area_manager_charge'        => 'شحن مدير المنطقة',
        'bd_charge'                  => 'شحن BD',
        'app_charge'                 => 'شحن داخل التطبيق',
        'return_charge'              => 'عكس شحنة',
        'payment'                    => 'دفع',
        'google_pay'                 => 'Google Pay',
        'huawei_pay'                 => 'Huawei Pay',
        'exchange'                   => 'تحويل',
        'gift'                       => 'هدية',
        'lucky_gift'                 => 'هدية الحظ',
        'cashback'                   => 'استرداد نقدي',
        'daily_gift'                 => 'هدية يومية',
        'room_target'                => 'هدف الغرفة',
        'room_level'                 => 'مستوى الغرفة',
        'create_room'                => 'إنشاء غرفة',
        'room_comment'               => 'تعليق الغرفة',
        'coin_game'                  => 'لعبة الكوينز',
        'lucky_box'                  => 'صندوق الحظ',
        'pk'                         => 'معركة PK',
        'super_admin_reward'         => 'مكافأة المشرف العام',
        'region_manager_reward'      => 'مكافأة مدير الإقليم',
        'admin_reward'               => 'مكافأة الإدارة',
        'room_boom'                  => 'انفجار الغرفة',
        'room_cup'                   => 'كأس الغرفة',
        'host_level'                 => 'مستوى المضيف',
        'weekly_star'                => 'نجم الأسبوع',
        'milestone'                  => 'إنجاز',
        'gift_ranking'               => 'ترتيب الهدايا',
        'level_interval'             => 'مكافأة المستوى',
        'charge_event'               => 'فعالية الشحن',
        'cp'                         => 'مكافأة CP',
        'cps'                        => 'مكافأة CPS',
        'invitation_code'            => 'كود الدعوة',
        'invitation_charge_earnings' => 'أرباح شحن الدعوة',
        'compensation'               => 'تعويض',
        'remaining_diamonds'         => 'الألماس المتبقي',
        'vip'                        => 'VIP',
        'pack'                       => 'باقة',
        'family'                     => 'عائلة',
        'background_images'          => 'صورة الخلفية',
        'special_id'                 => 'معرّف خاص',
    ],
];
