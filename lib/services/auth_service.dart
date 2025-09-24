// services/auth_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  List<User> _users = [];
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;

  AuthService() {
    _initializeDefaultUsers();
  }

  void _initializeDefaultUsers() {
    // Pre-populate with admin and counselor accounts
    _users = [
      User(
        id: '1',
        email: 'admin@girainshuti.com',
        name: 'System Administrator',
        role: UserRole.admin,
        createdAt: DateTime.now(),
        gender: 'Prefer not to say',
      ),
      User(
        id: '2',
        email: 'counselor@girainshuti.com',
        name: 'Senior Counselor',
        role: UserRole.counselor,
        createdAt: DateTime.now(),
        gender: 'Woman',
      ),
    ];
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));

    try {
      // Find user by email
      final user = _users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // Simple password validation (in real app, use proper hashing)
      if (_validatePassword(email, password)) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        throw Exception('Invalid password');
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool _validatePassword(String email, String password) {
    // Simple password validation for demo
    // In production, use proper password hashing
    if (email == 'admin@girainshuti.com') {
      return password == 'admin123';
    } else if (email == 'counselor@girainshuti.com') {
      return password == 'counselor123';
    } else {
      // For user accounts, validate password complexity
      return _isPasswordComplex(password);
    }
  }

  bool _isPasswordComplex(String password) {
    // Check password meets all requirements
    return password.length >= 8 &&
           password.contains(RegExp(r'[A-Z]')) && // Uppercase letter
           password.contains(RegExp(r'[a-z]')) && // Lowercase letter
           password.contains(RegExp(r'[0-9]')) && // Number
           password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')); // Special character
  }

  Future<bool> register(String email, String password, String name, {String? gender}) async {
    _isLoading = true;
    notifyListeners();

    // Simulate network delay
    await Future.delayed(Duration(seconds: 1));

    try {
      // Check if user already exists
      final existingUser = _users.where(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
      );

      if (existingUser.isNotEmpty) {
        throw Exception('User already exists');
      }

      // Validate password complexity
      if (!_isPasswordComplex(password)) {
        throw Exception('Password does not meet requirements');
      }

      // Create new user (only regular users can register)
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: UserRole.user, // Only users can self-register
        createdAt: DateTime.now(),
        gender: gender,
      );

      _users.add(newUser);
      _currentUser = newUser;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Admin functions
  List<User> getAllUsers() {
    if (_currentUser?.role != UserRole.admin) {
      return [];
    }
    return List.from(_users);
  }

  // Get all counselors (for users to see available counselors)
  List<User> getAllCounselors() {
    return _users.where((u) => u.role == UserRole.counselor && u.isActive).toList();
  }

  // Get all active users (for counselors to see their potential clients)
  List<User> getAllActiveUsers() {
    return _users.where((u) => u.role == UserRole.user && u.isActive).toList();
  }

  // Get user by ID
  User? getUserById(String userId) {
    try {
      return _users.firstWhere((u) => u.id == userId);
    } catch (e) {
      return null;
    }
  }

  Future<bool> createCounselor(String email, String name, String password, {String? gender}) async {
    if (_currentUser?.role != UserRole.admin) {
      return false;
    }

    final newCounselor = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      role: UserRole.counselor,
      createdAt: DateTime.now(),
      gender: gender,
    );

    _users.add(newCounselor);
    notifyListeners();
    return true;
  }

  Future<bool> toggleUserStatus(String userId) async {
    if (_currentUser?.role != UserRole.admin) {
      return false;
    }

    final userIndex = _users.indexWhere((u) => u.id == userId);
    if (userIndex != -1) {
      final user = _users[userIndex];
      _users[userIndex] = user.copyWith(isActive: !user.isActive);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? name,
    String? email,
    String? gender,
  }) async {
    if (_currentUser == null) return false;

    final userIndex = _users.indexWhere((u) => u.id == _currentUser!.id);
    if (userIndex != -1) {
      final updatedUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        email: email ?? _currentUser!.email,
        gender: gender ?? _currentUser!.gender,
      );
      
      _users[userIndex] = updatedUser;
      _currentUser = updatedUser;
      notifyListeners();
      return true;
    }
    return false;
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;
    
    // Validate current password
    if (!_validatePassword(_currentUser!.email, currentPassword)) {
      return false;
    }
    
    // Validate new password complexity
    if (!_isPasswordComplex(newPassword)) {
      return false;
    }
    
    // In a real app, you would hash and store the new password
    // For this demo, we'll just return true
    return true;
  }
}