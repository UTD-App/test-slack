import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

import '../../../core/wallet_strings.dart';
import '../bloc/wallet_cubit.dart';
import 'widgets/balance_card.dart';
import 'widgets/transaction_tile.dart';

/// The coin wallet: balance, recharge catalogue, and transaction history.
/// (Dollars/earnings live in the target package; diamonds in the agency package.)
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Always refresh on open. The profile balance card pre-loads balances
    // (flipping balancesStatus out of `initial`), so gating on it would skip
    // loading the transactions + recharge catalogue until a manual refresh.
    context.read<WalletCubit>().loadAll();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  /// Trigger the next page when the user nears the bottom. The cubit no-ops if
  /// there is nothing more to load or a request is already in flight.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      context.read<WalletCubit>().loadMoreTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletCubit>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
        title: Text(
          context.tr(WalletStrings.title),
          style: const TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: cubit.loadAll,
            child: BlocBuilder<WalletCubit, WalletState>(
              builder: (context, state) {
                final coins = state.balanceFor('coins');

                return ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Coin balance (the dollar wallet lives in the target package).
                BalanceCard(
                  label: context.tr(WalletStrings.coins),
                  amount: coins.balance.toStringAsFixed(0),
                  icon: Icons.toll,
                  gradient: const [Color(0xFFF6A623), Color(0xFFF77F00)],
                ),
                const SizedBox(height: 20),
                const _TransactionsSection(),
              ],
            );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Coin transaction history with a date-range filter.
class _TransactionsSection extends StatelessWidget {
  const _TransactionsSection();

  Future<void> _pickDateRange(BuildContext context) async {
    final cubit = context.read<WalletCubit>();
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
    );
    if (range == null) return;
    final fmt = DateFormat('yyyy-MM-dd');
    await cubit.setDateRange(fmt.format(range.start), fmt.format(range.end));
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WalletCubit>();

    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(WalletStrings.transactions),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_alt_outlined),
                  tooltip: context.tr(WalletStrings.filter),
                  onPressed: () => _pickDateRange(context),
                ),
                if (state.hasDateFilter)
                  TextButton(
                    onPressed: cubit.clearDateFilter,
                    child: Text(context.tr(WalletStrings.clearFilter)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _TransactionsList(state: state),
          ],
        );
      },
    );
  }
}

class _TransactionsList extends StatelessWidget {
  final WalletState state;
  const _TransactionsList({required this.state});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (state.txStatus == WalletStatus.loading && state.transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.txStatus == WalletStatus.failure && state.transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Text(
                state.error ?? context.tr(WalletStrings.somethingWrong),
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.outline),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => context.read<WalletCubit>().loadTransactions(),
                child: Text(context.tr(WalletStrings.retry)),
              ),
            ],
          ),
        ),
      );
    }

    if (state.transactions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            context.tr(WalletStrings.noTransactions),
            style: TextStyle(color: colors.outline),
          ),
        ),
      );
    }

    // Append a trailing spinner row while the next page is loading.
    final count = state.transactions.length + (state.txLoadingMore ? 1 : 0);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (i >= state.transactions.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return TransactionTile(tx: state.transactions[i]);
      },
    );
  }
}
