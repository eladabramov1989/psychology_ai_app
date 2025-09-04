import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/services/ad_service.dart';

import '../../../../shared/providers/data_providers.dart';
import '../../../../shared/models/appointment_model.dart';
import '../../../appointments/presentation/pages/appointments_screen.dart';
import '../../../chat/presentation/pages/chat_screen.dart';
import '../../../profile/presentation/pages/profile_screen.dart';
import '../../../video_call/presentation/pages/video_call_screen.dart';

// Example notification count provider (replace with your logic)
final notificationCountProvider = StateProvider<int>((ref) => 3);

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardHome(),
    const AppointmentsScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
   /*  // Add this at the beginning of the build method
    final aiModel = PsychologyAIModel.defaultModel;
print( aiModel.properties);
    Future.delayed(Duration(seconds: 1), () async {
      final result = await ModelAnalyzer.isPsychologicallyOriented(aiModel); // Pass the aiModel instance
      print('Is model psychology-oriented? $result');
    }); */
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ad Banner
          const BannerAdWidget(),
          // Navigation Bar
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppTheme.surfaceColor,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.textSecondary,
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: 'Appointments',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat_outlined),
                activeIcon: Icon(Icons.chat),
                label: 'Chat',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outlined),
                activeIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final appointmentsAsync = ref.watch(userAppointmentsProvider);
    final sessionStatsAsync = ref.watch(sessionStatsProvider);
    final appointmentStatsAsync = ref.watch(appointmentStatsProvider);
    final notificationCount = ref.watch(notificationCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              FadeInDown(
                duration: AppConstants.animationDurationSlow,
                child: currentUser.when(
                  data: (user) => Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        backgroundImage: user?.profileImageUrl != null
                            ? NetworkImage(user!.profileImageUrl!)
                            : null,
                        child: user?.profileImageUrl == null
                            ? Text(
                                user?.firstName.substring(0, 1).toUpperCase() ??
                                    'U',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${user?.firstName ?? 'User'}!',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'How are you feeling today?',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          // Show notifications dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Notifications'),
                              content: SizedBox(
                                width: double.maxFinite,
                                child: ListView(
                                  shrinkWrap: true,
                                  children: [
                                    // Example notifications, replace with your logic
                                    const ListTile(
                                      leading: Icon(Icons.notifications),
                                      title: Text('Your session starts soon!'),
                                      subtitle: Text('Today at 15:00'),
                                    ),
                                    const ListTile(
                                      leading: Icon(Icons.notifications),
                                      title: Text('Appointment confirmed'),
                                      subtitle: Text('Tomorrow at 10:00'),
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(
                              Icons.notifications_outlined,
                              color: AppTheme.textSecondary,
                              size: 28,
                            ),
                            if (notificationCount > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Center(
                                    child: Text(
                                      notificationCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => Text('Error: $error'),
                ),
              ),

              const SizedBox(height: AppConstants.paddingXLarge),

              // Quick Actions
              FadeInUp(
                duration: AppConstants.animationDurationSlow,
                delay: const Duration(milliseconds: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.chat_bubble_outline,
                            title: 'Start Session',
                            subtitle: 'Talk to Dr. Sarah',
                            color: AppTheme.primaryColor,
                            onTap: () {
                              // Navigate to chat using callback
                              final parentState =
                                  context.findAncestorStateOfType<
                                      _DashboardScreenState>();
                              if (parentState != null) {
                                parentState._navigateToTab(2);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppConstants.paddingMedium),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.calendar_today_outlined,
                            title: 'Book Session',
                            subtitle: 'Schedule appointment',
                            color: AppTheme.secondaryColor,
                            onTap: () {
                              // Navigate to appointments using callback
                              final parentState =
                                  context.findAncestorStateOfType<
                                      _DashboardScreenState>();
                              if (parentState != null) {
                                parentState._navigateToTab(1);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingXLarge),

              // Progress Overview with Real Data
              FadeInUp(
                duration: AppConstants.animationDurationSlow,
                delay: const Duration(milliseconds: 400),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius:
                        BorderRadius.circular(AppConstants.borderRadiusLarge),
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
                      Text(
                        'Your Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // Real session data
                      sessionStatsAsync.when(
                        data: (sessionStats) => Column(
                          children: [
                            _ProgressItem(
                              label: 'Total Sessions',
                              value: '${sessionStats['totalSessions'] ?? 0}',
                              icon: Icons.psychology_outlined,
                            ),
                            _ProgressItem(
                              label: 'Average Duration',
                              value:
                                  '${sessionStats['averageDuration'] ?? 0} min',
                              icon: Icons.timer_outlined,
                            ),
                            _ProgressItem(
                              label: 'Average Rating',
                              value:
                                  '${(sessionStats['averageRating'] ?? 0.0).toStringAsFixed(1)}/5',
                              icon: Icons.star_outline,
                            ),
                          ],
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (error, stack) => const Column(
                          children: [
                            _ProgressItem(
                              label: 'Total Sessions',
                              value: '0',
                              icon: Icons.psychology_outlined,
                            ),
                            _ProgressItem(
                              label: 'Average Duration',
                              value: '0 min',
                              icon: Icons.timer_outlined,
                            ),
                            _ProgressItem(
                              label: 'Average Rating',
                              value: '0.0/5',
                              icon: Icons.star_outline,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      // Real appointment data
                      appointmentStatsAsync.when(
                        data: (appointmentStats) => Column(
                          children: [
                            _ProgressItem(
                              label: 'Total Appointments',
                              value: '${appointmentStats['total'] ?? 0}',
                              icon: Icons.calendar_today_outlined,
                            ),
                            _ProgressItem(
                              label: 'Completed',
                              value: '${appointmentStats['completed'] ?? 0}',
                              icon: Icons.check_circle_outline,
                            ),
                            _ProgressItem(
                              label: 'Scheduled',
                              value: '${appointmentStats['scheduled'] ?? 0}',
                              icon: Icons.schedule_outlined,
                            ),
                            _ProgressItem(
                              label: 'Canceled',
                              value: '${appointmentStats['canceled'] ?? 0}',
                              icon: Icons.cancel_outlined,
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (error, stack) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.paddingXLarge),

              // Next Appointment with Real Data
              FadeInUp(
                duration: AppConstants.animationDurationSlow,
                delay: const Duration(milliseconds: 600),
                child: appointmentsAsync.when(
                  data: (appointments) {
                    final nextAppointment = _getNextAppointment(appointments);
                    return _NextAppointmentCard(
                      appointment: nextAppointment,
                      onScheduleTap: () {
                        final parentState = context
                            .findAncestorStateOfType<_DashboardScreenState>();
                        if (parentState != null) {
                          parentState._navigateToTab(1);
                        }
                      },
                    );
                  },
                  loading: () => _NextAppointmentCard(
                    appointment: null,
                    onScheduleTap: () {
                      final parentState = context
                          .findAncestorStateOfType<_DashboardScreenState>();
                      if (parentState != null) {
                        parentState._navigateToTab(1);
                      }
                    },
                  ),
                  error: (error, stack) => _NextAppointmentCard(
                    appointment: null,
                    onScheduleTap: () {
                      final parentState = context
                          .findAncestorStateOfType<_DashboardScreenState>();
                      if (parentState != null) {
                        parentState._navigateToTab(1);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppointmentModel? _getNextAppointment(List<AppointmentModel> appointments) {
    final now = DateTime.now();
    final upcomingAppointments = appointments
        .where((appointment) =>
            appointment.scheduledDateTime.isAfter(now) &&
            (appointment.status == AppointmentStatus.scheduled ||
                appointment.status == AppointmentStatus.confirmed))
        .toList();

    if (upcomingAppointments.isEmpty) return null;

    upcomingAppointments
        .sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    return upcomingAppointments.first;
  }
}

class _NextAppointmentCard extends StatelessWidget {
  final AppointmentModel? appointment;
  final VoidCallback onScheduleTap;

  const _NextAppointmentCard({
    required this.appointment,
    required this.onScheduleTap,
  });

  @override
  Widget build(BuildContext context) {
    if (appointment == null) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next Appointment',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'No upcoming appointments',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            ElevatedButton(
              onPressed: onScheduleTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
              ),
              child: const Text('Schedule Now'),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final timeUntil = appointment!.scheduledDateTime.difference(now);
    final canJoin = _canJoinSession(appointment!, now);

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next Appointment',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            appointment!.title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Row(
            children: [
              Icon(
                appointment!.type == AppointmentType.videoCall
                    ? Icons.video_call_outlined
                    : Icons.chat_outlined,
                color: Colors.white.withOpacity(0.9),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                appointment!.type == AppointmentType.videoCall
                    ? 'Video Call'
                    : 'Chat Session',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Icon(
                Icons.schedule,
                color: Colors.white.withOpacity(0.9),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _formatAppointmentTime(appointment!.scheduledDateTime, context),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            _getTimeUntilText(timeUntil),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: canJoin
                      ? () => _joinSession(context, appointment!)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        canJoin ? Colors.white : Colors.white.withOpacity(0.3),
                    foregroundColor: canJoin
                        ? AppTheme.primaryColor
                        : Colors.white.withOpacity(0.7),
                  ),
                  child: Text(canJoin ? 'Join Now' : 'Not Ready'),
                ),
              ),
              const SizedBox(width: AppConstants.paddingSmall),
              OutlinedButton(
                onPressed: onScheduleTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canJoinSession(AppointmentModel appointment, DateTime now) {
    final sessionTime = appointment.scheduledDateTime;
    final timeDifference = sessionTime.difference(now);

    // Allow joining 15 minutes before and up to 30 minutes after scheduled time
    return timeDifference.inMinutes >= -30 && timeDifference.inMinutes <= 15;
  }

  String _formatAppointmentTime(DateTime dateTime, [BuildContext? context]) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final appointmentDate =
        DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = context != null
        ? TimeOfDay.fromDateTime(dateTime).format(context)
        : '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (appointmentDate == today) {
      return 'Today $timeStr';
    } else if (appointmentDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow $timeStr';
    } else {
      return '${dateTime.day}/${dateTime.month} $timeStr';
    }
  }

  String _getTimeUntilText(Duration timeUntil) {
    if (timeUntil.isNegative) {
      final absTime = timeUntil.abs();
      if (absTime.inMinutes < 60) {
        return 'Started ${absTime.inMinutes} minutes ago';
      } else {
        return 'Started ${absTime.inHours} hours ago';
      }
    } else {
      if (timeUntil.inMinutes < 60) {
        return 'In ${timeUntil.inMinutes} minutes';
      } else if (timeUntil.inHours < 24) {
        return 'In ${timeUntil.inHours} hours';
      } else {
        return 'In ${timeUntil.inDays} days';
      }
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
      // Navigate to chat screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to chat session...'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    }
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ProgressItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingSmall),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}