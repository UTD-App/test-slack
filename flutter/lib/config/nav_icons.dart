import 'package:flutter/material.dart';

/// Stable string→[IconData] map for server-driven bottom-nav tabs.
///
/// The `app_layout` document references icons by NAME (not codepoint), so the
/// set of usable icons is closed and known at compile time — this avoids the
/// const-tree-shaking breakage you get from building `IconData` from dynamic
/// codepoints. UTD Studio's icon picker exposes exactly these same keys.
const Map<String, IconData> _navIcons = {
  'home': Icons.home_rounded,
  'chat': Icons.chat_bubble_rounded,
  'message': Icons.message_rounded,
  'settings': Icons.settings_rounded,
  'person': Icons.person_rounded,
  'profile': Icons.account_circle_rounded,
  'search': Icons.search_rounded,
  'explore': Icons.explore_rounded,
  'notifications': Icons.notifications_rounded,
  'favorite': Icons.favorite_rounded,
  'add': Icons.add_circle_rounded,
  'video': Icons.videocam_rounded,
  'live': Icons.live_tv_rounded,
  'list': Icons.list_rounded,
  'grid': Icons.grid_view_rounded,
  'store': Icons.storefront_rounded,
  'cart': Icons.shopping_cart_rounded,
  'wallet': Icons.account_balance_wallet_rounded,
  'menu': Icons.menu_rounded,
  'star': Icons.star_rounded,
  'mic': Icons.mic_rounded,
};

/// Resolves a tab icon by its [name], falling back to a neutral icon for any
/// name the runtime doesn't know.
IconData navIconFor(String? name) =>
    _navIcons[name] ?? Icons.circle_outlined;
