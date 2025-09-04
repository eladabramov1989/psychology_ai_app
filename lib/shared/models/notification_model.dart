import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  appointmentReminder,
  appointmentConfirmation,
  appointmentCancellation,
  sessionStarting,
  sessionEnded,
  messageReceived,
  systemUpdate,
  general,
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final Map<String, dynamic>? data; // Additional data like appointment ID, etc.
  final String? actionUrl; // Deep link or navigation path

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    required this.createdAt,
    this.readAt,
    this.data,
    this.actionUrl,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => NotificationType.general,
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == data['priority'],
        orElse: () => NotificationPriority.normal,
      ),
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      readAt: data['readAt'] != null ? (data['readAt'] as Timestamp).toDate() : null,
      data: data['data'] as Map<String, dynamic>?,
      actionUrl: data['actionUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type.toString(),
      'priority': priority.toString(),
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'data': data,
      'actionUrl': actionUrl,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }
}

extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.appointmentReminder:
        return 'Appointment Reminder';
      case NotificationType.appointmentConfirmation:
        return 'Appointment Confirmed';
      case NotificationType.appointmentCancellation:
        return 'Appointment Cancelled';
      case NotificationType.sessionStarting:
        return 'Session Starting';
      case NotificationType.sessionEnded:
        return 'Session Ended';
      case NotificationType.messageReceived:
        return 'New Message';
      case NotificationType.systemUpdate:
        return 'System Update';
      case NotificationType.general:
        return 'Notification';
    }
  }

  String get iconPath {
    switch (this) {
      case NotificationType.appointmentReminder:
      case NotificationType.appointmentConfirmation:
      case NotificationType.appointmentCancellation:
        return 'calendar_today';
      case NotificationType.sessionStarting:
      case NotificationType.sessionEnded:
        return 'video_call';
      case NotificationType.messageReceived:
        return 'chat';
      case NotificationType.systemUpdate:
        return 'system_update';
      case NotificationType.general:
        return 'notifications';
    }
  }
}