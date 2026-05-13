class UserNotificationItem {
  const UserNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.type,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final String createdAt;
  final String type;
  final bool isRead;

  UserNotificationItem copyWith({
    String? id,
    String? title,
    String? body,
    String? createdAt,
    String? type,
    bool? isRead,
  }) {
    return UserNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}
