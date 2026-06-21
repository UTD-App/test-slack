/// A single in-app notification, as returned by GET /api/notifications.
/// title/body are already rendered server-side in the request locale.
class NotificationItem {
  final int id;
  final String type;
  final String? category;
  final String title;
  final String body;
  final String? icon;
  final String? route;
  final Map<String, dynamic> data;
  final String? imageUrl;
  final NotificationActor? actor;
  final bool isRead;
  final DateTime? createdAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.category,
    this.icon,
    this.route,
    this.data = const {},
    this.imageUrl,
    this.actor,
    this.createdAt,
  });

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        type: type,
        category: category,
        title: title,
        body: body,
        icon: icon,
        route: route,
        data: data,
        imageUrl: imageUrl,
        actor: actor,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String? ?? '',
      category: json['category'] as String?,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      icon: json['icon'] as String?,
      route: json['route'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      imageUrl: json['image_url'] as String?,
      actor: json['actor'] is Map
          ? NotificationActor.fromJson((json['actor'] as Map).cast<String, dynamic>())
          : null,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class NotificationActor {
  final int id;
  final String? name;
  final String? avatar;

  const NotificationActor({required this.id, this.name, this.avatar});

  factory NotificationActor.fromJson(Map<String, dynamic> json) => NotificationActor(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String?,
        avatar: json['avatar'] as String?,
      );
}
