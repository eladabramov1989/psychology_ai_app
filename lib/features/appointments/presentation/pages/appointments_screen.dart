import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../video_call/presentation/pages/video_call_screen.dart';

class AppointmentsScreen extends ConsumerStatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  ConsumerState<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends ConsumerState<AppointmentsScreen> {
  @override
  Widget build(BuildContext context) {
    final appointmentsAsync = ref.watch(userAppointmentsProvider);
    final isLoading = ref.watch(appointmentLoadingProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Appointments',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              _showScheduleDialog(context);
            },
            icon: const Icon(
              Icons.add,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
      body: appointmentsAsync.when(
        data: (appointments) => appointments.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userAppointmentsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 100),
                      child: _buildAppointmentCard(appointment, index),
                    );
                  },
                ),
              ),
        loading: () => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        error: (error, stackTrace) => _buildErrorState(error.toString()),
      ),
      /*     floatingActionButton: FloatingActionButton(
        onPressed: isLoading
            ? null
            : () {
                _showScheduleDialog(context);
              },
        backgroundColor: isLoading
            ? AppTheme.primaryColor.withOpacity(0.5)
            : AppTheme.primaryColor,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.add, color: Colors.white),
      ), */
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInUp(
            child: Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'No Appointments Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            child: Text(
              'Schedule your first session with Dr. Sarah',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          FadeInUp(
            delay: const Duration(milliseconds: 600),
            child: ElevatedButton(
              onPressed: () {
                _showScheduleDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.paddingLarge,
                  vertical: AppConstants.paddingMedium,
                ),
              ),
              child: Text(
                'Schedule Session',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            error,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(userAppointmentsProvider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
                vertical: AppConstants.paddingMedium,
              ),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment, int index) {
    final isUpcoming = appointment.scheduledDateTime.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isUpcoming
                      ? AppTheme.primaryColor.withOpacity(0.1)
                      : AppTheme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  appointment.type == AppointmentType.videoCall
                      ? Icons.video_call_outlined
                      : Icons.chat_outlined,
                  color: isUpcoming
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      appointment.type.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  if (appointment.summary?.isNotEmpty == true)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.summarize,
                        size: 16,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status.displayName,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getStatusColor(appointment.status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${appointment.scheduledDateTime.day}/${appointment.scheduledDateTime.month}/${appointment.scheduledDateTime.year}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              const Icon(
                Icons.access_time,
                size: 16,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                TimeOfDay.fromDateTime(appointment.scheduledDateTime)
                    .format(context),
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              if (appointment.durationMinutes != null) ...[
                const SizedBox(width: AppConstants.paddingMedium),
                const Icon(
                  Icons.timer,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${appointment.durationMinutes}min',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (appointment.notes?.isNotEmpty == true) ...[
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              appointment.notes!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: 40,
                width: 100,
                child: OutlinedButton(
                  onPressed: () {
                    _showAppointmentDetails(context, appointment, isUpcoming);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                  child: const Center(
                    child: Text(
                      'Details',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                width: 100,
                child: OutlinedButton(
                  onPressed: !isUpcoming && appointment.summary == null
                      ? () {
                          _generateSummary(context, appointment);
                        }
                      : isUpcoming &&
                              appointment.status != AppointmentStatus.cancelled
                          ? () {
                              _editAppointment(context, appointment);
                            }
                          : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    foregroundColor: !isUpcoming && appointment.summary == null
                        ? AppTheme.secondaryColor
                        : AppTheme.secondaryColor,
                    side: BorderSide(
                        color: !isUpcoming && appointment.summary == null
                            ? AppTheme.secondaryColor
                            : AppTheme.secondaryColor),
                  ),
                  child: Center(
                    child: Text(
                      !isUpcoming && appointment.summary == null
                          ? 'Summarize'
                          : 'Edit',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                width: 100,
                child: ElevatedButton(
                  onPressed: _canJoinSession(appointment)
                      ? () {
                          _joinSession(context, appointment);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: Center(
                    child: Text(
                      _getActionButtonText(appointment, isUpcoming),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.scheduled:
        return AppTheme.primaryColor;
      case AppointmentStatus.confirmed:
        return Colors.green;
      case AppointmentStatus.inProgress:
        return Colors.orange;
      case AppointmentStatus.completed:
        return AppTheme.textSecondary;
      case AppointmentStatus.cancelled:
        return Colors.red;
      case AppointmentStatus.rescheduled:
        return Colors.blue;
    }
  }

  bool _canJoinSession(AppointmentModel appointment) {
    if (appointment.status != AppointmentStatus.scheduled &&
        appointment.status != AppointmentStatus.confirmed) {
      return false;
    }

    final now = DateTime.now();
    final appointmentTime = appointment.scheduledDateTime;

    // Allow joining 15 minutes before to 30 minutes after scheduled time
    final earliestJoinTime =
        appointmentTime.subtract(const Duration(minutes: 15));
    final latestJoinTime = appointmentTime.add(const Duration(minutes: 30));

    return now.isAfter(earliestJoinTime) && now.isBefore(latestJoinTime);
  }

  String _getActionButtonText(AppointmentModel appointment, bool isUpcoming) {
    if (!isUpcoming) return 'Completed';

    switch (appointment.status) {
      case AppointmentStatus.scheduled:
      case AppointmentStatus.confirmed:
        return 'Join';
      case AppointmentStatus.inProgress:
        return 'Rejoin';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }

  void _joinSession(BuildContext context, AppointmentModel appointment) {
    if (appointment.type == AppointmentType.videoCall) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(appointment: appointment),
        ),
      );
    } else {
      // Handle chat session - could navigate to a chat screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat sessions will be available soon'),
        ),
      );
    }
  }

  void _showScheduleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Schedule Session',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.video_call_outlined),
              title: const Text('Video Session'),
              subtitle: const Text('Face-to-face therapy session'),
              onTap: () {
                Navigator.pop(context);
                _showDateTimeSelection(AppointmentType.videoCall);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('Chat Session'),
              subtitle: const Text('Text-based therapy session'),
              onTap: () {
                Navigator.pop(context);
                _showDateTimeSelection(AppointmentType.chatSession);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDateTimeSelection(AppointmentType type) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = TimeOfDay.now();
    int selectedDuration = 60; // Default 60 minutes
    String notes = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Select Date & Time',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Duration'),
                  subtitle: Text('$selectedDuration minutes'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Select Duration'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<int>(
                              title: const Text('30 minutes'),
                              value: 30,
                              groupValue: selectedDuration,
                              onChanged: (value) {
                                setState(() {
                                  selectedDuration = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<int>(
                              title: const Text('45 minutes'),
                              value: 45,
                              groupValue: selectedDuration,
                              onChanged: (value) {
                                setState(() {
                                  selectedDuration = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<int>(
                              title: const Text('60 minutes'),
                              value: 60,
                              groupValue: selectedDuration,
                              onChanged: (value) {
                                setState(() {
                                  selectedDuration = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<int>(
                              title: const Text('90 minutes'),
                              value: 90,
                              groupValue: selectedDuration,
                              onChanged: (value) {
                                setState(() {
                                  selectedDuration = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add any specific notes for this session...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _scheduleAppointment(
                    type, selectedDate, selectedTime, selectedDuration, notes);
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleAppointment(AppointmentType type, DateTime date, TimeOfDay time,
      int durationMinutes, String notes) async {
    ref.read(appointmentLoadingProvider.notifier).state = true;

    try {
      final scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final appointmentService = ref.read(appointmentServiceProvider);

      await appointmentService.createAppointment(
        title: 'Therapy Session with Dr. Sarah',
        scheduledDateTime: scheduledDateTime,
        type: type,
        notes: notes.isNotEmpty ? notes : null,
        durationMinutes: durationMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.displayName} scheduled successfully!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to schedule appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(appointmentLoadingProvider.notifier).state = false;
    }
  }

  void _showAppointmentDetails(
      BuildContext context, AppointmentModel appointment, bool isUpcoming) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Appointment Details',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailRow('Session', appointment.title),
              _DetailRow('Type', appointment.type.displayName),
              _DetailRow('Date',
                  '${appointment.scheduledDateTime.day}/${appointment.scheduledDateTime.month}/${appointment.scheduledDateTime.year}'),
              _DetailRow(
                  'Time',
                  TimeOfDay.fromDateTime(appointment.scheduledDateTime)
                      .format(context)),
              if (appointment.durationMinutes != null)
                _DetailRow(
                    'Duration', '${appointment.durationMinutes} minutes'),
              _DetailRow('Status', appointment.status.displayName),
              if (appointment.notes?.isNotEmpty == true)
                _DetailRow('Notes', appointment.notes!),
              if (appointment.summary?.isNotEmpty == true) ...[
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  'Session Summary',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingSmall),
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.2)),
                  ),
                  child: Text(
                    appointment.summary!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Dr. Sarah will be ready to meet with you at the scheduled time. Please ensure you have a stable internet connection.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!isUpcoming && appointment.summary == null)
            TextButton(
              onPressed: () => _generateSummary(context, appointment),
              child: const Text('Generate Summary'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateSummary(
      BuildContext context, AppointmentModel appointment) async {
    final appointmentService = ref.read(appointmentServiceProvider);
    final sessionService = ref.read(sessionServiceProvider);
    final messageService = ref.read(messageServiceProvider);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Generating summary...'),
          ],
        ),
      ),
    );

    try {
      // Get sessions for this appointment
      final sessions =
          await sessionService.getSessionsByAppointment(appointment.id).first;

      if (sessions.isEmpty) {
        throw Exception('No sessions found for this appointment');
      }

      // Get the most recent session
      final session = sessions.first;

      // Get messages for this session
      final messages =
          await messageService.getSessionMessages(session.id).first;

      // Extract message contents
      final messageContents = messages.map((msg) => msg.content).toList();

      // Generate the summary
      await appointmentService.generateAppointmentSummary(
          appointment.id, messageContents);

      // Close the loading dialog
      if (context.mounted) Navigator.pop(context);

      // Close the appointment details dialog
      if (context.mounted) Navigator.pop(context);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Summary generated successfully!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      // Close the loading dialog
      if (context.mounted) Navigator.pop(context);

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate summary: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editAppointment(BuildContext context, AppointmentModel appointment) {
    DateTime selectedDate = appointment.scheduledDateTime;
    TimeOfDay selectedTime =
        TimeOfDay.fromDateTime(appointment.scheduledDateTime);
    int selectedDuration =
        appointment.durationMinutes ?? 60; // Default to 60 if null
    String notes = appointment.notes ?? '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            'Edit Appointment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.timer),
                  title: const Text('Duration'),
                  subtitle: Text('$selectedDuration minutes'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Select Duration'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<int>(
                              title: const Text('30 minutes'),
                              value: 30,
                              groupValue: selectedDuration,
                              onChanged: (value) {
                                setState(() {
                                  selectedDuration = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<int>(
                              title: const Text('45 minutes'),
                              value: 45,
                              groupValue: selectedDuration,
                              onChanged: (value) {
                                setState(() {
                                  selectedDuration = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<int>(
                              title: const Text('60 minutes'),
                              value: 60,
                              groupValue: selectedDuration,
                              onChanged: (value) {
                                setState(() {
                                  selectedDuration = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<int>(
                              title: const Text('90 minutes'),
                              value: 90,
                              groupValue: selectedDuration,
                              onChanged: (value) {
                                setState(() {
                                  selectedDuration = value!;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Add any specific notes for this session...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  controller: TextEditingController(text: notes),
                  onChanged: (value) => notes = value,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _cancelAppointment(appointment);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Cancel Appointment'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _updateAppointment(appointment, selectedDate, selectedTime,
                    selectedDuration, notes);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _DetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateAppointment(AppointmentModel appointment, DateTime date,
      TimeOfDay time, int durationMinutes, String notes) async {
    ref.read(appointmentLoadingProvider.notifier).state = true;

    try {
      final scheduledDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      final appointmentService = ref.read(appointmentServiceProvider);

      await appointmentService.updateAppointment(
        appointment.id,
        scheduledDateTime: scheduledDateTime,
        notes: notes.isNotEmpty ? notes : null,
        durationMinutes: durationMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment updated successfully!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(appointmentLoadingProvider.notifier).state = false;
    }
  }

  void _cancelAppointment(AppointmentModel appointment) async {
    ref.read(appointmentLoadingProvider.notifier).state = true;

    try {
      final appointmentService = ref.read(appointmentServiceProvider);

      await appointmentService.cancelAppointment(appointment.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment cancelled successfully!'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel appointment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      ref.read(appointmentLoadingProvider.notifier).state = false;
    }
  }
}

extension on AppointmentType {
  String get displayName {
    switch (this) {
      case AppointmentType.videoCall:
        return 'Video Call';
      case AppointmentType.chatSession:
        return 'Chat Session';
    }
  }
}

extension on AppointmentStatus {
  String get displayName {
    switch (this) {
      case AppointmentStatus.scheduled:
        return 'Scheduled';
      case AppointmentStatus.confirmed:
        return 'Confirmed';
      case AppointmentStatus.inProgress:
        return 'In Progress';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
      case AppointmentStatus.rescheduled:
        return 'Rescheduled';
    }
  }
}
