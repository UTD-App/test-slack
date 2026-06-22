import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/shared/stac/stac_data_registry.dart';

import '../data/profile_api_service.dart';
import '../data/profile_remote_datasource.dart';
import '../domain/profile_repository.dart';
import '../presentation/utils/media.dart';

/// Wires the profile package's data into the Stac renderer for the UTD Studio
/// `profile` package.
///
/// Exposes the signed-in user's profile as the single-object source
/// `profile.user`, consumed by a `Scope` (utdObject) on the `user_profile`
/// default screen. The returned map keys MUST match the profile manifest
/// (backend/config/utd_manifest.php → name/bio/avatar/cover/country/uid) so the
/// designer's bindings resolve with no extra mapping.
///
/// Current user id is read lazily from the cached user data inside the closure
/// (there is no widget context at feature initialize time). Called once from
/// [ProfileFeature.initialize].
void registerProfileStacSources() {
  final repository = ProfileRepositoryImpl(
    remoteDataSource: ProfileRemoteDataSourceImpl(
      apiService: ProfileApiService(),
    ),
  );

  StacDataRegistry.instance.registerObject('profile.user', () async {
    final id = (CacheManager.getUserData()?['id'] as num?)?.toInt() ?? 0;
    if (id == 0) return const <String, dynamic>{};

    final result = await repository.getUserProfile(id);
    final p = result.dataOrNull?.data;
    if (p == null) return const <String, dynamic>{};

    return {
      'name': p.name ?? '',
      // Placeholder when empty so the profile's bio + edit-pencil row stays
      // meaningful (tap → edit). A real bio overrides it.
      'bio': (p.bio?.trim().isNotEmpty ?? false) ? p.bio : 'أضف نبذة',
      // Resolve media to ABSOLUTE URLs — the Stac renderer loads the value
      // verbatim, so a raw path (`avatars/x.jpg`, `flags/ye.png`) 404s. This is
      // why the avatar/country flag showed broken. avatarUrl adds a generated
      // fallback so the avatar is never blank.
      'avatar': avatarUrl(p.avatar, p.name),
      'cover': p.covers.isNotEmpty ? resolveMediaUrl(p.covers.first) : '',
      'country': p.countryName ?? '',
      'flag': resolveMediaUrl(p.countryFlag),
      'uid': p.uuid ?? '',
      // Gender → two visibleBinding-gated icons in the manifest (1=male,2=female).
      'isMale': p.gender == 1 ? '1' : '',
      'isFemale': p.gender == 2 ? '1' : '',
      // Gender sign: symbol for the matching gender, '' otherwise. Bound to a
      // colored Text in the manifest (UTD Studio drops visibleBinding, so an empty
      // bound string is how the non-matching one is hidden).
      'maleSign': p.gender == 1 ? '♂' : '',
      'femaleSign': p.gender == 2 ? '♀' : '',
    };
  });
}
