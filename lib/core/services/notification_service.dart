import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../../shared/models/notification_model.dart';
import '../../shared/providers/auth_provider.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // ignore: unused_field
  String? _currentUserId;

  void setUserId(String? userId) {
    _currentUserId = userId;
  }

  // Create a new notification
  Future<String> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    Map<String, dynamic>? data,
    String? actionUrl,
  }) async {
    try {
      final notification = NotificationModel(
        id: '', // Will be set by Firestore
        userId: userId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        createdAt: DateTime.now(),
        data: data,
        actionUrl: actionUrl,
      );

      final docRef = await _firestore
          .collection(AppConstants.notificationsCollection)
          .add(notification.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  // Get notifications for a user
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to recent 50 notifications
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  // Get unread notification count
  Stream<int> getUnreadNotificationCount(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(AppConstants.notificationsCollection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  // Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();
      final userNotifications = await _firestore
          .collection(AppConstants.notificationsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in userNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete all notifications: $e');
    }
  }

  // Create appointment reminder notification
  Future<void> createAppointmentReminder({
    required String userId,
    required String appointmentId,
    required String appointmentTitle,
    required DateTime appointmentTime,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Appointment Reminder',
      message: 'Your session "$appointmentTitle" is starting in 15 minutes',
      type: NotificationType.appointmentReminder,
      priority: NotificationPriority.high,
      data: {
        'appointmentId': appointmentId,
        'appointmentTime': appointmentTime.toIso8601String(),
      },
      actionUrl: '/appointments/$appointmentId',
    );
  }

  // Create session starting notification
  Future<void> createSessionStartingNotification({
    required String userId,
    required String appointmentId,
    required String appointmentTitle,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Session Ready',
      message: 'Your session "$appointmentTitle" is ready to join',
      type: NotificationType.sessionStarting,
      priority: NotificationPriority.urgent,
      data: {
        'appointmentId': appointmentId,
      },
      actionUrl: '/appointments/$appointmentId/join',
    );
  }

  // Create appointment confirmation notification
  Future<void> createAppointmentConfirmation({
    required String userId,
    required String appointmentId,
    required String appointmentTitle,
    required DateTime appointmentTime,
  }) async {
    await createNotification(
      userId: userId,
      title: 'Appointment Confirmed',
      message: 'Your session "$appointmentTitle" has been confirmed',
      type: NotificationType.appointmentConfirmation,
      priority: NotificationPriority.normal,
      data: {
        'appointmentId': appointmentId,
        'appointmentTime': appointmentTime.toIso8601String(),
      },
      actionUrl: '/appointments/$appointmentId',
    );
  }

  // Create general notification
  Future<void> createGeneralNotification({
    required String userId,
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.normal,
    String? actionUrl,
  }) async {
    await createNotification(
      userId: userId,
      title: title,
      message: message,
      type: NotificationType.general,
      priority: priority,
      actionUrl: actionUrl,
    );
  }
}

// Provider for notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  final authState = ref.watch(authStateProvider);
  authState.whenData((user) => service.setUserId(user?.uid));
  return service;
});

// Provider for user notifications stream
final userNotificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  
  return authState.when(
    data: (user) {
      if (user != null) {
        return notificationService.getUserNotifications(user.uid);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

// Provider for unread notification count
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final authState = ref.watch(authStateProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  
  return authState.when(
    data: (user) {
      if (user != null) {
        return notificationService.getUnreadNotificationCount(user.uid);
      }
      return Stream.value(0);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});