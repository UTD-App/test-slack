import 'package:flutter/foundation.dart';

/// Registry that connects Stac data-bound widgets (e.g. `utdList`) to real
/// runtime data sources.
///
/// Each package registers its sources by key — for example the Chat package
/// registers `chat.conversations` and `chat.conversation`. The base Stac
/// renderer stays data-agnostic: it only knows "give me the list for this
/// source key", and the package decides where the data comes from (its BLoC,
/// repository, API, ...).
///
/// This is what keeps a package's UI editable in UTD Studio while its data
/// logic remains fully inside the package.
typedef StacListSource = Future<List<Map<String, dynamic>>> Function();

/// A single-object source (e.g. the current user for the `core.profile` screen).
typedef StacObjectSource = Future<Map<String, dynamic>> Function();

class StacDataRegistry {
  StacDataRegistry._();
  static final StacDataRegistry instance = StacDataRegistry._();

  final Map<String, StacListSource> _listSources = {};
  final Map<String, StacObjectSource> _objectSources = {};

  /// Bumped whenever a source's underlying data changes (e.g. the signed-in
  /// user updated their avatar). Data-bound widgets (`utdObject`) listen to this
  /// and re-fetch so the UI reflects fresh data without a full screen reload.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Signal that cached source data changed — triggers bound widgets to refetch.
  void invalidate() => revision.value++;

  /// Register a list data source for a binding `source` key
  /// (e.g. `chat.conversations`).
  void registerList(String key, StacListSource source) {
    _listSources[key] = source;
  }

  bool hasList(String key) => _listSources.containsKey(key);

  /// Fetch the list for [key]. Returns an empty list if the source is missing
  /// or throws — the UI degrades gracefully instead of crashing.
  Future<List<Map<String, dynamic>>> fetchList(String key) async {
    final source = _listSources[key];
    if (source == null) return const [];
    try {
      return await source();
    } catch (_) {
      return const [];
    }
  }

  /// Register a single-object data source for a `source` key
  /// (e.g. `core.currentUser` for the profile screen).
  void registerObject(String key, StacObjectSource source) {
    _objectSources[key] = source;
  }

  bool hasObject(String key) => _objectSources.containsKey(key);

  /// Fetch the object for [key]. Returns an empty map if the source is missing
  /// or throws — bindings then fall back to their literal defaults.
  Future<Map<String, dynamic>> fetchObject(String key) async {
    final source = _objectSources[key];
    if (source == null) return const {};
    try {
      return await source();
    } catch (_) {
      return const {};
    }
  }
}
