import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

enum AuthState {
  unauthenticated,
  authenticated,
  loading,
}

class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final bool isGuest;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.isGuest = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'isGuest': isGuest,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'],
        email: map['email'],
        displayName: map['displayName'],
        isGuest: map['isGuest'] ?? false,
      );
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

final currentUserProvider = StateProvider<UserProfile?>((ref) => null);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.loading) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final box = Hive.box('settings');
    final isAuthenticated = box.get('isAuthenticated', defaultValue: false);

    await Future.delayed(const Duration(milliseconds: 500));
    state =
        isAuthenticated ? AuthState.authenticated : AuthState.unauthenticated;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signup(String email, String password) async {
    state = AuthState.loading;

    try {
      final box = Hive.box('settings');

      // Check if email already exists
      final users = box.get('users', defaultValue: <String, dynamic>{}) as Map;
      if (users.containsKey(email)) {
        throw Exception('Email already registered');
      }

      // Hash password and store user
      final passwordHash = _hashPassword(password);
      users[email] = {
        'passwordHash': passwordHash,
        'createdAt': DateTime.now().toIso8601String(),
      };

      await box.put('users', users);

      state = AuthState.unauthenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading;

    try {
      final box = Hive.box('settings');
      final users = box.get('users', defaultValue: <String, dynamic>{}) as Map;

      if (!users.containsKey(email)) {
        throw Exception('Invalid email or password');
      }

      final userData = users[email] as Map;
      final storedHash = userData['passwordHash'];
      final inputHash = _hashPassword(password);

      if (storedHash != inputHash) {
        throw Exception('Invalid email or password');
      }

      // Save session
      await box.put('isAuthenticated', true);
      await box.put('currentUserEmail', email);

      state = AuthState.authenticated;
    } catch (e) {
      state = AuthState.unauthenticated;
      rethrow;
    }
  }

  Future<void> loginAsGuest() async {
    state = AuthState.loading;
    final box = Hive.box('settings');
    await box.put('isAuthenticated', true);
    await box.put('isGuest', true);
    state = AuthState.authenticated;
  }

  Future<void> logout() async {
    final box = Hive.box('settings');
    await box.put('isAuthenticated', false);
    await box.delete('currentUserEmail');
    await box.delete('isGuest');
    state = AuthState.unauthenticated;
  }
}
