import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/message_model.dart';
import '../../core/constants/app_constants.dart';

class MessageService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  MessageService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Send a message
  Future<String> sendMessage(MessageModel message) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final messageData = message.copyWith(
        userId: _currentUserId!,
        timestamp: DateTime.now(),
      );

      final docRef = await _firestore
          .collection(AppConstants.messagesCollection)
          .add(messageData.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages for a session
  Stream<List<MessageModel>> getSessionMessages(String sessionId) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('sessionId', isEqualTo: sessionId)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get recent messages for user
  Stream<List<MessageModel>> getRecentMessages({int limit = 50}) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // Mark message as read
  Future<void> markMessageAsRead(String messageId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  // Mark all messages in session as read
  Future<void> markSessionMessagesAsRead(String sessionId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('sessionId', isEqualTo: sessionId)
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark session messages as read: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Get message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection(AppConstants.messagesCollection)
          .doc(messageId)
          .get();

      if (doc.exists) {
        final message = MessageModel.fromFirestore(doc);
        // Ensure the message belongs to the current user
        if (message.userId == _currentUserId) {
          return message;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get message: $e');
    }
  }

  // Search messages
  Future<List<MessageModel>> searchMessages(String query, {String? sessionId}) async {
    if (_currentUserId == null) {
      return [];
    }

    try {
      Query messagesQuery = _firestore
          .collection(AppConstants.messagesCollection)
          .where('userId', isEqualTo: _currentUserId);

      if (sessionId != null) {
        messagesQuery = messagesQuery.where('sessionId', isEqualTo: sessionId);
      }

      final snapshot = await messagesQuery
          .orderBy('timestamp', descending: true)
          .get();

      final messages = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .where((message) => message.content.toLowerCase().contains(query.toLowerCase()))
          .toList();

      return messages;
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount({String? sessionId}) async {
    if (_currentUserId == null) {
      return 0;
    }

    try {
      Query messagesQuery = _firestore
          .collection(AppConstants.messagesCollection)
          .where('userId', isEqualTo: _currentUserId)
          .where('isRead', isEqualTo: false)
          .where('isUser', isEqualTo: false); // Only count AI messages

      if (sessionId != null) {
        messagesQuery = messagesQuery.where('sessionId', isEqualTo: sessionId);
      }

      final snapshot = await messagesQuery.get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  // Get messages with emotion
  Stream<List<MessageModel>> getMessagesWithEmotion(String emotion) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('userId', isEqualTo: _currentUserId)
        .where('emotion', isEqualTo: emotion)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get message statistics
  Future<Map<String, dynamic>> getMessageStats() async {
    if (_currentUserId == null) {
      return {
        'totalMessages': 0,
        'userMessages': 0,
        'aiMessages': 0,
        'emotionBreakdown': <String, int>{},
      };
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.messagesCollection)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final messages = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc))
          .toList();

      final userMessages = messages.where((m) => m.isUser).length;
      final aiMessages = messages.where((m) => !m.isUser).length;

      // Count emotions
      final emotionBreakdown = <String, int>{};
      for (final message in messages) {
        if (message.emotion != null && message.emotion!.isNotEmpty) {
          emotionBreakdown[message.emotion!] = (emotionBreakdown[message.emotion!] ?? 0) + 1;
        }
      }

      return {
        'totalMessages': messages.length,
        'userMessages': userMessages,
        'aiMessages': aiMessages,
        'emotionBreakdown': emotionBreakdown,
      };
    } catch (e) {
      throw Exception('Failed to get message stats: $e');
    }
  }

  // Batch send messages (for importing chat history)
  Future<void> batchSendMessages(List<MessageModel> messages) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final batch = _firestore.batch();
      
      for (final message in messages) {
        final messageData = message.copyWith(
          userId: _currentUserId!,
        );
        
        final docRef = _firestore
            .collection(AppConstants.messagesCollection)
            .doc();
        
        batch.set(docRef, messageData.toFirestore());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch send messages: $e');
    }
  }
}