import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/session_model.dart';
import '../../core/constants/app_constants.dart';

class SessionService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SessionService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Start a new session
  Future<String> startSession(String appointmentId, String type) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final session = SessionModel(
        id: '',
        userId: _currentUserId!,
        appointmentId: appointmentId,
        type: type,
        startTime: DateTime.now(),
        durationMinutes: 0,
        status: 'Active',
        messageIds: [],
        metadata: {
          'startedAt': DateTime.now().toIso8601String(),
          'platform': 'mobile',
        },
      );

      final docRef = await _firestore
          .collection(AppConstants.sessionsCollection)
          .add(session.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to start session: $e');
    }
  }

  // End a session
  Future<void> endSession(String sessionId, {double? rating, String? feedback}) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final sessionDoc = await _firestore
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found');
      }

      final session = SessionModel.fromFirestore(sessionDoc);
      final endTime = DateTime.now();
      final duration = endTime.difference(session.startTime);

      await _firestore
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId)
          .update({
        'endTime': Timestamp.fromDate(endTime),
        'durationMinutes': duration.inMinutes,
        'status': 'Completed',
        'rating': rating,
        'feedback': feedback,
        'metadata': {
          ...session.metadata,
          'endedAt': endTime.toIso8601String(),
          'actualDuration': duration.inMinutes,
        },
      });
    } catch (e) {
      throw Exception('Failed to end session: $e');
    }
  }

  // Get active session for user
  Future<SessionModel?> getActiveSession() async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.sessionsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .where('status', isEqualTo: 'Active')
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return SessionModel.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get active session: $e');
    }
  }

  // Get session by ID
  Future<SessionModel?> getSessionById(String sessionId) async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId)
          .get();

      if (doc.exists) {
        final session = SessionModel.fromFirestore(doc);
        // Ensure the session belongs to the current user
        if (session.userId == _currentUserId) {
          return session;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get session: $e');
    }
  }

  // Get all sessions for user
  Stream<List<SessionModel>> getUserSessions() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.sessionsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get sessions by appointment ID
  Stream<List<SessionModel>> getSessionsByAppointment(String appointmentId) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.sessionsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .where('appointmentId', isEqualTo: appointmentId)
        //.orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();
    });
  }

  // Add message to session
  Future<void> addMessageToSession(String sessionId, String messageId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId)
          .update({
        'messageIds': FieldValue.arrayUnion([messageId]),
      });
    } catch (e) {
      throw Exception('Failed to add message to session: $e');
    }
  }

  // Update session metadata
  Future<void> updateSessionMetadata(String sessionId, Map<String, dynamic> metadata) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final sessionDoc = await _firestore
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId)
          .get();

      if (!sessionDoc.exists) {
        throw Exception('Session not found');
      }

      final session = SessionModel.fromFirestore(sessionDoc);
      final updatedMetadata = {...session.metadata, ...metadata};

      await _firestore
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId)
          .update({
        'metadata': updatedMetadata,
      });
    } catch (e) {
      throw Exception('Failed to update session metadata: $e');
    }
  }

  // Get session statistics
  Future<Map<String, dynamic>> getSessionStats() async {
    if (_currentUserId == null) {
      return {
        'totalSessions': 0,
        'completedSessions': 0,
        'totalDuration': 0,
        'averageRating': 0.0,
        'videoSessions': 0,
        'chatSessions': 0,
      };
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.sessionsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final sessions = snapshot.docs
          .map((doc) => SessionModel.fromFirestore(doc))
          .toList();

      final completedSessions = sessions.where((s) => s.status == 'Completed').toList();
      final totalDuration = completedSessions.fold(0, (sum, session) => sum + session.durationMinutes);
      final ratingsSum = completedSessions
          .where((s) => s.rating != null)
          .fold(0.0, (sum, session) => sum + session.rating!);
      final ratedSessions = completedSessions.where((s) => s.rating != null).length;

      return {
        'totalSessions': sessions.length,
        'completedSessions': completedSessions.length,
        'totalDuration': totalDuration,
        'averageRating': ratedSessions > 0 ? ratingsSum / ratedSessions : 0.0,
        'videoSessions': sessions.where((s) => s.type == 'Video Call').length,
        'chatSessions': sessions.where((s) => s.type == 'Chat Session').length,
      };
    } catch (e) {
      throw Exception('Failed to get session stats: $e');
    }
  }

  // Cancel an active session
  Future<void> cancelSession(String sessionId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(AppConstants.sessionsCollection)
          .doc(sessionId)
          .update({
        'status': 'Cancelled',
        'endTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel session: $e');
    }
  }
}