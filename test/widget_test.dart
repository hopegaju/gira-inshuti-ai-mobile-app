import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gira_inshuti/main.dart';
import 'package:gira_inshuti/services/auth_service.dart';

void main() {
  testWidgets('App loads splash screen correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the splash screen loads with the app title
    expect(find.text('Gira Inshuti'), findsOneWidget);
    expect(find.text('Connecting Hearts, Building Communities'), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
  });

  testWidgets('Navigation to login screen works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Wait for splash screen animation and navigation
    await tester.pumpAndSettle(Duration(seconds: 4));

    // Verify we're now on the login screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue to Gira Inshuti'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    // Build our app and navigate to login
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle(Duration(seconds: 4));

    // Try to login without entering credentials
    await tester.tap(find.text('Sign In'));
    await tester.pump();

    // Check for validation messages
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Navigate to register screen', (WidgetTester tester) async {
    // Build our app and navigate to login
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle(Duration(seconds: 4));

    // Tap on Sign Up link
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify we're on the register screen
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Join the Gira Inshuti community'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
  });

  testWidgets('Admin login test', (WidgetTester tester) async {
    // Build our app and navigate to login
    await tester.pumpWidget(MyApp());
    await tester.pumpAndSettle(Duration(seconds: 4));

    // Enter admin credentials
    await tester.enterText(find.byType(TextFormField).first, 'admin@girainshuti.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'admin123');
    
    // Tap login button
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Should navigate to admin dashboard
    expect(find.text('Admin Dashboard'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
  });

  testWidgets('AuthService initialization test', (WidgetTester tester) async {
    final authService = AuthService();
    
    expect(authService.isLoggedIn, false);
    expect(authService.currentUser, null);
    expect(authService.isLoading, false);
    
    // Test that default users are initialized
    final users = authService.getAllUsers();
    expect(users.length, 0); // Should be empty for non-admin user
  });

  group('AuthService Login Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    testWidgets('Admin login success', (WidgetTester tester) async {
      final result = await authService.login('admin@girainshuti.com', 'admin123');
      
      expect(result, true);
      expect(authService.isLoggedIn, true);
      expect(authService.currentUser?.email, 'admin@girainshuti.com');
    });

    testWidgets('Invalid login fails', (WidgetTester tester) async {
      final result = await authService.login('invalid@email.com', 'wrongpassword');
      
      expect(result, false);
      expect(authService.isLoggedIn, false);
      expect(authService.currentUser, null);
    });

    testWidgets('Counselor login success', (WidgetTester tester) async {
      final result = await authService.login('counselor@girainshuti.com', 'counselor123');
      
      expect(result, true);
      expect(authService.isLoggedIn, true);
      expect(authService.currentUser?.email, 'counselor@girainshuti.com');
    });
  });
}