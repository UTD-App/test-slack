import 'package:utd_app/shared/stac/stac_data_registry.dart';

import '../domain/entities/moment_entity.dart';
import '../domain/repositories/moment_repository.dart';

/// Static bridge so the package's `const` Stac parsers (which hold no state) can
/// reach the moment repository — and the currently-open moment — at call time.
/// Mirrors the base's `AuthLocator` pattern used by the core action parsers.
class MomentStacBridge {
  MomentStacBridge._();

  static MomentRepository? repository;

  /// The moment opened via `moment.open` — backs the context-free `moment.detail`
  /// object source and `moment.comments` list source on the detail screen.
  static Map<String, dynamic>? currentMoment;
  static int? currentMomentId;
}

/// Wires the moments data into the Stac renderer:
///   • `moment.feed`     (list)   → the global feed, one row per moment
///   • `moment.detail`   (object) → the moment opened via `moment.open`
///   • `moment.comments` (list)   → that moment's comments
///
/// The map keys returned per row MUST match `backend/config/utd_manifest.php`
/// (`elements` / `list_sources.provides` / `object_sources.provides`) so the
/// designer's bindings resolve with no extra mapping. Call once from
/// [MomentFeature.initialize].
void registerMomentStacSources(MomentRepository repository) {
  MomentStacBridge.repository = repository;

  Map<String, dynamic> rowOf(MomentEntity m) => {
        'moment_id': m.id,
        'user_id': m.userId,
        'description': m.description,
        // single image, else first gallery image, else empty.
        'image': m.img.isNotEmpty
            ? m.img
            : (m.images.isNotEmpty ? m.images.first : ''),
        'user_name': m.userName,
        'user_avatar': m.userImage,
        'like_num': m.likeNum,
        'comment_num': m.commentNum,
        'gifts_count': m.giftsCount,
        'is_like': m.isLike,
        'is_owner': m.isOwner,
        'created_at': m.createdAt,
      };

  // Feed list — type 4 = all moments (see MomentRepository.fetchMoments).
  StacDataRegistry.instance.registerList('moment.feed', () async {
    final result = await repository.fetchMoments(type: 4, page: 1);
    final moments = result.dataOrNull ?? const <MomentEntity>[];
    return moments.map(rowOf).toList();
  });

  // Detail — the moment stashed by `moment.open` (context-free registry).
  StacDataRegistry.instance.registerObject('moment.detail', () async {
    return MomentStacBridge.currentMoment ?? const <String, dynamic>{};
  });

  // Comments of the currently-open moment.
  StacDataRegistry.instance.registerList('moment.comments', () async {
    final id = MomentStacBridge.currentMomentId;
    if (id == null) return const <Map<String, dynamic>>[];
    final result = await repository.fetchComments(id);
    final comments = result.dataOrNull ?? const [];
    return comments
        .map<Map<String, dynamic>>((c) => {
              'comment_id': c.id,
              'user_id': c.userId,
              'body': c.comment,
              'author_name': c.userName,
              'author_avatar': c.userImage,
              'created_at': c.createdAt,
            })
        .toList();
  });
}
