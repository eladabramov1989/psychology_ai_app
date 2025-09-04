import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychology_ai_app/shared/providers/data_providers.dart';
import 'package:psychology_ai_app/shared/models/appointment_model.dart';
import 'package:psychology_ai_app/features/appointments/presentation/pages/appointments_screen.dart';

void main() {
  group('Appointments Integration Tests', () {
    testWidgets('AppointmentsScreen displays loading state initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AppointmentsScreen(),
          ),
        ),
      );

      // Should show loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AppointmentsScreen displays empty state when no appointments', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAppointmentsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            home: AppointmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No Appointments Yet'), findsOneWidget);
      expect(find.text('Schedule your first session with Dr. Sarah'), findsOneWidget);
    });

    testWidgets('AppointmentsScreen displays appointments list', (WidgetTester tester) async {
      final testAppointments = [
        AppointmentModel(
          id: '1',
          userId: 'user1',
          title: 'Test Session',
          scheduledDateTime: DateTime.now().add(Duration(days: 1)),
          type: AppointmentType.videoCall,
          status: AppointmentStatus.scheduled,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAppointmentsProvider.overrideWith((ref) => Stream.value(testAppointments)),
          ],
          child: MaterialApp(
            home: AppointmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show appointment card
      expect(find.text('Test Session'), findsOneWidget);
      expect(find.text('Video Call'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
    });

    testWidgets('AppointmentsScreen handles error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAppointmentsProvider.overrideWith((ref) => Stream.error('Test error')),
          ],
          child: MaterialApp(
            home: AppointmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show error state
      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Schedule dialog opens when FAB is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userAppointmentsProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            home: AppointmentsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the floating action button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should show schedule dialog
      expect(find.text('Schedule Session'), findsOneWidget);
      expect(find.text('Video Session'), findsOneWidget);
      expect(find.text('Chat Session'), findsOneWidget);
    });
  });

  group('Data Providers Tests', () {
    test('Service providers are properly configured', () {
      final container = ProviderContainer();
      
      // Test that service providers can be created
      expect(() => container.read(appointmentServiceProvider), returnsNormally);
      expect(() => container.read(sessionServiceProvider), returnsNormally);
      expect(() => container.read(messageServiceProvider), returnsNormally);
      
      container.dispose();
    });

    test('State providers have correct initial values', () {
      final container = ProviderContainer();
      
      // Test initial states
      expect(container.read(appointmentLoadingProvider), false);
      expect(container.read(sessionLoadingProvider), false);
      expect(container.read(messageLoadingProvider), false);
      expect(container.read(currentSessionProvider), null);
      
      container.dispose();
    });
  });
}