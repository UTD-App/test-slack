import 'package:utd_app/cache/cache_manager.dart';

import '../../audio_room_feature.dart';
import '../../domain/room_model.dart';

mixin AudioRoomPluginMixin {
  RoomModel? get currentRoom;

  void notifyPluginsEnter(RoomModel room) {
    final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
    for (final plugin in AudioRoomFeature.registeredPlugins) {
      plugin.onRoomEnter(room.id, userId);
    }
  }

  void notifyPluginsExit() {
    if (currentRoom == null) return;
    final userId = CacheManager.getUserData()?['id']?.toString() ?? '';
    for (final plugin in AudioRoomFeature.registeredPlugins) {
      plugin.onRoomExit(currentRoom!.id, userId);
    }
  }
}
