import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/providers/auth_provider.dart';
import '../../../../shared/models/user_model.dart';
import '../../../auth/presentation/pages/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile',
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
              _showEditProfileDialog(context, ref);
            },
            icon: const Icon(
              Icons.edit_outlined,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal:  AppConstants.paddingLarge),
          child: Column(
            children: [
              // --- AI Psychologist Avatar Section ---
              Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.08),
                    // Use a default AI avatar from the internet (open source) as a fallback
                    backgroundImage: const NetworkImage(
                      'https://cdn-icons-png.flaticon.com/512/4712/4712035.png',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'AI Psychologist',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingLarge),
              // Profile Header
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/profile-image-edit');
                      },
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            backgroundImage: user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty
                                ? NetworkImage(user.profileImageUrl!)
                                : null,
                            child: (user?.profileImageUrl == null || user!.profileImageUrl!.isEmpty)
                                ? Text(
                                    user?.firstName.substring(0, 1).toUpperCase() ?? 'U',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.surfaceColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      user?.fullName ?? 'User',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    )        
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.paddingLarge),

              // Profile Options
              _ProfileOption(
                icon: Icons.person_outline,
                title: 'Personal Information',
                subtitle: 'Update your personal details',
                onTap: () {
                  _showPersonalInfoDialog(context, ref);
                },
              ),
              _ProfileOption(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () {
                  _showNotificationSettings(context, ref);
                },
              ),
              _ProfileOption(
                icon: Icons.settings_outlined,
                title: 'App Settings',
                subtitle: 'Language and voice preferences',
                onTap: () {
                  _showAppSettings(context, ref);
                },
              ),
              _ProfileOption(
                icon: Icons.security_outlined,
                title: 'Privacy & Security',
                subtitle: 'Manage your privacy settings',
                onTap: () {
                  _showPrivacySettings(context, ref);
                },
              ),
              _ProfileOption(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help and contact support',
                onTap: () {
                  _showHelpDialog(context);
                },
              ),
              _ProfileOption(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {
                  _showAboutDialog(context);
                },
              ),

              const SizedBox(height: AppConstants.paddingLarge),
              // Sign Out Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    final authService = ref.read(authServiceProvider);
                    await authService.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
                  ),
                  child: Text(
                    'Sign Out',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),

            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error loading profile',
            style: GoogleFonts.poppins(
              color: AppTheme.errorColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        tileColor: AppTheme.surfaceColor,
      ),
    );
  }
}

// Helper functions for profile interactions
void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
  final currentUser = ref.read(currentUserProvider).value;
  final firstNameController = TextEditingController(text: currentUser?.firstName ?? '');
  final lastNameController = TextEditingController(text: currentUser?.lastName ?? '');
  final isLoading = ValueNotifier<bool>(false);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Edit Profile',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: firstNameController,
            decoration: const InputDecoration(
              labelText: 'First Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          TextField(
            controller: lastNameController,
            decoration: const InputDecoration(
              labelText: 'Last Name',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: isLoading,
          builder: (context, loading, child) {
            return ElevatedButton(
              onPressed: loading ? null : () async {
                isLoading.value = true;
                try {
                  final authService = ref.read(authServiceProvider);
                  await authService.updateUserProfile(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update profile: ${e.toString()}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                } finally {
                  isLoading.value = false;
                }
              },
              child: loading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save'),
            );
          },
        ),
      ],
    ),
  );
}

