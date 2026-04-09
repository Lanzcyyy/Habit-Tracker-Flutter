import 'dart:convert';

import 'package:dart_project/features/auth/domain/auth_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthRepository {
  static const _usersKey = 'auth.users.v1';
  static const _currentUserKey = 'auth.currentUser.v1';

  Future<AuthSession?> getCurrentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_currentUserKey);
    if (username == null || username.isEmpty) {
      return null;
    }
    return AuthSession(username: username);
  }

  Future<String?> signUp({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    if (normalizedUsername.length < 3) {
      return 'Username must be at least 3 characters.';
    }
    if (password.length < 4) {
      return 'Password must be at least 4 characters.';
    }

    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);
    if (users.containsKey(normalizedUsername)) {
      return 'Username already exists.';
    }

    users[normalizedUsername] = password;
    await prefs.setString(_usersKey, jsonEncode(users));
    await prefs.setString(_currentUserKey, normalizedUsername);
    return null;
  }

  Future<String?> signIn({
    required String username,
    required String password,
  }) async {
    final normalizedUsername = username.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final users = _loadUsers(prefs);

    if (!users.containsKey(normalizedUsername)) {
      return 'No account found for this username.';
    }
    if (users[normalizedUsername] != password) {
      return 'Incorrect password.';
    }

    await prefs.setString(_currentUserKey, normalizedUsername);
    return null;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  Map<String, String> _loadUsers(SharedPreferences prefs) {
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) {
      return <String, String>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
      (key, value) => MapEntry(key.toString(), value.toString()),
    );
  }
}
