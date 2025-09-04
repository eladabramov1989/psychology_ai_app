import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isActive;
  final UserPreferences preferences;
  final SessionStats sessionStats;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.dateOfBirth,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.lastLoginAt,
    required this.isActive,
    required this.preferences,
    required this.sessionStats,
  });

  String get fullName => '$firstName $lastName';
  
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month || 
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      phoneNumber: data['phoneNumber'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      preferences: UserPreferences.fromMap(data['preferences'] ?? {}),
      sessionStats: SessionStats.fromMap(data['sessionStats'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isActive': isActive,
      'preferences': preferences.toMap(),
      'sessionStats': sessionStats.toMap(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    UserPreferences? preferences,
    SessionStats? sessionStats,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      preferences: preferences ?? this.preferences,
      sessionStats: sessionStats ?? this.sessionStats,
    );
  }
}

class UserPreferences {
  final bool notificationsEnabled;
  final bool reminderNotifications;
  final int reminderMinutesBefore;
  final String preferredSessionTime; // morning, afternoon, evening
  final bool darkModeEnabled;
  final String language;
  final bool voiceEnabled;
  final double voiceSpeed;

  UserPreferences({
    this.notificationsEnabled = true,
    this.reminderNotifications = true,
    this.reminderMinutesBefore = 15,
    this.preferredSessionTime = 'afternoon',
    this.darkModeEnabled = false,
    this.language = 'en',
    this.voiceEnabled = false,
    this.voiceSpeed = 1.0,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      reminderNotifications: map['reminderNotifications'] ?? true,
      reminderMinutesBefore: map['reminderMinutesBefore'] ?? 15,
      preferredSessionTime: map['preferredSessionTime'] ?? 'afternoon',
      darkModeEnabled: map['darkModeEnabled'] ?? false,
      language: map['language'] ?? 'en',
      voiceEnabled: map['voiceEnabled'] ?? false,
      voiceSpeed: map['voiceSpeed']?.toDouble() ?? 1.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'reminderNotifications': reminderNotifications,
      'reminderMinutesBefore': reminderMinutesBefore,
      'preferredSessionTime': preferredSessionTime,
      'darkModeEnabled': darkModeEnabled,
      'language': language,
      'voiceEnabled': voiceEnabled,
      'voiceSpeed': voiceSpeed,
    };
  }

  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? reminderNotifications,
    int? reminderMinutesBefore,
    String? preferredSessionTime,
    bool? darkModeEnabled,
    String? language,
    bool? voiceEnabled,
    double? voiceSpeed,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderNotifications: reminderNotifications ?? this.reminderNotifications,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      preferredSessionTime: preferredSessionTime ?? this.preferredSessionTime,
      darkModeEnabled: darkModeEnabled ?? this.darkModeEnabled,
      language: language ?? this.language,
      voiceEnabled: voiceEnabled ?? this.voiceEnabled,
      voiceSpeed: voiceSpeed ?? this.voiceSpeed,
    );
  }
}

class SessionStats {
  final int totalSessions;
  final int completedSessions;
  final int cancelledSessions;
  final double averageSessionRating;
  final Duration totalSessionTime;
  final DateTime? lastSessionDate;
  final int currentStreak;
  final int longestStreak;
  final Map<String, int> moodTrends; // mood -> count
  final List<String> focusAreas; // areas of focus in therapy

  SessionStats({
    this.totalSessions = 0,
    this.completedSessions = 0,
    this.cancelledSessions = 0,
    this.averageSessionRating = 0.0,
    this.totalSessionTime = Duration.zero,
    this.lastSessionDate,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.moodTrends = const {},
    this.focusAreas = const [],
  });

  factory SessionStats.fromMap(Map<String, dynamic> map) {
    return SessionStats(
      totalSessions: map['totalSessions'] ?? 0,
      completedSessions: map['completedSessions'] ?? 0,
      cancelledSessions: map['cancelledSessions'] ?? 0,
      averageSessionRating: map['averageSessionRating']?.toDouble() ?? 0.0,
      totalSessionTime: Duration(minutes: map['totalSessionTimeMinutes'] ?? 0),
      lastSessionDate: map['lastSessionDate'] != null 
          ? (map['lastSessionDate'] as Timestamp).toDate() 
          : null,
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      moodTrends: Map<String, int>.from(map['moodTrends'] ?? {}),
      focusAreas: List<String>.from(map['focusAreas'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'cancelledSessions': cancelledSessions,
      'averageSessionRating': averageSessionRating,
      'totalSessionTimeMinutes': totalSessionTime.inMinutes,
      'lastSessionDate': lastSessionDate != null 
          ? Timestamp.fromDate(lastSessionDate!) 
          : null,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'moodTrends': moodTrends,
      'focusAreas': focusAreas,
    };
  }

  double get completionRate {
    if (totalSessions == 0) return 0.0;
    return completedSessions / totalSessions;
  }

  SessionStats copyWith({
    int? totalSessions,
    int? completedSessions,
    int? cancelledSessions,
    double? averageSessionRating,
    Duration? totalSessionTime,
    DateTime? lastSessionDate,
    int? currentStreak,
    int? longestStreak,
    Map<String, int>? moodTrends,
    List<String>? focusAreas,
  }) {
    return SessionStats(
      totalSessions: totalSessions ?? this.totalSessions,
      completedSessions: completedSessions ?? this.completedSessions,
      cancelledSessions: cancelledSessions ?? this.cancelledSessions,
      averageSessionRating: averageSessionRating ?? this.averageSessionRating,
      totalSessionTime: totalSessionTime ?? this.totalSessionTime,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      moodTrends: moodTrends ?? this.moodTrends,
      focusAreas: focusAreas ?? this.focusAreas,
    );
  }
}