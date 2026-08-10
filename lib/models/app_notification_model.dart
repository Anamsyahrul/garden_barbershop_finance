class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final bool isRead;
  final String type;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    this.isRead = false,
    this.type = 'general',
  });

  factory AppNotification.fromMap(Map<String, dynamic> map, String id) {
    return AppNotification(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      isRead: map['isRead'] ?? false,
      type: map['type'] ?? 'general',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'date': date.toIso8601String(),
      'isRead': isRead,
      'type': type,
    };
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? date,
    bool? isRead,
    String? type,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }
}
