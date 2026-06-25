import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:utd_app/localization/localization.dart';
import 'package:utd_app/network/models/api_response.dart';
import 'package:utd_app/shared/core/color_manager.dart';
import 'package:utd_app/shared/widgets/gradient_background.dart';

import '../../../core/gifts_strings.dart';
import '../../domain/entities/gift_history_item.dart';
import '../../domain/repositories/gift_repository.dart';

class GiftHistoryPage extends StatefulWidget {
  const GiftHistoryPage({super.key});

  @override
  State<GiftHistoryPage> createState() => _GiftHistoryPageState();
}

class _GiftHistoryPageState extends State<GiftHistoryPage> with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<GiftRepository>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorManager.lumiaTextPrimary),
        title: Text(
          context.tr(GiftsStrings.history),
          style: const TextStyle(
            color: ColorManager.lumiaTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tab,
          labelColor: ColorManager.lumiaTextPrimary,
          unselectedLabelColor: ColorManager.lumiaTextSecondary,
          indicatorColor: ColorManager.lumiaAccent,
          tabs: [
            Tab(text: context.tr(GiftsStrings.received)),
            Tab(text: context.tr(GiftsStrings.sentTab)),
          ],
        ),
      ),
      body: GradientBackground(
        child: SafeArea(
          child: TabBarView(
            controller: _tab,
            children: [
              _HistoryList(repository: repo, type: 'received'),
              _HistoryList(repository: repo, type: 'sent'),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final GiftRepository repository;
  final String type;

  const _HistoryList({required this.repository, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FutureBuilder<Result<List<GiftHistoryItem>>>(
      future: repository.fetchHistory(type: type),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data?.dataOrNull ?? const <GiftHistoryItem>[];
        if (items.isEmpty) {
          return Center(child: Text(context.tr(GiftsStrings.noHistory), style: TextStyle(color: colors.outline)));
        }

        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = items[i];
            final isReceived = type == 'received';
            final value = isReceived ? item.earned : item.totalPrice;
            final color = isReceived ? Colors.green.shade600 : Colors.red.shade600;
            final sign = isReceived ? '+' : '-';

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(isReceived ? Icons.south_west : Icons.north_east, color: color, size: 20),
              ),
              title: Text(item.giftName.isEmpty ? '#${item.id}' : item.giftName),
              subtitle: Text(_formatDate(item.createdAt), style: TextStyle(fontSize: 12, color: colors.outline)),
              trailing: Text(
                '$sign${value.toStringAsFixed(0)}  ×${item.giftNum}',
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('yyyy-MM-dd  HH:mm').format(dt.toLocal());
  }
}
