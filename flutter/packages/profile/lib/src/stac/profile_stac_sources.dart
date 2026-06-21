import 'package:utd_app/cache/cache_manager.dart';
import 'package:utd_app/shared/stac/stac_data_registry.dart';

import '../data/profile_api_service.dart';
import '../data/profile_remote_datasource.dart';
import '../domain/profile_repository.dart';

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
      'bio': p.bio ?? '',
      'avatar': p.avatar ?? '',
      'cover': p.covers.isNotEmpty ? p.covers.first : '',
      'country': p.countryName ?? '',
      'uid': p.uuid ?? '',
    };
  });
}
