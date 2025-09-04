import 'package:cloud_firestore/cloud_firestore.dart';

enum AppointmentType {
  videoCall,
  chatSession,
}

enum AppointmentStatus {
  scheduled,
  confirmed,
  inProgress,
  completed,
  cancelled,
  rescheduled,
}

class AppointmentModel {
  final String id;
  final String userId;
  final String title;
  final DateTime scheduledDateTime;
  final AppointmentType type;
  final AppointmentStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? notes;
  final int? durationMinutes;
  final String? summary;

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.scheduledDateTime,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.notes,
    this.durationMinutes,
    this.summary,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return AppointmentModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      scheduledDateTime: (data['scheduledDateTime'] as Timestamp).toDate(),
      type: _parseAppointmentType(data['type']),
      status: _parseAppointmentStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      notes: data['notes'],
      durationMinutes: data['durationMinutes'],
      summary: data['summary'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'notes': notes,
      'durationMinutes': durationMinutes,
      'summary': summary,
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? scheduledDateTime,
    AppointmentType? type,
    AppointmentStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    int? durationMinutes,
    String? summary,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      summary: summary ?? this.summary,
    );
  }

  static AppointmentType _parseAppointmentType(dynamic value) {
    if (value == null) return AppointmentType.chatSession;
    
    switch (value.toString().toLowerCase()) {
      case 'videocall':
      case 'video_call':
      case 'video call':
        return AppointmentType.videoCall;
      case 'chatsession':
      case 'chat_session':
      case 'chat session':
        return AppointmentType.chatSession;
      default:
        return AppointmentType.chatSession;
    }
  }

  static AppointmentStatus _parseAppointmentStatus(dynamic value) {
    if (value == null) return AppointmentStatus.scheduled;
    
    switch (value.toString().toLowerCase()) {
      case 'scheduled':
        return AppointmentStatus.scheduled;
      case 'confirmed':
        return AppointmentStatus.confirmed;
      case 'inprogress':
      case 'in_progress':
      case 'in progress':
        return AppointmentStatus.inProgress;
      case 'completed':
        return AppointmentStatus.completed;
      case 'cancelled':
        return AppointmentStatus.cancelled;
      case 'rescheduled':
        return AppointmentStatus.rescheduled;
      default:
        return AppointmentStatus.scheduled;
    }
  }
}