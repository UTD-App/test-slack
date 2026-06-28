import 'package:utd_app/network/services/base_api_service.dart';

class AudioRoomApiService extends BaseApiService {
  // Room CRUD
  String roomsPath() => '/rooms';
  String roomPath(int id) => '/rooms/$id';

  // Room actions
  String enterPath(int id) => '/rooms/$id/enter';
  String exitPath(int id) => '/rooms/$id/exit';
  String favoritePath(int id) => '/rooms/$id/favorite';
  String commentStatusPath(int id) => '/rooms/$id/comment-status';
  String modePath(int id) => '/rooms/$id/mode';
  String removePasswordPath(int id) => '/rooms/$id/remove-password';
  String usersPath(int id) => '/rooms/$id/users';

  // Room queries
  String myRoomPath() => '/rooms/mine';
  String favoritesPath() => '/rooms/favorites';
  String categoriesPath() => '/rooms/categories';
  String roomConfigPath() => '/config/room';

  // Admin management
  String adminsPath(int roomId) => '/rooms/$roomId/admins';
  String adminPath(int roomId, int userId) => '/rooms/$roomId/admins/$userId';

  // Blacklist management
  String blacklistPath(int roomId) => '/rooms/$roomId/blacklist';
  String kickPath(int roomId) => '/rooms/$roomId/kick';
  String banPath(int roomId) => '/rooms/$roomId/ban';
  String unbanPath(int roomId, int userId) => '/rooms/$roomId/blacklist/$userId';

  // Moderation
  String muteWritingPath(int id) => '/rooms/$id/mute-writing';
  String unmuteWritingPath(int id) => '/rooms/$id/unmute-writing';
  String yellowBannerPath(int id) => '/rooms/$id/yellow-banner';

  // Pinned message
  String pinMessagePath(int id) => '/rooms/$id/pin-message';
  String unpinMessagePath(int id) => '/rooms/$id/unpin-message';

  // Role check
  String checkRolePath(int id) => '/rooms/$id/check-role';
}
