import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/profile/profile_view_arguments.dart';

import '../../../core/wallet_routes.dart';
import '../../../core/wallet_strings.dart';
import '../bloc/wallet_cubit.dart';

/// Coin-balance card on the user's OWN profile. Shows the current coin balance
/// and opens the wallet page on tap. Hidden on other users' profiles — a
/// balance is private — so it only renders when `ProfileViewArguments.isMe`.
class WalletProfileSection extends StatefulWidget {
  const WalletProfileSection({super.key});

  @override
  State<WalletProfileSection> createState() => _WalletProfileSectionState();
}

class _WalletProfileSectionState extends State<WalletProfileSection> {
  @override
  void initState() {
    super.initState();
    // Load the coin balance once (own profile only — see build()).
    final cubit = context.read<WalletCubit>();
    if (cubit.state.balancesStatus == WalletStatus.initial) {
      cubit.loadBalances();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only on the current user's own profile (balance is private).
    ProfileViewArguments? args;
    try {
      args = context.read<ProfileViewArguments>();
    } catch (_) {
      args = null;
    }
    if (args != null && !args.isMe) return const SizedBox.shrink();

    return BlocBuilder<WalletCubit, WalletState>(
      buildWhen: (a, b) =>
          a.balances != b.balances || a.balancesStatus != b.balancesStatus,
      builder: (context, state) {
        final coins = state.balanceFor('coins').balance;
        final loading =
            state.balancesStatus == WalletStatus.loading && state.balances.isEmpty;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(WalletRoutes.wallet),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF6A623), Color(0xFFF77F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.toll, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr(WalletStrings.coins),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          loading ? '—' : coins.toStringAsFixed(0),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
