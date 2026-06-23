import 'package:stac/stac.dart';

import 'stac_list_parser.dart';
import 'stac_loading_parser.dart';
import 'stac_object_parser.dart';
import 'stac_scroll_parser.dart';
import 'utd_positioned_directional_parser.dart';
import 'utd_sized_parser.dart';
import 'utd_tabs_parser.dart';
import 'utd_text_field_parser.dart';

/// The UTD widget parsers bundled with UTD Studio. `UtdStudio.init` registers
/// these (plus any `StudioConfig.extraParsers`) with `Stac.initialize`.
///
/// These handle the custom `utd*` widget types emitted by the UTD Studio editor:
/// `utdList`, `utdObject`, `utdScroll`, `utdSized`, `utdLoading`, `utdTabs`,
/// `utdTextField`, `utdPositionedDirectional`.
const List<StacParser> builtinStacParsers = [
  StacUtdListParser(),
  StacUtdObjectParser(),
  StacUtdScrollParser(),
  StacUtdSizedParser(),
  StacUtdLoadingParser(),
  StacUtdTabsParser(),
  StacUtdTextFieldParser(),
  StacUtdPositionedDirectionalParser(),
];