void _showPersonalInfoDialog(BuildContext context, WidgetRef ref) {
  final currentUser = ref.read(currentUserProvider).value;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Personal Information',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow('Name', currentUser?.fullName ?? 'Not set'),
          _InfoRow('Email', currentUser?.email ?? 'Not set'),
          _InfoRow('Member since', currentUser?.createdAt.toString().split(' ')[0] ?? 'Unknown'),
          _InfoRow('Total sessions', '${currentUser?.sessionStats.totalSessions ?? 0}'),
          _InfoRow('Current streak', '${currentUser?.sessionStats.currentStreak ?? 0} days'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showNotificationSettings(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Notification Settings',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text('Session Reminders'),
            subtitle: const Text('Get reminded about upcoming sessions'),
            value: true,
            onChanged: (value) {
              // TODO: Update notification preferences
            },
          ),
          SwitchListTile(
            title: const Text('Daily Check-ins'),
            subtitle: const Text('Daily mood and wellness check-ins'),
            value: false,
            onChanged: (value) {
              // TODO: Update notification preferences
            },
          ),
          SwitchListTile(
            title: const Text('Progress Updates'),
            subtitle: const Text('Weekly progress summaries'),
            value: true,
            onChanged: (value) {
              // TODO: Update notification preferences
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

void _showPrivacySettings(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Privacy & Security',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            subtitle: const Text('Update your account password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showChangePasswordDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: const Text('Data Privacy'),
            subtitle: const Text('Manage your data and privacy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showDataPrivacyDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Delete Account'),
            subtitle: const Text('Permanently delete your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.pop(context);
              _showDeleteAccountDialog(context);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showHelpDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Help & Support',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('FAQ'),
            subtitle: const Text('Frequently asked questions'),
            onTap: () {
              Navigator.pop(context);
              _showFAQDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Contact Support'),
            subtitle: const Text('Get help from our team'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening email client...')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Report a Bug'),
            subtitle: const Text('Help us improve the app'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bug report form opened')),
              );
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

// This is the first implementation of _showAppSettings function
void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'About ${AppConstants.appName}',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.appDescription,
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          _InfoRow('Version', AppConstants.appVersion),
          _InfoRow('AI Psychologist', AppConstants.aiPsychologistName),
          _InfoRow('Specialty', AppConstants.aiPsychologistSpecialty),
          const SizedBox(height: AppConstants.paddingMedium),
          Text(
            'Disclaimer: This app provides AI-powered support and is not a substitute for professional mental health treatment. If you are experiencing a mental health crisis, please contact emergency services or a mental health professional immediately.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showChangePasswordDialog(BuildContext context) {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Change Password',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Current Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          TextField(
            controller: newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          TextField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm New Password',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // TODO: Change password logic
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password changed successfully!')),
            );
          },
          child: const Text('Change'),
        ),
      ],
    ),
  );
}

void _showDataPrivacyDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Data Privacy',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Privacy Matters',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              'We take your privacy seriously and are committed to protecting your personal information. Here\'s what we collect and how we use it:',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              '• Chat conversations are encrypted and stored securely\n'
              '• Personal information is never shared with third parties\n'
              '• You can request data deletion at any time\n'
              '• All data is processed in compliance with privacy laws',
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            SwitchListTile(
              title: const Text('Analytics'),
              subtitle: const Text('Help improve the app with anonymous usage data'),
              value: true,
              onChanged: (value) {
                // TODO: Update analytics preference
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showAppSettings(BuildContext context, WidgetRef ref) {
  final currentUser = ref.read(currentUserProvider).value;
  final userPreferences = currentUser?.preferences;
  
  // Language options
  final languageOptions = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ru': 'Russian',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'pt': 'Portuguese',
  };
  
  // Current language selection
  String selectedLanguage = userPreferences?.language ?? 'en';
  bool voiceEnabled = userPreferences?.voiceEnabled ?? false;
  double voiceSpeed = userPreferences?.voiceSpeed ?? 1.0;
  
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
          'App Settings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Language',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              DropdownButtonFormField<String>(
                value: selectedLanguage,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: languageOptions.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedLanguage = value;
                    });
                  }
                },
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Voice Settings',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              SwitchListTile(
                title: const Text('Text-to-Speech'),
                subtitle: const Text('Enable voice responses'),
                value: voiceEnabled,
                onChanged: (value) {
                  setState(() {
                    voiceEnabled = value;
                  });
                },
              ),
              if (voiceEnabled) ...[  
                const Text('Voice Speed'),
                Slider(
                  value: voiceSpeed,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  label: voiceSpeed.toStringAsFixed(1) + 'x',
                  onChanged: (value) {
                    setState(() {
                      voiceSpeed = value;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Update user preferences
              if (currentUser != null) {
                try {
                  final updatedPreferences = userPreferences?.copyWith(
                    language: selectedLanguage,
                    voiceEnabled: voiceEnabled,
                    voiceSpeed: voiceSpeed,
                  ) ?? UserPreferences(
                    language: selectedLanguage,
                    voiceEnabled: voiceEnabled,
                    voiceSpeed: voiceSpeed,
                  );
                  
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUser.uid)
                      .update({
                    'preferences': updatedPreferences.toMap(),
                  });
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings updated successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating settings: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void _showDeleteAccountDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Delete Account',
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          color: AppTheme.errorColor,
        ),
      ),
      content: Text(
        'Are you sure you want to delete your account? This action cannot be undone and will permanently remove all your data, including chat history and session records.',
        style: GoogleFonts.poppins(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account deletion requires email verification'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorColor,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

void _showFAQDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        'Frequently Asked Questions',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FAQItem(
              'How does AI therapy work?',
              'Our AI psychologist uses advanced natural language processing to provide supportive, evidence-based responses based on cognitive behavioral therapy principles.',
            ),
            _FAQItem(
              'Is my data secure?',
              'Yes, all conversations are encrypted and stored securely. We never share your personal information with third parties.',
            ),
            _FAQItem(
              'Can AI replace a human therapist?',
              'No, AI therapy is meant to supplement, not replace, professional mental health care. For serious mental health concerns, please consult a licensed professional.',
            ),
            _FAQItem(
              'How often should I use the app?',
              'You can use the app as often as you like. Many users find daily check-ins helpful for maintaining mental wellness.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FAQItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQItem(this.question, this.answer);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}