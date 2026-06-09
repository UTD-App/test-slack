import 'package:utd_app/shared/stac/stac_data_registry.dart';

import '../domain/entities/moment_entity.dart';
import '../domain/repositories/moment_repository.dart';

/// Static bridge so the package's `const` Stac action parsers (which hold no
/// state) can reach the moment repository at call time — mirrors the base's
/// `AuthLocator` pattern used by the core action parsers.
class MomentStacBridge {
  MomentStacBridge._();

  static MomentRepository? repository;
}

/// Wires the moments feed into the Stac renderer as the `moment.feed` list
/// source — what a UTD-Studio `utdList` binds to.
///
/// The map keys returned per row MUST match `backend/config/utd_manifest.php`
/// (`elements` / `list_sources.provides`) so bindings resolve with no extra
/// mapping. Call once from [MomentFeature.initialize].
void registerMomentStacSources(MomentRepository repository) {
  MomentStacBridge.repository = repository;

  StacDataRegistry.instance.registerList('moment.feed', () async {
    // type 4 = all moments (see MomentRepository.fetchMoments).
    final result = await repository.fetchMoments(type: 4, page: 1);
    final moments = result.dataOrNull ?? const <MomentEntity>[];

    return moments
        .map<Map<String, dynamic>>((m) => {
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
              'created_at': m.createdAt,
            })
        .toList();
  });
}
