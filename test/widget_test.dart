import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:gira_inshuti/main.dart';
import 'package:gira_inshuti/services/auth_service.dart';
import 'package:gira_inshuti/screens/login_screen.dart';
import 'package:gira_inshuti/screens/register_screen.dart';

void main() {
  // Helper function to wrap widgets with Provider for testing
  Widget createWidgetUnderTest(Widget child) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('App loads splash screen correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that the splash screen loads with the app title
    expect(find.text('Gira Inshuti'), findsOneWidget);
    expect(find.text('Connecting Hearts, Building Communities'), findsOneWidget);
    expect(find.byIcon(Icons.people), findsOneWidget);
    
    // Wait for all timers to complete to avoid test errors
    await tester.pumpAndSettle(Duration(seconds: 5));
  });

  testWidgets('Navigation to login screen works', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Wait for splash screen animation and navigation
    await tester.pumpAndSettle(Duration(seconds: 5));

    // Verify we're now on the login screen
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue to Gira Inshuti'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Login form validation works', (WidgetTester tester) async {
    // Test login screen in isolation with Provider
    await tester.pumpWidget(createWidgetUnderTest(LoginScreen()));

    // Find the Sign In button specifically (not the Sign Up text button)
    final signInButton = find.widgetWithText(ElevatedButton, 'Sign In');
    expect(signInButton, findsOneWidget);

    // Try to login without entering credentials
    await tester.tap(signInButton);
    await tester.pump();

    // Check for validation messages
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    // Test login screen in isolation
    await tester.pumpWidget(createWidgetUnderTest(LoginScreen()));

    // Verify login screen elements
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Sign in to continue to Gira Inshuti'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);
  });

  testWidgets('Register screen displays correctly', (WidgetTester tester) async {
    // Test register screen in isolation
    await tester.pumpWidget(createWidgetUnderTest(RegisterScreen()));

    // Verify register screen elements
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Join the Gira Inshuti community'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Create Account'), findsAtLeastNWidgets(1)); // Button text
  });

  testWidgets('Register form validation works', (WidgetTester tester) async {
    // Test register screen validation
    await tester.pumpWidget(createWidgetUnderTest(RegisterScreen()));

    // Find and tap the Create Account button
    final createButton = find.widgetWithText(ElevatedButton, 'Create Account');
    expect(createButton, findsOneWidget);
    
    await tester.tap(createButton);
    await tester.pump();

    // Check for validation messages
    expect(find.text('Please enter your full name'), findsOneWidget);
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter a password'), findsOneWidget);
    expect(find.text('Please confirm your password'), findsOneWidget);
  });

  testWidgets('Password mismatch validation works', (WidgetTester tester) async {
    // Test register screen password mismatch
    await tester.pumpWidget(createWidgetUnderTest(RegisterScreen()));

    // Enter mismatched passwords
    final nameField = find.widgetWithText(TextFormField, 'Full Name');
    final emailField = find.widgetWithText(TextFormField, 'Email');
    final passwordFields = find.byType(TextFormField);
    
    await tester.enterText(nameField, 'Test User');
    await tester.enterText(emailField, 'test@example.com');
    await tester.enterText(passwordFields.at(2), 'password123'); // Password field
    await tester.enterText(passwordFields.at(3), 'different123'); // Confirm password field
    
    // Tap create account button
    final createButton = find.widgetWithText(ElevatedButton, 'Create Account');
    await tester.tap(createButton);
    await tester.pump();

    // Check for password mismatch validation
    expect(find.text('Passwords do not match'), findsOneWidget);
  });

  testWidgets('Full app navigation flow', (WidgetTester tester) async {
    // Test complete app flow
    await tester.pumpWidget(MyApp());
    
    // Wait for splash to complete
    await tester.pumpAndSettle(Duration(seconds: 5));
    
    // Should be on login screen
    expect(find.text('Welcome Back'), findsOneWidget);
    
    // Navigate to register screen
    final signUpButton = find.widgetWithText(TextButton, 'Sign Up');
    await tester.tap(signUpButton);
    await tester.pumpAndSettle();
    
    // Should be on register screen
    expect(find.text('Create Account'), findsOneWidget);
    
    // Go back to login screen
    await tester.pageBack();
    await tester.pumpAndSettle();
    
    // Should be back on login screen
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  group('AuthService Tests', () {
    test('AuthService initialization', () {
      final authService = AuthService();
      
      expect(authService.isLoggedIn, false);
      expect(authService.currentUser, null);
      expect(authService.isLoading, false);
    });

    test('Admin login success', () async {
      final authService = AuthService();
      final result = await authService.login('admin@girainshuti.com', 'admin123');
      
      expect(result, true);
      expect(authService.isLoggedIn, true);
      expect(authService.currentUser?.email, 'admin@girainshuti.com');
    });

    test('Invalid login fails', () async {
      final authService = AuthService();
      final result = await authService.login('invalid@email.com', 'wrongpassword');
      
      expect(result, false);
      expect(authService.isLoggedIn, false);
      expect(authService.currentUser, null);
    });

    test('Counselor login success', () async {
      final authService = AuthService();
      final result = await authService.login('counselor@girainshuti.com', 'counselor123');
      
      expect(result, true);
      expect(authService.isLoggedIn, true);
      expect(authService.currentUser?.email, 'counselor@girainshuti.com');
    });

    test('User registration success', () async {
      final authService = AuthService();
      final result = await authService.register('user@test.com', 'password123', 'Test User');
      
      expect(result, true);
      expect(authService.isLoggedIn, true);
      expect(authService.currentUser?.email, 'user@test.com');
      expect(authService.currentUser?.name, 'Test User');
    });

    test('Duplicate email registration fails', () async {
      final authService = AuthService();
      
      // First registration should succeed
      final firstResult = await authService.register('user@test.com', 'password123', 'Test User');
      expect(firstResult, true);
      
      // Logout to test duplicate registration
      authService.logout();
      
      // Second registration with same email should fail
      final secondResult = await authService.register('user@test.com', 'password456', 'Another User');
      expect(secondResult, false);
    });

    test('Admin can create counselors', () async {
      final authService = AuthService();
      
      // Login as admin
      await authService.login('admin@girainshuti.com', 'admin123');
      
      // Create counselor
      final result = await authService.createCounselor('newcounselor@test.com', 'New Counselor', 'password');
      expect(result, true);
      
      // Verify counselor was added
      final users = authService.getAllUsers();
      final newCounselor = users.where((u) => u.email == 'newcounselor@test.com').firstOrNull;
      expect(newCounselor, isNotNull);
      expect(newCounselor?.name, 'New Counselor');
    });

    test('Non-admin cannot create counselors', () async {
      final authService = AuthService();
      
      // Register as regular user
      await authService.register('user@test.com', 'password123', 'Regular User');
      
      // Try to create counselor (should fail)
      final result = await authService.createCounselor('counselor@test.com', 'Test Counselor', 'password');
      expect(result, false);
    });

    test('Logout works correctly', () async {
      final authService = AuthService();
      
      // Login first
      await authService.login('admin@girainshuti.com', 'admin123');
      expect(authService.isLoggedIn, true);
      
      // Logout
      authService.logout();
      expect(authService.isLoggedIn, false);
      expect(authService.currentUser, null);
    });
  });
}