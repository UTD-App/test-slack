<?php

namespace Utd\Wallet\Enums;

/**
 * Canonical coin-movement types, ported from Eagle's UserCoinLogType.
 * Used as `wallet_transactions.type`. `sub_type` / `item_name` add detail.
 *
 * These cover every coin credit/debit flow found in Eagle: manual charges,
 * payment-gateway recharge, gifts, games, rewards, exchange, special items.
 */
final class CoinTransactionType
{
    // --- Charging (credit) ---
    public const ADMIN_CHARGES        = 'admin_charge';        // dashboard admin
    public const AREA_MANAGER_CHARGES = 'area_manager_charge';
    public const BD_CHARGES           = 'bd_charge';
    public const APP_CHARGE           = 'app_charge';
    public const RETURN_CHARGE        = 'return_charge';       // reverse a charge (debit)

    // --- Payment gateways (credit) ---
    public const PAYMENT    = 'payment';
    public const GOOGLE_PAY = 'google_pay';
    public const HUAWEI_PAY = 'huawei_pay';

    // --- Conversion (credit; dollar/diamond -> coins) ---
    public const EXCHANGE = 'exchange';

    // --- Gifts & rooms (debit/credit) ---
    public const GIFT         = 'gift';
    public const LUCKY_GIFT   = 'lucky_gift';
    public const CASHBACK     = 'cashback';
    public const DAILY_GIFT   = 'daily_gift';
    public const ROOM_TARGET  = 'room_target';
    public const ROOM_LEVEL   = 'room_level';
    public const CREATE_ROOM  = 'create_room';
    public const ROOM_COMMENT = 'room_comment';

    // --- Games (credit/debit) ---
    public const COIN_GAME = 'coin_game';
    public const LUCK_BOX  = 'lucky_box';
    public const PK        = 'pk';

    // --- Rewards (credit) ---
    public const SUPER_ADMIN_REWARD    = 'super_admin_reward';
    public const REGION_MANAGER_REWARD = 'region_manager_reward';
    public const ADMIN_REWARD          = 'admin_reward';
    public const ROOM_BOOM             = 'room_boom';
    public const ROOM_CUP              = 'room_cup';
    public const HOST_LEVEL            = 'host_level';
    public const WEEKLY_STAR           = 'weekly_star';
    public const MILESTONE             = 'milestone';
    public const GIFT_RANKING          = 'gift_ranking';
    public const LEVEL_INTERVAL        = 'level_interval';
    public const CHARGE_EVENT          = 'charge_event';
    public const CP                    = 'cp';
    public const CPS                   = 'cps';
    public const INVITATION_CODE       = 'invitation_code';
    public const INVITATION_CHARGE_EARNINGS = 'invitation_charge_earnings';
    public const COMPENSATION          = 'compensation';
    public const REMAINING_DIAMONDS    = 'remaining_diamonds';

    // --- Special items (debit) ---
    public const VIP               = 'vip';
    public const PACK              = 'pack';
    public const FAMILY            = 'family';
    public const BACKGROUND_IMAGES = 'background_images';
    public const SPECIAL_ID        = 'special_id';
}
