class NotificationModel {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  final String userId;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.data,
    required this.userId,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      createdAt: DateTime.parse(json['created_at']),
      data: json['data'],
      userId: json['user_id'],
      isRead: json['is_read'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'created_at': createdAt.toIso8601String(),
      'data': data,
      'user_id': userId,
      'is_read': isRead,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    DateTime? createdAt,
    Map<String, dynamic>? data,
    String? userId,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      data: data ?? this.data,
      userId: userId ?? this.userId,
      isRead: isRead ?? this.isRead,
    );
  }
}