# MindCare AI - Psychology Therapy App

## 🧠 Overview

MindCare AI is a comprehensive mobile application that provides AI-powered psychology therapy sessions. The app features an AI psychologist named "Dr. Sarah" who conducts therapy sessions using evidence-based techniques like Cognitive Behavioral Therapy (CBT).

## ✨ Features

### 🔐 Authentication & User Management
- **Firebase Authentication** with email/password
- **User Registration** with personal information
- **Password Reset** functionality
- **User Profile Management**

### 🤖 AI Psychology Sessions
- **AI Therapist (Dr. Sarah)** powered by OpenAI GPT-4
- **Personalized therapy sessions** using CBT techniques
- **Mood analysis** and sentiment tracking
- **Session history** and progress tracking
- **Coping strategies** based on user's emotional state

### 📅 Appointment System
- **Schedule therapy sessions** at convenient times
- **Session reminders** and notifications
- **Appointment management** (reschedule, cancel)
- **Calendar integration**

### 📊 Progress Tracking
- **Session statistics** and analytics
- **Mood trends** over time
- **Completion rates** and streaks
- **Personal insights** and recommendations

### 🎨 Beautiful UI/UX
- **Modern Material Design** with custom theming
- **Smooth animations** using Animate Do
- **Dark/Light mode** support
- **Responsive design** for all screen sizes
- **Accessibility features**

## 🛠 Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile development
- **Dart** - Programming language
- **Riverpod** - State management
- **Google Fonts** - Typography
- **Animate Do** - Animations
- **Lottie** - Advanced animations

### Backend & Services
- **Firebase Auth** - Authentication
- **Cloud Firestore** - Database
- **Firebase Storage** - File storage
- **OpenAI GPT-4** - AI psychology responses

### Local Storage
- **Hive** - Local database
- **Shared Preferences** - App settings

### Additional Features
- **Speech to Text** - Voice input (future feature)
- **Text to Speech** - Voice responses (future feature)
- **Local Notifications** - Reminders and alerts
- **Calendar Integration** - Appointment scheduling

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.5.4 or later)
- Dart SDK
- Android Studio / Xcode
- Firebase project
- OpenAI API key

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd psychology_ai_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Enable Authentication (Email/Password)
   - Enable Cloud Firestore
   - Enable Storage
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories:
     - Android: `android/app/google-services.json`
     - iOS: `ios/Runner/GoogleService-Info.plist`

4. **OpenAI API Setup**
   - Get an API key from [OpenAI](https://platform.openai.com/api-keys)
   - Replace `YOUR_OPENAI_API_KEY` in `lib/core/constants/app_constants.dart`
   ```dart
   static const String openAIApiKey = 'your-actual-api-key-here';
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📱 App Structure

```
lib/
├── core/
│   ├── constants/          # App constants and configuration
│   ├── theme/             # App theming and styles
│   ├── utils/             # Utility functions
│   └── services/          # Core services (AI, notifications)
├── features/
│   ├── auth/              # Authentication screens
│   ├── dashboard/         # Main dashboard
│   ├── appointments/      # Appointment management
│   ├── chat/              # AI chat interface
│   ├── profile/           # User profile
│   └── onboarding/        # App introduction
└── shared/
    ├── widgets/           # Reusable UI components
    ├── models/            # Data models
    └── providers/         # State management
```

## 🤖 AI Psychology Features

### Dr. Sarah - AI Psychologist
The app features an AI psychologist named Dr. Sarah who:
- Uses evidence-based therapeutic techniques
- Provides empathetic and professional responses
- Analyzes user mood and emotional state
- Offers personalized coping strategies
- Maintains appropriate therapeutic boundaries

### Therapy Techniques Implemented
- **Cognitive Behavioral Therapy (CBT)**
- **Mindfulness and meditation guidance**
- **Breathing exercises**
- **Progressive muscle relaxation**
- **Thought challenging and reframing**

### Safety Features
- Crisis detection and emergency contact recommendations
- Professional boundaries maintenance
- Privacy and confidentiality assurance
- Referral to human professionals when needed

## 📊 Data Models

### User Model
```dart
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final DateTime dateOfBirth;
  final UserPreferences preferences;
  final SessionStats sessionStats;
  // ... more fields
}
```

### Session Stats
```dart
class SessionStats {
  final int totalSessions;
  final int completedSessions;
  final double averageSessionRating;
  final Duration totalSessionTime;
  final int currentStreak;
  final Map<String, int> moodTrends;
  // ... more fields
}
```

## 🔒 Privacy & Security

- **End-to-end encryption** for sensitive data
- **HIPAA-compliant** data handling practices
- **Local data storage** for offline functionality
- **Secure authentication** with Firebase
- **Privacy-first design** with user consent

## 🎯 Future Enhancements

### Planned Features
- **Voice therapy sessions** with speech recognition
- **Group therapy rooms** for peer support
- **Therapist matching** with human professionals
- **Medication reminders** and tracking
- **Crisis intervention** features
- **Family/caregiver involvement** options
- **Integration with wearables** for mood tracking
- **Multilingual support**

### Technical Improvements
- **Offline mode** with data synchronization
- **Advanced AI models** for better responses
- **Machine learning** for personalized recommendations
- **Real-time chat** with typing indicators
- **Video call integration** for human therapists

## 🧪 Testing

### Running Tests
```bash
# Unit tests
flutter test

# Integration tests
flutter test integration_test/

# Widget tests
flutter test test/widget_test/
```

### Test Coverage
- Authentication flows
- AI service responses
- User data management
- UI component functionality

## 📱 Platform Support

- ✅ **Android** (API level 21+)
- ✅ **iOS** (iOS 12.0+)
- 🔄 **Web** (in development)
- 🔄 **Desktop** (future consideration)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style
- Follow [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚠️ Disclaimer

**Important Medical Disclaimer:**

This app is designed to provide supportive mental health resources and is not a substitute for professional medical advice, diagnosis, or treatment. The AI responses are generated based on general therapeutic principles but should not be considered as professional psychological or psychiatric advice.

**Please note:**
- Always seek the advice of qualified mental health professionals
- In case of emergency or suicidal thoughts, contact emergency services immediately
- This app is intended for educational and supportive purposes only
- Individual results may vary, and the app should complement, not replace, professional care

## 📞 Support

For support, email support@mindcareai.com or create an issue in this repository.

## 🙏 Acknowledgments

- OpenAI for providing the GPT-4 API
- Firebase team for the excellent backend services
- Flutter team for the amazing framework
- Mental health professionals who provided guidance on therapeutic techniques
- Beta testers and early users for valuable feedback

---

**Made with ❤️ for better mental health accessibility**