import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/appointment_model.dart';
import '../../core/constants/app_constants.dart';
import './ai_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  AppointmentService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  })  : _firestore = firestore,
        _auth = auth;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Create a new appointment with named parameters
  Future<String> createAppointment({
    required String title,
    required DateTime scheduledDateTime,
    required AppointmentType type,
    String? notes,
    int? durationMinutes,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final appointment = AppointmentModel(
        id: '', // Will be set by Firestore
        userId: _currentUserId!,
        title: title,
        scheduledDateTime: scheduledDateTime,
        type: type,
        status: AppointmentStatus.scheduled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: notes,
        durationMinutes: durationMinutes,
      );

      final docRef = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .add(appointment.toFirestore());

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create appointment: $e');
    }
  }

  // Get all appointments for current user (sorted in memory to avoid index requirement)
  Stream<List<AppointmentModel>> getUserAppointments() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
      
      // Sort in memory to avoid requiring a composite index
      appointments.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
      return appointments;
    });
  }

  // Get upcoming appointments (filtered and sorted in memory)
  Stream<List<AppointmentModel>> getUpcomingAppointments() {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    final now = DateTime.now();
    
    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .where((appointment) => 
              appointment.scheduledDateTime.isAfter(now) &&
              appointment.status == AppointmentStatus.scheduled)
          .toList();
      
      // Sort in memory
      appointments.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
      return appointments;
    });
  }

  // Update an appointment with named parameters
  Future<void> updateAppointment(
    String appointmentId, {
    DateTime? scheduledDateTime,
    String? notes,
    int? durationMinutes,
    String? summary,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (scheduledDateTime != null) {
        updateData['scheduledDateTime'] = Timestamp.fromDate(scheduledDateTime);
      }

      if (notes != null) {
        updateData['notes'] = notes;
      }

      if (durationMinutes != null) {
        updateData['durationMinutes'] = durationMinutes;
      }
      
      if (summary != null) {
        updateData['summary'] = summary;
      }

      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update appointment: $e');
    }
  }

  // Cancel an appointment
  Future<void> cancelAppointment(String appointmentId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .update({
        'status': AppointmentStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to cancel appointment: $e');
    }
  }

  // Delete an appointment
  Future<void> deleteAppointment(String appointmentId) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  // Get appointment by ID
  Future<AppointmentModel?> getAppointmentById(String appointmentId) async {
    if (_currentUserId == null) {
      return null;
    }

    try {
      final doc = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .get();

      if (doc.exists) {
        final appointment = AppointmentModel.fromFirestore(doc);
        // Ensure the appointment belongs to the current user
        if (appointment.userId == _currentUserId) {
          return appointment;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get appointment: $e');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(String appointmentId, AppointmentStatus status) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection(AppConstants.appointmentsCollection)
          .doc(appointmentId)
          .update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // Get appointments by date range (filtered in memory)
  Stream<List<AppointmentModel>> getAppointmentsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) {
    if (_currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection(AppConstants.appointmentsCollection)
        .where('userId', isEqualTo: _currentUserId)
        .snapshots()
        .map((snapshot) {
      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .where((appointment) => 
              appointment.scheduledDateTime.isAfter(startDate.subtract(const Duration(days: 1))) &&
              appointment.scheduledDateTime.isBefore(endDate.add(const Duration(days: 1))))
          .toList();
      
      // Sort in memory
      appointments.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
      return appointments;
    });
  }

  // Get appointment statistics
  Future<Map<String, int>> getAppointmentStats() async {
    if (_currentUserId == null) {
      return {
        'total': 0,
        'completed': 0,
        'scheduled': 0,
        'cancelled': 0,
      };
    }

    try {
      final snapshot = await _firestore
          .collection(AppConstants.appointmentsCollection)
          .where('userId', isEqualTo: _currentUserId)
          .get();

      final appointments = snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();

      return {
        'total': appointments.length,
        'completed': appointments.where((a) => !a.scheduledDateTime.isAfter(DateTime.now())).length,
        'scheduled': appointments.where((a) => a.scheduledDateTime.isAfter(DateTime.now())).length,
        'cancelled': appointments.where((a) => a.status == AppointmentStatus.cancelled).length,
      };
    } catch (e) {
      throw Exception('Failed to get appointment stats: $e');
    }
  }

  // Generate a summary for an appointment using AI
  Future<String> generateAppointmentSummary(String appointmentId, List<String> messageContents) async {
    if (_currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the appointment
      final appointment = await getAppointmentById(appointmentId);
      if (appointment == null) {
        throw Exception('Appointment not found');
      }

      // Create a prompt for the AI
      final prompt = """Please provide a concise summary of this therapy session. 
      Focus on key themes, insights, and any action items or recommendations.
      Session details: ${appointment.title} on ${appointment.scheduledDateTime.toString()}
      Session type: ${appointment.type.name}
      Session messages: ${messageContents.join('\n')}
      """;

      // Use the AI service to generate a summary
      final summary = await AIService.sendMessage(prompt, [
        {'role': 'system', 'content': 'You are an AI assistant tasked with summarizing therapy sessions.'}
      ]);

      // Update the appointment with the summary
      await updateAppointment(appointmentId, summary: summary);

      return summary;
    } catch (e) {
      throw Exception('Failed to generate appointment summary: $e');
    }
  }

  // Helper method to create the required Firestore indexes programmatically
  // Note: This is for documentation - indexes must be created via Firebase Console
  static Map<String, dynamic> getRequiredIndexes() {
    return {
      'appointments': [
        {
          'fields': [
            {'fieldPath': 'userId', 'order': 'ASCENDING'},
            {'fieldPath': 'scheduledDateTime', 'order': 'ASCENDING'},
          ],
          'queryScope': 'COLLECTION'
        },
        {
          'fields': [
            {'fieldPath': 'userId', 'order': 'ASCENDING'},
            {'fieldPath': 'status', 'order': 'ASCENDING'},
            {'fieldPath': 'scheduledDateTime', 'order': 'ASCENDING'},
          ],
          'queryScope': 'COLLECTION'
        }
      ]
    };
  }
}