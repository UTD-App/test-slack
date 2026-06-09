import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:utd_app/localization/localization.dart';

import '../../../core/moment_strings.dart';
import '../../domain/repositories/moment_repository.dart';
import '../bloc/moment_feed/moment_feed_bloc.dart';
import 'moment_feed_view.dart';

/// Moments page. With no [userId] it shows the global feed using the ambient
/// [MomentFeedBloc]. With a [userId] it shows that single user's posts using a
/// scoped bloc (and hides the "add" button).
///
/// The list body itself lives in [MomentFeedView] so it can be reused as-is by
/// the server-driven `moment.feed` Stac widget.
class MomentFeedPage extends StatelessWidget {
  final int? userId;
  final String? titleKey;

  const MomentFeedPage({super.key, this.userId, this.titleKey});

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return _scaffold(context, showAdd: true);
    }
    return BlocProvider<MomentFeedBloc>(
      create: (ctx) =>
          MomentFeedBloc(ctx.read<MomentRepository>(), userId: userId),
      child: _scaffold(context, showAdd: false),
    );
  }

  Widget _scaffold(BuildContext context, {required bool showAdd}) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr(titleKey ?? MomentStrings.title))),
      floatingActionButton: showAdd
          ? FloatingActionButton(
              onPressed: () => context.push('/moment/add'),
              child: const Icon(Icons.add),
            )
          : null,
      body: const MomentFeedView(),
    );
  }
}
