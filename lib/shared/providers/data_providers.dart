import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/appointment_service.dart';
import '../../core/services/session_service.dart';
import '../../core/services/message_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/models/appointment_model.dart';
import '../../shared/models/session_model.dart';
import '../../shared/models/message_model.dart';

// Service providers
final appointmentServiceProvider = Provider<AppointmentService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return AppointmentService(auth: auth, firestore: firestore);
});

final sessionServiceProvider = Provider<SessionService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return SessionService(auth: auth, firestore: firestore);
});

final messageServiceProvider = Provider<MessageService>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(firestoreProvider);
  return MessageService(auth: auth, firestore: firestore);
});

// Data providers
final userAppointmentsProvider = StreamProvider<List<AppointmentModel>>((ref) {
  final appointmentService = ref.watch(appointmentServiceProvider);
  return appointmentService.getUserAppointments();
});

final upcomingAppointmentsProvider = StreamProvider<List<AppointmentModel>>((ref) {
  final appointmentService = ref.watch(appointmentServiceProvider);
  return appointmentService.getUpcomingAppointments();
});

final userSessionsProvider = StreamProvider<List<SessionModel>>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getUserSessions();
});

final activeSessionProvider = FutureProvider<SessionModel?>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getActiveSession();
});

// Session messages provider
final sessionMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, sessionId) {
  final messageService = ref.watch(messageServiceProvider);
  return messageService.getSessionMessages(sessionId);
});

// Recent messages provider
final recentMessagesProvider = StreamProvider<List<MessageModel>>((ref) {
  final messageService = ref.watch(messageServiceProvider);
  return messageService.getRecentMessages();
});

// Statistics providers
final appointmentStatsProvider = FutureProvider<Map<String, int>>((ref) {
  final appointmentService = ref.watch(appointmentServiceProvider);
  return appointmentService.getAppointmentStats();
});

final sessionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final sessionService = ref.watch(sessionServiceProvider);
  return sessionService.getSessionStats();
});

final messageStatsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  final messageService = ref.watch(messageServiceProvider);
  return messageService.getMessageStats();
});

// Unread message count provider
final unreadMessageCountProvider = FutureProvider<int>((ref) {
  final messageService = ref.watch(messageServiceProvider);
  return messageService.getUnreadMessageCount();
});

// Current session provider (for active video/chat sessions)
final currentSessionProvider = StateProvider<SessionModel?>((ref) => null);

// Loading states
final appointmentLoadingProvider = StateProvider<bool>((ref) => false);
final sessionLoadingProvider = StateProvider<bool>((ref) => false);
final messageLoadingProvider = StateProvider<bool>((ref) => false);