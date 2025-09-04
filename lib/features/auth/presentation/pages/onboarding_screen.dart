import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/pages/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.psychology_outlined,
      title: 'AI-Powered Therapy',
      description: 'Connect with Dr. Sarah, your AI psychologist, for personalized therapy sessions using evidence-based techniques.',
      color: AppTheme.primaryColor,
    ),
    OnboardingPage(
      icon: Icons.calendar_today_outlined,
      title: 'Schedule Sessions',
      description: 'Book therapy sessions at your convenience. Set reminders and build a consistent therapy routine.',
      color: AppTheme.secondaryColor,
    ),
    OnboardingPage(
      icon: Icons.trending_up_outlined,
      title: 'Track Progress',
      description: 'Monitor your mental health journey with detailed insights, mood tracking, and session analytics.',
      color: AppTheme.accentColor,
    ),
    OnboardingPage(
      icon: Icons.security_outlined,
      title: 'Safe & Private',
      description: 'Your conversations are completely confidential and secure. Focus on healing in a judgment-free space.',
      color: AppTheme.successColor,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _navigateToLogin(),
                    child: Text(
                      'Skip',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], index);
                },
              ),
            ),

            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingLarge),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => _buildIndicator(index),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Row(
                children: [
                  // Previous button
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: AppConstants.animationDurationMedium,
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Previous'),
                      ),
                    ),
                  
                  if (_currentPage > 0) const SizedBox(width: AppConstants.paddingMedium),
                  
                  // Next/Get Started button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          _navigateToLogin();
                        } else {
                          _pageController.nextPage(
                            duration: AppConstants.animationDurationMedium,
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          FadeInDown(
            duration: AppConstants.animationDurationSlow,
            delay: Duration(milliseconds: 200 * index),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: page.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: page.color.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                page.icon,
                size: 60,
                color: page.color,
              ),
            ),
          ),

          const SizedBox(height: AppConstants.paddingXLarge),

          // Title
          FadeInUp(
            duration: AppConstants.animationDurationSlow,
            delay: Duration(milliseconds: 400 + (200 * index)),
            child: Text(
              page.title,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: AppConstants.paddingMedium),

          // Description
          FadeInUp(
            duration: AppConstants.animationDurationSlow,
            delay: Duration(milliseconds: 600 + (200 * index)),
            child: Text(
              page.description,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(int index) {
    return AnimatedContainer(
      duration: AppConstants.animationDurationMedium,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index 
            ? AppTheme.primaryColor 
            : AppTheme.primaryColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}