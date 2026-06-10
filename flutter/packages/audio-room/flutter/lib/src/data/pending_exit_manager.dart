import 'package:shared_preferences/shared_preferences.dart';

class PendingExitManager {
  static const _key = 'audio_room_pending_exits';

  static Future<void> add(int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    final idStr = roomId.toString();
    if (!ids.contains(idStr)) {
      ids.add(idStr);
      await prefs.setStringList(_key, ids);
    }
  }

  static Future<List<int>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    return ids.map(int.parse).toList();
  }

  static Future<void> remove(int roomId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? [];
    ids.remove(roomId.toString());
    await prefs.setStringList(_key, ids);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
