import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart' as firebase_core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

enum AuthMode {
  firebase,  
  demo,      
}

enum AuthError {
  userNotFound,
  invalidPassword,
  userExists,
  weakPassword,
  networkError,
  accountDisabled,
  tooManyRequests,
  unknown
}

class AuthResult {
  final bool success;
  final AuthError? error;
  final String? message;

  AuthResult.success() : success = true, error = null, message = null;
  AuthResult.failure(this.error, [this.message]) : success = false;
}

class AuthService  extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _firebaseAuth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  AuthMode _authMode = AuthMode.firebase; // Default to Firebase
  bool _needsOnboarding = false;
  
  // Demo mode data (fallback when Firebase is unavailable)
  final Map<String, Map<String, dynamic>> _demoAccounts = {
    'admin@girainshuti.com': {
      'password': 'admin123',
      'user': User(
        id: 'demo_admin_1',
        email: 'admin@girainshuti.com',
        name: 'System Administrator',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        gender: 'Prefer not to say',
      ),
    },
    'counselor@girainshuti.com': {
      'password': 'counselor123',
      'user': User(
        id: 'demo_counselor_1',
        email: 'counselor@girainshuti.com',
        name: 'Dr. Sarah Johnson',
        role: UserRole.counselor,
        createdAt: DateTime.now(),
        gender: 'Female',
      ),
    },
    'user@girainshuti.com': {
      'password': 'user123',
      'user': User(
        id: 'demo_user_1',
        email: 'user@girainshuti.com',
        name: 'Demo User',
        role: UserRole.user,
        createdAt: DateTime.now(),
        gender: 'Male',
      ),
    },
  };

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;
  AuthMode get authMode => _authMode;
  bool get needsOnboarding => _needsOnboarding;
  bool get isUsingFirebase => _authMode == AuthMode.firebase;

  AuthService() {
    _initializeAuth();
  }

  // Initialize authentication
  void _initializeAuth() {
    // Check if Firebase is available
    try {
      _firebaseAuth.authStateChanges().listen((firebase_auth.User? firebaseUser) async {
        if (firebaseUser != null) {
          await _loadUserFromFirestore(firebaseUser.uid);
        } else {
          _currentUser = null;
          _needsOnboarding = false;
        }
        notifyListeners();
      });
      _authMode = AuthMode.firebase;
      debugPrint('Auth Service: Using Firebase mode');
    } catch (e) {
      _authMode = AuthMode.demo;
      debugPrint('Auth Service: Firebase unavailable, using demo mode');
    }
  }

  // Password validation rules
  List<String> getPasswordErrors(String password) {
    List<String> errors = [];
    
    if (password.length < 8) {
      errors.add('At least 8 characters');
    }
    if (password.length > 128) {
      errors.add('Maximum 128 characters');
    }
    if (password.contains(' ')) {
      errors.add('No spaces allowed');
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      errors.add('At least one uppercase letter (A–Z)');
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      errors.add('At least one lowercase letter (a–z)');
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      errors.add('At least one number (0–9)');
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\\/~`]'))) {
      errors.add('At least one special character');
    }
    
    // Common weak patterns
    if (password.toLowerCase().contains('password')) {
      errors.add('Cannot contain "password"');
    }
    if (password.contains('123456')) {
      errors.add('Cannot contain "123456"');
    }
    if (RegExp(r'^(.)\1+$').hasMatch(password)) {
      errors.add('Cannot be all same character');
    }
    
    return errors;
  }

  bool isPasswordValid(String password) {
    return getPasswordErrors(password).isEmpty;
  }

  int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;
    
    int score = 0;
    
    // Length scoring
    if (password.length >= 8) score += 20;
    if (password.length >= 12) score += 10;
    if (password.length >= 16) score += 10;
    
    // Character variety
    if (password.contains(RegExp(r'[A-Z]'))) score += 15;
    if (password.contains(RegExp(r'[a-z]'))) score += 15;
    if (password.contains(RegExp(r'[0-9]'))) score += 15;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_+=\-\[\]\\\/~`]'))) score += 15;
    
    // No common patterns bonus
    if (!password.toLowerCase().contains('password') && 
        !password.contains('123') && 
        !RegExp(r'(.)\1{2,}').hasMatch(password)) {
      score += 10;
    }
    
    return score.clamp(0, 100);
  }

  // Get demo credentials for UI display
  Map<String, String> getDemoCredentials() {
    return {
      'admin@girainshuti.com': 'Admin123!@#',
      'counselor@girainshuti.com': 'Counselor123!@#',
      'user@girainshuti.com': 'Demo123!@#',
    };
  }

  // Sign in with email and password
  Future<AuthResult> signIn(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if it's a demo account first
      if (_demoAccounts.containsKey(email.toLowerCase())) {
        return await _signInDemoAccount(email, password);
      }

      // Try Firebase authentication
      if (_authMode == AuthMode.firebase) {
        return await _signInWithFirebase(email, password);
      } else {
        // Demo mode only
        return AuthResult.failure(
          AuthError.userNotFound,
          'Only demo accounts available in offline mode'
        );
      }
    } catch (e) {
      _errorMessage = 'Sign in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(AuthError.unknown, _errorMessage);
    }
  }

  // Sign in with demo account
  Future<AuthResult> _signInDemoAccount(String email, String password) async {
    await Future.delayed(Duration(seconds: 1)); // Simulate network delay
    
    final account = _demoAccounts[email.toLowerCase()];
    if (account != null && account['password'] == password) {
      _currentUser = account['user'] as User;
      _isLoading = false;
      notifyListeners();
      debugPrint('Signed in with demo account: $email');
      return AuthResult.success();
    }
    
    _isLoading = false;
    notifyListeners();
    return AuthResult.failure(
      AuthError.invalidPassword,
      'Invalid email or password'
    );
  }

  // Sign in with Firebase
  Future<AuthResult> _signInWithFirebase(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _loadUserFromFirestore(credential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return AuthResult.success();
      }
      
      return AuthResult.failure(AuthError.unknown, 'Sign in failed');
    } on firebase_auth.FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();
      
      switch (e.code) {
        case 'user-not-found':
          return AuthResult.failure(AuthError.userNotFound, 'No account found with this email');
        case 'wrong-password':
          return AuthResult.failure(AuthError.invalidPassword, 'Incorrect password');
        case 'invalid-email':
          return AuthResult.failure(AuthError.unknown, 'Invalid email format');
        case 'user-disabled':
          return AuthResult.failure(AuthError.accountDisabled, 'This account has been disabled');
        case 'too-many-requests':
          return AuthResult.failure(AuthError.tooManyRequests, 'Too many failed attempts. Please try again later');
        default:
          return AuthResult.failure(AuthError.unknown, e.message ?? 'Sign in failed');
      }
    }
  }

  // Register new user
  Future<AuthResult> register(String email, String password, String name, {String? gender}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Check if it's a demo account email
    if (_demoAccounts.containsKey(email.toLowerCase())) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(
        AuthError.userExists,
        'This email is reserved for demo accounts'
      );
    }

    // Validate password
    final passwordErrors = getPasswordErrors(password);
    if (passwordErrors.isNotEmpty) {
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(
        AuthError.weakPassword,
        'Password requirements: ${passwordErrors.join(', ')}'
      );
    }

    // Firebase registration
    if (_authMode == AuthMode.firebase) {
      try {
        // Check if email exists in Firestore first
        final existingUsers = await _firestore
            .collection('users')
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();

        if (existingUsers.docs.isNotEmpty) {
          _isLoading = false;
          notifyListeners();
          return AuthResult.failure(
            AuthError.userExists,
            'An account with this email already exists'
          );
        }

        // Create Firebase Auth account
        final credential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (credential.user != null) {
          // Update display name
          await credential.user!.updateDisplayName(name);
          
          // Create Firestore document
          final userData = {
            'email': email.toLowerCase(),
            'name': name,
            'role': 'user',
            'createdAt': Timestamp.now(),
            'isActive': true,
            'gender': gender,
            'onboardingCompleted': gender != null,
          };

          await _firestore.collection('users').doc(credential.user!.uid).set(userData);
          
          _currentUser = User(
            id: credential.user!.uid,
            email: email,
            name: name,
            role: UserRole.user,
            createdAt: DateTime.now(),
            isActive: true,
            gender: gender,
          );

          _needsOnboarding = gender == null;
          _isLoading = false;
          notifyListeners();
          return AuthResult.success();
        }
        
        return AuthResult.failure(AuthError.unknown, 'Registration failed');
      } on firebase_auth.FirebaseAuthException catch (e) {
        _isLoading = false;
        notifyListeners();
        
        switch (e.code) {
          case 'email-already-in-use':
            return AuthResult.failure(AuthError.userExists, 'An account already exists with this email');
          case 'weak-password':
            return AuthResult.failure(AuthError.weakPassword, 'Password is too weak');
          case 'invalid-email':
            return AuthResult.failure(AuthError.unknown, 'Invalid email format');
          default:
            return AuthResult.failure(AuthError.unknown, e.message ?? 'Registration failed');
        }
      }
    } else {
      // Demo mode - registration not allowed
      _isLoading = false;
      notifyListeners();
      return AuthResult.failure(
        AuthError.networkError,
        'Registration requires internet connection'
      );
    }
  }

  // Load user from Firestore
  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _currentUser = User(
          id: uid,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: _parseUserRole(data['role']),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          gender: data['gender'],
        );
        
        _needsOnboarding = _currentUser!.gender == null || 
                          _currentUser!.name.isEmpty ||
                          data['onboardingCompleted'] != true;
      }
    } catch (e) {
      debugPrint('Error loading user from Firestore: $e');
      _errorMessage = 'Failed to load user data';
    }
  }

  // Parse user role
  UserRole _parseUserRole(String? role) {
    switch (role) {
      case 'admin':
        return UserRole.admin;
      case 'counselor':
        return UserRole.counselor;
      default:
        return UserRole.user;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    if (_authMode != AuthMode.firebase) {
      _errorMessage = 'Google sign in requires internet connection';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final firebase_auth.UserCredential userCredential = 
          await _firebaseAuth.signInWithCredential(credential);

      final firebase_auth.User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        
        if (!userDoc.exists) {
          // Create new user document
          final userData = {
            'email': firebaseUser.email ?? '',
            'name': firebaseUser.displayName ?? '',
            'role': 'user',
            'createdAt': Timestamp.now(),
            'isActive': true,
            'gender': null,
            'onboardingCompleted': false,
            'photoUrl': firebaseUser.photoURL,
          };

          await _firestore.collection('users').doc(firebaseUser.uid).set(userData);
          _needsOnboarding = true;
        } else {
          await _loadUserFromFirestore(firebaseUser.uid);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
      
      throw Exception('Failed to get user from Firebase');
    } catch (e) {
      _errorMessage = 'Google sign in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_authMode == AuthMode.firebase) {
        await _googleSignIn.signOut();
        await _firebaseAuth.signOut();
      }
      
      _currentUser = null;
      _errorMessage = null;
      _needsOnboarding = false;
    } catch (e) {
      _errorMessage = 'Sign out failed: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? displayName,
    String? gender,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_currentUser == null) return false;

    // Demo mode - just update local state
    if (_authMode == AuthMode.demo) {
      _currentUser = _currentUser!.copyWith(
        name: displayName ?? _currentUser!.name,
        gender: gender ?? _currentUser!.gender,
      );
      
      if (gender != null) {
        _needsOnboarding = false;
      }
      
      notifyListeners();
      return true;
    }

    // Firebase mode
    if (_firebaseAuth.currentUser == null) return false;

    try {
      if (displayName != null) {
        await _firebaseAuth.currentUser!.updateDisplayName(displayName);
      }

      final updates = <String, dynamic>{};
      if (displayName != null) updates['name'] = displayName;
      if (gender != null) updates['gender'] = gender;
      if (additionalData != null) updates.addAll(additionalData);
      
      if (gender != null) {
        updates['onboardingCompleted'] = true;
      }

      await _firestore.collection('users').doc(_currentUser!.id).update(updates);

      _currentUser = _currentUser!.copyWith(
        name: displayName ?? _currentUser!.name,
        gender: gender ?? _currentUser!.gender,
      );

      if (gender != null) {
        _needsOnboarding = false;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Profile update failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Password reset
  Future<bool> sendPasswordResetEmail(String email) async {
    if (_authMode != AuthMode.firebase) {
      _errorMessage = 'Password reset requires internet connection';
      notifyListeners();
      return false;
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = 'No user found with this email';
      } else {
        _errorMessage = e.message ?? 'Failed to send reset email';
      }
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get all users (admin only)
  Stream<List<User>>? getAllUsers() {
    // Debug logging
    debugPrint('=== getAllUsers called ===');
    debugPrint('Current user: ${_currentUser?.email}');
    debugPrint('Current user role: ${_currentUser?.role}');
    debugPrint('Firebase Auth UID: ${_firebaseAuth.currentUser?.uid}');
    debugPrint('Auth mode: $_authMode');
    
    // Keep the role check - it's important for security!
    if (_currentUser?.role != UserRole.admin) {
      debugPrint('User is not admin, returning null');
      return null;
    }
    
    if (_authMode != AuthMode.firebase) {
      debugPrint('Using demo mode');
      return Stream.value(
        _demoAccounts.values.map((account) => account['user'] as User).toList()
      );
    }

    debugPrint('Creating Firestore stream for users collection');
    
    return _firestore.collection('users').snapshots().map((snapshot) {
      debugPrint('✅ Received snapshot with ${snapshot.docs.length} users');
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: _parseUserRole(data['role']),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          gender: data['gender'],
        );
      }).toList();
    }).handleError((error) {
      debugPrint('❌ FIRESTORE ERROR: $error');
    });
  }

  // Get all counselors
  Stream<List<User>>? getAllCounselors() {
    if (_authMode != AuthMode.firebase) {
      // Return demo counselor as a stream
      final counselor = _demoAccounts['counselor@girainshuti.com']!['user'] as User;
      return Stream.value([counselor]);
    }

    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'counselor')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return User(
          id: doc.id,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          role: UserRole.counselor,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          isActive: data['isActive'] ?? true,
          gender: data['gender'],
        );
      }).toList();
    });
  }
    // Create counselor account (Admin only)
  Future<bool> createCounselor(String email, String name, String password, {String? gender}) async {
    if (_currentUser?.role != UserRole.admin) return false;

    // Demo mode - not supported
    if (_authMode == AuthMode.demo) {
      _errorMessage = 'Creating counselors requires Firebase connection';
      notifyListeners();
      return false;
    }

    try {
      // Create a temporary Firebase app to avoid signing out the current admin
      final tempApp = await firebase_core.Firebase.initializeApp(
        name: 'tempApp_${DateTime.now().millisecondsSinceEpoch}',
        options: firebase_core.Firebase.app().options,
      );

      final tempAuth = firebase_auth.FirebaseAuth.instanceFor(app: tempApp);

      final credential = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create Firestore document
        final counselorData = {
          'email': email.toLowerCase(),
          'name': name,
          'role': 'counselor',
          'createdAt': Timestamp.now(),
          'isActive': true,
          'gender': gender,
          'onboardingCompleted': true,
          'createdBy': _currentUser!.id,
        };

        await _firestore.collection('users').doc(credential.user!.uid).set(counselorData);

        // Clean up temporary app
        await tempApp.delete();
        
        debugPrint('Created counselor account: $email');
        return true;
      }

      await tempApp.delete();
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      _errorMessage = 'Failed to create counselor: ${e.message}';
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to create counselor: $e';
      notifyListeners();
      return false;
    }
  }
// Backward compatibility
Future<void> logout() => signOut();

// Toggle user active status (Admin only)
  Future<bool> toggleUserStatus(String userId) async {
    if (_currentUser?.role != UserRole.admin) return false;
    
    if (_authMode == AuthMode.demo) {
      _errorMessage = 'Cannot modify demo accounts';
      notifyListeners();
      return false;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final currentStatus = userDoc.data()?['isActive'] ?? true;
        await _firestore.collection('users').doc(userId).update({
          'isActive': !currentStatus,
        });
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to update user status: $e';
      notifyListeners();
      return false;
    }
  }
// Add to AuthService class
  User? getUserById(String userId) {
    // Demo mode
    if (_authMode == AuthMode.demo) {
      for (var account in _demoAccounts.values) {
        final user = account['user'] as User;
        if (user.id == userId) return user;
      }
      return null;
    }
    
    // For Firebase, you'd need caching - this is a limitation
    // without making it async
    return null;
  }
}
        