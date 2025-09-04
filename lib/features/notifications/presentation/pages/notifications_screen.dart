import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'package:psychology_ai_app/shared/providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/models/notification_model.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(userNotificationsProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          unreadCount.when(
            data: (count) => count > 0
                ? TextButton(
                    onPressed: () async {
                      final notificationService = ref.read(notificationServiceProvider);
                      final authState = ref.read(authStateProvider);
                      authState.whenData((user) async {
                        if (user != null) {
                          await notificationService.markAllAsRead(user.uid);
                        }
                      });
                    },
                    child: Text(
                      'Mark all read',
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final notificationService = ref.read(notificationServiceProvider);
              final authState = ref.read(authStateProvider);
              
              if (value == 'clear_all') {
                final confirmed = await _showClearAllDialog();
                if (confirmed == true) {
                  authState.whenData((user) async {
                    if (user != null) {
                      await notificationService.deleteAllNotifications(user.uid);
                    }
                  });
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Clear all',
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) => notifications.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(userNotificationsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 100),
                      child: _buildNotificationCard(notification, index),
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeInUp(
            child: Icon(
              Icons.notifications_none_outlined,
              size: 80,
              color: AppTheme.primaryColor.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            child: Text(
              'No Notifications',
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
              'You\'re all caught up! New notifications will appear here.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
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
              ref.invalidate(userNotificationsProvider);
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

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? AppTheme.surfaceColor 
            : AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        border: notification.isRead 
            ? null 
            : Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          onTap: () => _handleNotificationTap(notification),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppConstants.paddingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: notification.isRead 
                                    ? FontWeight.w500 
                                    : FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeago.format(notification.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (notification.priority == NotificationPriority.high ||
                              notification.priority == NotificationPriority.urgent)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: notification.priority == NotificationPriority.urgent
                                    ? Colors.red.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                notification.priority == NotificationPriority.urgent
                                    ? 'URGENT'
                                    : 'HIGH',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: notification.priority == NotificationPriority.urgent
                                      ? Colors.red
                                      : Colors.orange,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleNotificationAction(notification, value),
                  itemBuilder: (context) => [
                    if (!notification.isRead)
                      PopupMenuItem(
                        value: 'mark_read',
                        child: Row(
                          children: [
                            const Icon(Icons.mark_email_read, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Mark as read',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 16, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(
                            'Delete',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentReminder:
      case NotificationType.appointmentConfirmation:
      case NotificationType.appointmentCancellation:
        return Icons.calendar_today;
      case NotificationType.sessionStarting:
      case NotificationType.sessionEnded:
        return Icons.video_call;
      case NotificationType.messageReceived:
        return Icons.chat;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      case NotificationType.general:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentReminder:
      case NotificationType.appointmentConfirmation:
        return AppTheme.primaryColor;
      case NotificationType.appointmentCancellation:
        return Colors.red;
      case NotificationType.sessionStarting:
        return Colors.green;
      case NotificationType.sessionEnded:
        return AppTheme.textSecondary;
      case NotificationType.messageReceived:
        return Colors.blue;
      case NotificationType.systemUpdate:
        return Colors.orange;
      case NotificationType.general:
        return AppTheme.primaryColor;
    }
  }

  void _handleNotificationTap(NotificationModel notification) async {
    // Mark as read if not already read
    if (!notification.isRead) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.markAsRead(notification.id);
    }

    // Handle navigation based on actionUrl or type
    if (notification.actionUrl != null) {
      // TODO: Implement deep linking navigation
      // For now, just show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Navigation to: ${notification.actionUrl}'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    }
  }

  void _handleNotificationAction(NotificationModel notification, String action) async {
    final notificationService = ref.read(notificationServiceProvider);
    
    switch (action) {
      case 'mark_read':
        await notificationService.markAsRead(notification.id);
        break;
      case 'delete':
        await notificationService.deleteNotification(notification.id);
        break;
    }
  }

  Future<bool?> _showClearAllDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Notifications',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete all notifications? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}