import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String userId;
  final String appointmentId;
  final String type; // 'Video Call' or 'Chat Session'
  final DateTime startTime;
  final DateTime? endTime;
  final int durationMinutes;
  final String status; // 'Active', 'Completed', 'Cancelled'
  final List<String> messageIds;
  final double? rating;
  final String? feedback;
  final Map<String, dynamic> metadata;

  SessionModel({
    required this.id,
    required this.userId,
    required this.appointmentId,
    required this.type,
    required this.startTime,
    this.endTime,
    required this.durationMinutes,
    required this.status,
    required this.messageIds,
    this.rating,
    this.feedback,
    required this.metadata,
  });

  factory SessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return SessionModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      appointmentId: data['appointmentId'] ?? '',
      type: data['type'] ?? 'Chat Session',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      durationMinutes: data['durationMinutes'] ?? 0,
      status: data['status'] ?? 'Active',
      messageIds: List<String>.from(data['messageIds'] ?? []),
      rating: data['rating']?.toDouble(),
      feedback: data['feedback'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'appointmentId': appointmentId,
      'type': type,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'durationMinutes': durationMinutes,
      'status': status,
      'messageIds': messageIds,
      'rating': rating,
      'feedback': feedback,
      'metadata': metadata,
    };
  }

  SessionModel copyWith({
    String? id,
    String? userId,
    String? appointmentId,
    String? type,
    DateTime? startTime,
    DateTime? endTime,
    int? durationMinutes,
    String? status,
    List<String>? messageIds,
    double? rating,
    String? feedback,
    Map<String, dynamic>? metadata,
  }) {
    return SessionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      appointmentId: appointmentId ?? this.appointmentId,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      messageIds: messageIds ?? this.messageIds,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isActive => status == 'Active';
  bool get isCompleted => status == 'Completed';
  Duration get duration => Duration(minutes: durationMinutes);
  
  // Calculate actual duration if session is active
  Duration get actualDuration {
    if (endTime != null) {
      return endTime!.difference(startTime);
    } else if (isActive) {
      return DateTime.now().difference(startTime);
    }
    return Duration.zero;
  }
}