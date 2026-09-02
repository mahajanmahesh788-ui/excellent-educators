class UserNotificationDto {
  const UserNotificationDto({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.readAt,
    this.createdAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String? createdAt;

  bool get isUnread => readAt == null || readAt!.isEmpty;

  factory UserNotificationDto.fromJson(Map<String, dynamic> json) {
    return UserNotificationDto(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      data: json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : null,
      readAt: json['read_at'] as String?,
      createdAt: json['created_at'] as String?,
    );
  }
}
