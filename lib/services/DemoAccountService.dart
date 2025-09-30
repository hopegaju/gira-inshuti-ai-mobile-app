// services/demo_account_service.dart
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class DemoAccountService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Demo account credentials
  static const Map<String, Map<String, dynamic>> demoAccounts = {
    'admin': {
      'email': 'admin@girainshuti.com',
      'password': 'Admin123!@#',
      'name': 'System Administrator',
      'role': 'admin',
      'gender': 'Prefer not to say',
    },
    'counselor': {
      'email': 'counselor@girainshuti.com',
      'password': 'Counselor123!@#',
      'name': 'Dr. Sarah Johnson',
      'role': 'counselor',
      'gender': 'Female',
    },
    'counselor2': {
      'email': 'counselor2@girainshuti.com',
      'password': 'Counselor123!@#',
      'name': 'Dr. Michael Chen',
      'role': 'counselor',
      'gender': 'Male',
    },
    'user': {
      'email': 'demo@girainshuti.com',
      'password': 'Demo123!@#',
      'name': 'Demo User',
      'role': 'user',
      'gender': 'Non-binary',
    },
  };

  // Setup demo accounts (only call this once or check if accounts exist)
  static Future<void> setupDemoAccounts() async {
    if (!kDebugMode) {
      debugPrint('Demo accounts can only be created in debug mode');
      return;
    }

    try {
      for (final account in demoAccounts.entries) {
        await _createDemoAccount(account.value);
      }
      debugPrint('Demo accounts setup completed');
    } catch (e) {
      debugPrint('Error setting up demo accounts: $e');
    }
  }

  static Future<void> _createDemoAccount(Map<String, dynamic> accountData) async {
    try {
      // Check if user already exists in Firestore
      final QuerySnapshot existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: accountData['email'])
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        debugPrint('Account ${accountData['email']} already exists');
        return;
      }


// Create a temporary Firebase app instance to avoid signing out current user
firebase_core.FirebaseApp tempApp = await firebase_core.Firebase.initializeApp(
  name: 'tempApp_${DateTime.now().millisecondsSinceEpoch}',
  options: firebase_core.Firebase.app().options,
);

firebase_auth.FirebaseAuth tempAuth = firebase_auth.FirebaseAuth.instanceFor(app: tempApp);

try {
  // Try to create user account
  final credential = await tempAuth.createUserWithEmailAndPassword(
    email: accountData['email'],
    password: accountData['password'],
  );

  if (credential.user != null) {
    // Update display name
    await credential.user!.updateDisplayName(accountData['name']);

    // Create user document in Firestore
    await _firestore.collection('users').doc(credential.user!.uid).set({
      'email': accountData['email'],
      'name': accountData['name'],
      'role': accountData['role'],
      'gender': accountData['gender'],
      'createdAt': Timestamp.now(),
      'isActive': true,
      'onboardingCompleted': true,
      'isDemoAccount': true,
    });

    debugPrint('Created demo account: ${accountData['email']}');
  }
} on firebase_auth.FirebaseAuthException catch (e) {
  if (e.code == 'email-already-in-use') {
    // Account exists in Auth but not in Firestore, try to sign in and update
    try {
      final existingCredential = await tempAuth.signInWithEmailAndPassword(
              email: accountData['email'],
              password: accountData['password'],
            );
            
            if (existingCredential.user != null) {
              // Update/create Firestore document
              await _firestore.collection('users').doc(existingCredential.user!.uid).set({
                'email': accountData['email'],
                'name': accountData['name'],
                'role': accountData['role'],
                'gender': accountData['gender'],
                'createdAt': Timestamp.now(),
                'isActive': true,
                'onboardingCompleted': true,
                'isDemoAccount': true,
              }, SetOptions(merge: true));
              
              debugPrint('Updated existing demo account: ${accountData['email']}');
            }
          } catch (signInError) {
            debugPrint('Demo account ${accountData['email']} exists but cannot sign in: $signInError');
          }
        } else {
          debugPrint('Error creating demo account ${accountData['email']}: ${e.message}');
        }
      }

      // Clean up temporary app
      await tempApp.delete();
    } catch (e) {
      debugPrint('Error creating demo account ${accountData['email']}: $e');
    }
  }

  // Reset demo accounts (useful for testing)
  static Future<void> resetDemoAccounts() async {
    if (!kDebugMode) {
      debugPrint('Demo accounts can only be reset in debug mode');
      return;
    }

    try {
      for (final account in demoAccounts.values) {
        // Get user from Firestore
        final QuerySnapshot userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: account['email'])
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userId = userQuery.docs.first.id;
          
          // Reset user data to original state
          await _firestore.collection('users').doc(userId).update({
            'name': account['name'],
            'role': account['role'],
            'gender': account['gender'],
            'isActive': true,
            'onboardingCompleted': true,
            'isDemoAccount': true,
          });

          // Delete any related data (messages, posts, etc.)
          await _clearUserData(userId);
          
          debugPrint('Reset demo account: ${account['email']}');
        }
      }
    } catch (e) {
      debugPrint('Error resetting demo accounts: $e');
    }
  }

  // Clear user-related data (messages, posts, etc.)
  static Future<void> _clearUserData(String userId) async {
    try {
      // Delete user's messages
      final messagesQuery = await _firestore
          .collection('messages')
          .where('senderId', isEqualTo: userId)
          .get();
      
      for (final doc in messagesQuery.docs) {
        await doc.reference.delete();
      }

      // Delete user's community posts
      final postsQuery = await _firestore
          .collection('communityPosts')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in postsQuery.docs) {
        await doc.reference.delete();
      }

      debugPrint('Cleared data for user: $userId');
    } catch (e) {
      debugPrint('Error clearing user data: $e');
    }
  }

  // Get demo account credentials (for display in login screen)
 static List<User> getDemoCredentials() {
  return demoAccounts.entries.map((entry) {
    final roleString = entry.value['role'];
    final role = UserRole.values.firstWhere(
      (e) => e.toString() == 'UserRole.$roleString',
      orElse: () => UserRole.user,
    );

    return User(
      id: entry.key,
      email: entry.value['email'] ?? '',
      name: entry.value['name'] ?? '',
      role: role,
      createdAt: DateTime.now(), // or use a fixed/mock date
      gender: entry.value['gender'],
    );
  }).where((user) => user.role.toString() != 'UserRole.counselor2').toList();
}
}