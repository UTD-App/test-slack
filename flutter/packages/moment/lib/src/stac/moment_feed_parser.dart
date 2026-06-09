import 'package:flutter/material.dart';
import 'package:stac/stac.dart' hide StacService;

import '../presentation/view/moment_feed_view.dart';

/// Stac **widget** parser for the moments feed.
///
/// A UTD-Studio screen can drop a `moment.feed` widget (declared in the backend
/// manifest `widgets`) and it renders the real, fully-interactive feed — like,
/// comments, likes, report, delete, image preview, gifts, pull-to-refresh and
/// infinite scroll all work natively, because [MomentFeedView] is the same body
/// used by the bottom-nav [MomentFeedPage].
///
/// The widget needs no props: it reads the ambient [MomentFeedBloc] provided by
/// [MomentFeature.getProviders]. Registered via [MomentFeature.getStacParsers].
class MomentFeedStacParser extends StacParser<Map<String, dynamic>> {
  const MomentFeedStacParser();

  @override
  String get type => 'moment.feed';

  @override
  Map<String, dynamic> getModel(Map<String, dynamic> json) => json;

  @override
  Widget parse(BuildContext context, Map<String, dynamic> model) =>
      const MomentFeedView();
}

/// The package's Stac widget parsers, registered via [MomentFeature.getStacParsers].
List<StacParser> momentStacParsers() => const [
      MomentFeedStacParser(),
    ];
