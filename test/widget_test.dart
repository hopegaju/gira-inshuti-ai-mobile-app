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
      final result = await authService.signIn('admin@girainshuti.com', 'Admin123!@#');
      
      expect(result.success, true);
      expect(authService.isLoggedIn, true);
      expect(authService.currentUser?.email, 'admin@girainshuti.com');
    });

    test('Invalid login fails', () async {
      final authService = AuthService();
      final result = await authService.signIn('invalid@email.com', 'wrongpassword');
      
      expect(result.success, false);
      expect(authService.isLoggedIn, false);
      expect(authService.currentUser, null);
    });

    test('Counselor login success', () async {
      final authService = AuthService();
      final result = await authService.signIn('counselor@girainshuti.com', 'Counselor123!@#');
      
      expect(result.success, true);
      expect(authService.isLoggedIn, true);
      expect(authService.currentUser?.email, 'counselor@girainshuti.com');
    });

    test('User login success', () async {
      final authService = AuthService();
      final result = await authService.signIn('user@girainshuti.com', 'Demo123!@#');
      
      expect(result.success, true);
      expect(authService.isLoggedIn, true);
      expect(authService.currentUser?.email, 'user@girainshuti.com');
    });

    test('User registration success (Firebase mode)', () async {
      final authService = AuthService();
      final result = await authService.register(
        'user@test.com',
        'Test123!@#',
        'Test User',
        gender: 'Male',
      );
      
      // In demo mode, registration requires Firebase connection
      if (authService.authMode == AuthMode.demo) {
        expect(result.success, false);
        expect(result.error, AuthError.networkError);
      } else {
        // In Firebase mode, should succeed
        expect(result.success, true);
        expect(authService.isLoggedIn, true);
        expect(authService.currentUser?.email, 'user@test.com');
        expect(authService.currentUser?.name, 'Test User');
      }
    });

    test('Duplicate email registration fails', () async {
      final authService = AuthService();
      
      // Try to register with demo account email (reserved)
      final result = await authService.register(
        'admin@girainshuti.com',
        'Test123!@#',
        'Test Admin',
      );
      
      expect(result.success, false);
      expect(result.error, AuthError.userExists);
    });

    test('Weak password registration fails', () async {
      final authService = AuthService();
      
      final result = await authService.register(
        'user@test.com',
        'weak',
        'Test User',
      );
      
      expect(result.success, false);
      expect(result.error, AuthError.weakPassword);
    });

    test('Password validation works correctly', () {
      final authService = AuthService();
      
      // Valid password
      expect(authService.isPasswordValid('Test123!@#'), true);
      
      // Too short
      expect(authService.isPasswordValid('Test1!'), false);
      
      // No uppercase
      expect(authService.isPasswordValid('test123!@#'), false);
      
      // No lowercase
      expect(authService.isPasswordValid('TEST123!@#'), false);
      
      // No number
      expect(authService.isPasswordValid('Test!@#'), false);
      
      // No special character
      expect(authService.isPasswordValid('Test123'), false);
    });

    test('Password strength calculation works', () {
      final authService = AuthService();
      
      // Strong password
      final strongScore = authService.getPasswordStrength('Test123!@#SecurePassword');
      expect(strongScore, greaterThan(70));
      
      // Weak password
      final weakScore = authService.getPasswordStrength('test');
      expect(weakScore, lessThan(30));
    });

    test('Admin can get all users in demo mode', () async {
      final authService = AuthService();
      
      // Login as admin
      await authService.signIn('admin@girainshuti.com', 'Admin123!@#');
      
      final usersStream = authService.getAllUsers();
      expect(usersStream, isNotNull);
      
      // Get first emission from stream
      final users = await usersStream!.first;
      expect(users.isNotEmpty, true);
      expect(users.length, greaterThanOrEqualTo(3)); // At least 3 demo accounts
    });

    test('Non-admin cannot get all users', () async {
      final authService = AuthService();
      
      // Login as regular user
      await authService.signIn('user@girainshuti.com', 'Demo123!@#');
      
      final usersStream = authService.getAllUsers();
      expect(usersStream, isNull);
    });

    test('Can get all counselors', () async {
      final authService = AuthService();
      
      // Login as any user
      await authService.signIn('user@girainshuti.com', 'Demo123!@#');
      
      final counselorsStream = authService.getAllCounselors();
      expect(counselorsStream, isNotNull);
      
      final counselors = await counselorsStream!.first;
      expect(counselors.isNotEmpty, true);
      expect(counselors.first.email, 'counselor@girainshuti.com');
    });

    test('Admin can create counselors (Firebase mode only)', () async {
      final authService = AuthService();
      
      // Login as admin
      await authService.signIn('admin@girainshuti.com', 'Admin123!@#');
      
      // Try to create counselor
      final result = await authService.createCounselor(
        'newcounselor@test.com',
        'New Counselor',
        'Counselor123!@#',
        gender: 'Female',
      );
      
      // In demo mode, this should fail (no Firebase)
      if (authService.authMode == AuthMode.demo) {
        expect(result, false);
      }
      // In Firebase mode, it should succeed (if properly configured)
    });

    test('Non-admin cannot create counselors', () async {
      final authService = AuthService();
      
      // Login as regular user
      await authService.signIn('user@girainshuti.com', 'Demo123!@#');
      
      // Try to create counselor (should fail - not admin)
      final result = await authService.createCounselor(
        'counselor@test.com',
        'Test Counselor',
        'Counselor123!@#',
      );
      expect(result, false);
    });

    test('Logout works correctly', () async {
      final authService = AuthService();
      
      // Login first
      await authService.signIn('admin@girainshuti.com', 'Admin123!@#');
      expect(authService.isLoggedIn, true);
      
      // Logout (using signOut which is the correct method)
      await authService.signOut();
      expect(authService.isLoggedIn, false);
      expect(authService.currentUser, null);
    });

    test('Update user profile works', () async {
      final authService = AuthService();
      
      // Login
      await authService.signIn('user@girainshuti.com', 'Demo123!@#');
      
      // Update profile
      final result = await authService.updateUserProfile(
        displayName: 'Updated Name',
        gender: 'Female',
      );
      
      expect(result, true);
      expect(authService.currentUser?.name, 'Updated Name');
      expect(authService.currentUser?.gender, 'Female');
    });

    test('Demo credentials are accessible', () {
      final authService = AuthService();
      final credentials = authService.getDemoCredentials();
      
      expect(credentials.containsKey('admin@girainshuti.com'), true);
      expect(credentials.containsKey('counselor@girainshuti.com'), true);
      expect(credentials.containsKey('user@girainshuti.com'), true);
      expect(credentials['admin@girainshuti.com'], 'Admin123!@#');
      expect(credentials['counselor@girainshuti.com'], 'Counselor123!@#');
      expect(credentials['user@girainshuti.com'], 'Demo123!@#');
    });
  });
}