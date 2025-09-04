import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String sessionId;
  final String userId;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String type; // 'text', 'image', 'file', 'system'
  final String? emotion; // Detected emotion for AI responses
  final Map<String, dynamic> metadata;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.type,
    this.emotion,
    required this.metadata,
    required this.isRead,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MessageModel(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      userId: data['userId'] ?? '',
      content: data['content'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? 'text',
      emotion: data['emotion'],
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'content': content,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'emotion': emotion,
      'metadata': metadata,
      'isRead': isRead,
    };
  }

  MessageModel copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? type,
    String? emotion,
    Map<String, dynamic>? metadata,
    bool? isRead,
  }) {
    return MessageModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      emotion: emotion ?? this.emotion,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
    );
  }

  // Convert to chat message format for UI
  Map<String, dynamic> toChatFormat() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp,
      'emotion': emotion,
    };
  }

  // Create from chat message format
  factory MessageModel.fromChatFormat(
    Map<String, dynamic> data,
    String sessionId,
    String userId,
  ) {
    return MessageModel(
      id: data['id'] ?? '',
      sessionId: sessionId,
      userId: userId,
      content: data['content'] ?? '',
      isUser: data['isUser'] ?? false,
      timestamp: data['timestamp'] ?? DateTime.now(),
      type: 'text',
      emotion: data['emotion'],
      metadata: {},
      isRead: false,
    );
  }

  // Helper methods
  bool get isFromAI => !isUser;
  bool get isSystemMessage => type == 'system';
  bool get hasEmotion => emotion != null && emotion!.isNotEmpty;
  
  String get displayTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}