import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // App Info
  static const String appName = 'MindCare AI';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'AI-powered psychology therapy sessions';

  // API Configuration
  static const String aiEndpoint =
      'https://api.together.xyz/v1/chat/completions'; // Together.ai API endpoint
  static final String? aiApiKey = dotenv.env['apikey']; // Together.ai API key
  static const String aiModel =
      'NousResearch/Nous-Hermes-2-Mixtral-8x7B-DPO'; // Together.ai serverless model
  // Session Configuration
  static const int sessionDurationMinutes = 60;
  static const int maxSessionsPerDay = 3;
  static const int sessionReminderMinutes = 15;

  // AI Psychologist Configuration
  static const String aiPsychologistName = 'Dr. Sarah';
  static const String aiPsychologistSpecialty = 'Cognitive Behavioral Therapy';
  static const String systemPrompt = '''
You are Dr. Sarah, a licensed clinical psychologist specializing in Cognitive Behavioral Therapy (CBT).
You are conducting a therapy session with a client. Your approach should be:

1. Empathetic and non-judgmental
2. Professional yet warm
3. Use evidence-based therapeutic techniques
4. Ask thoughtful, open-ended questions
5. Provide insights and coping strategies
6. Maintain appropriate boundaries
7. If the client expresses suicidal thoughts or immediate danger, recommend they contact emergency services

Remember:
- This is a therapy session, not casual conversation
- Focus on the client's mental health and wellbeing
- Use therapeutic techniques like cognitive restructuring, mindfulness, and behavioral interventions
- Keep responses concise but meaningful
- Always prioritize the client's safety and wellbeing

Begin each session by asking how the client is feeling today and what they'd like to focus on.
''';

  // Colors
  static const String primaryColorHex = '#6B73FF';
  static const String secondaryColorHex = '#9B59B6';
  static const String accentColorHex = '#FF6B9D';
  static const String backgroundColorHex = '#F8F9FE';
  static const String surfaceColorHex = '#FFFFFF';

  // Spacing
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;

  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);

  // Database Collections
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';
  static const String appointmentsCollection = 'appointments';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';

  // Storage Keys
  static const String userPrefsKey = 'user_preferences';
  static const String sessionDataKey = 'session_data';
  static const String appointmentsKey = 'appointments_cache';

  // Notification Channels
  static const String appointmentChannelId = 'appointment_reminders';
  static const String sessionChannelId = 'session_notifications';
  static const String generalChannelId = 'general_notifications';
}
