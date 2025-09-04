import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'shared/services/ad_service.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'features/onboarding/presentation/pages/splash_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/dashboard/presentation/pages/dashboard_screen.dart';
import 'screens/profile_image_edit_screen.dart';
import 'shared/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
        apiKey: "AIzaSyC-p2AkAPQAPB1ITzeKolE9H6siwkUnWo4",
        authDomain: "protfolio-daeb8.firebaseapp.com",
        projectId: "protfolio-daeb8",
        storageBucket: "protfolio-daeb8.appspot.com",
        messagingSenderId: "148615898630",
        appId: "1:148615898630:web:1e50e48826290f5670c587",
        measurementId: "G-J6GL5Q44C9"),
  );
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Initialize Mobile Ads SDK
  await AdService.initialize();
  
  runApp(const ProviderScope(child: PsychologyAIApp()));
}

class PsychologyAIApp extends ConsumerWidget {
  const PsychologyAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/profile-image-edit': (context) => const ProfileImageEditScreen(),
      },
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          return const DashboardScreen();
        } else {
          return const SplashScreen();
        }
      },
      loading: () => const SplashScreen(),
      error: (error, stack) => const LoginScreen(),
    );
  }
}