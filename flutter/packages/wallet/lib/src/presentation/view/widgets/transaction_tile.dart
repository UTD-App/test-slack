import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../../core/wallet_strings.dart';
import '../../../domain/entities/wallet_transaction.dart';

/// One row in the transactions list. Green for credits, red for debits.
class TransactionTile extends StatelessWidget {
  final WalletTransaction tx;

  const TransactionTile({super.key, required this.tx});

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('yyyy-MM-dd  HH:mm').format(dt.toLocal());
  }

  String _humanize(String value) => value.replaceAll('_', ' ').trim();

  /// Localized label for the transaction's type (`wallet.tx_type.<type>`),
  /// falling back to the humanized type/reason when no key is registered so
  /// unknown/new backend types still render.
  String _label(BuildContext context) {
    final type = tx.type.trim();
    if (type.isNotEmpty) {
      final key = WalletStrings.txType(type);
      final translated = context.tr(key);
      // `context.tr` returns the raw key when it is missing — treat that as
      // "no label" and fall back to the humanized reason/type below.
      if (translated != key && translated.trim().isNotEmpty) return translated;
    }
    final fallback = tx.reason.trim().isNotEmpty ? tx.reason : type;
    return _humanize(fallback);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isCredit = tx.isCredit;
    final color = isCredit ? Colors.green.shade600 : Colors.red.shade600;
    final sign = isCredit ? '+' : '-';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(
          isCredit ? Icons.south_west : Icons.north_east,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        _label(context),
        style: const TextStyle(fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        _formatDate(tx.createdAt),
        style: TextStyle(fontSize: 12, color: colors.outline),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '$sign${tx.absAmount.toStringAsFixed(2)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          Text(
            tx.balanceAfter.toStringAsFixed(2),
            style: TextStyle(fontSize: 11, color: colors.outline),
          ),
        ],
      ),
    );
  }
}
