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
      ),
      User(
        id: '2',
        email: 'counselor@girainshuti.com',
        name: 'Senior Counselor',
        role: UserRole.counselor,
        createdAt: DateTime.now(),
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
      return password.length >= 6; // Basic validation for user accounts
    }
  }

  Future<bool> register(String email, String password, String name) async {
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

      // Create new user (only regular users can register)
      final newUser = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        name: name,
        role: UserRole.user, // Only users can self-register
        createdAt: DateTime.now(),
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

  Future<bool> createCounselor(String email, String name, String password) async {
    if (_currentUser?.role != UserRole.admin) {
      return false;
    }

    final newCounselor = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      role: UserRole.counselor,
      createdAt: DateTime.now(),
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
      _users[userIndex] = User(
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        createdAt: user.createdAt,
        isActive: !user.isActive,
      );
      notifyListeners();
      return true;
    }
    return false;
  }
}