import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../module/app_user.dart';

class AuthController extends ChangeNotifier {
  final List<AppUser> _users = [
    const AppUser(
      id: 'u001',
      username: 'admin',
      displayName: 'System Administrator',
      password: 'admin123',
      role: UserRole.administrator,
    ),
    const AppUser(
      id: 'u002',
      username: 'treasurer',
      displayName: 'Cooperative Treasurer',
      password: 'treasurer123',
      role: UserRole.treasurer,
    ),
  ];

  AppUser? _currentUser;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  UnmodifiableListView<AppUser> get users => UnmodifiableListView(_users);

  bool login(String username, String password) {
    final normalized = username.trim().toLowerCase();
    AppUser? user;
    for (final item in _users) {
      if (item.username.toLowerCase() == normalized) {
        user = item;
        break;
      }
    }

    if (user != null && user.password == password) {
      _currentUser = user;
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Invalid username or password.';
    notifyListeners();
    return false;
  }

  bool addUser({
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) {
    final cleanUsername = username.trim();
    final cleanDisplayName = displayName.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty ||
        cleanDisplayName.isEmpty ||
        cleanPassword.isEmpty) {
      return false;
    }
    if (_usernameExists(cleanUsername)) {
      return false;
    }

    _users.add(
      AppUser(
        id: 'u${DateTime.now().microsecondsSinceEpoch}',
        username: cleanUsername,
        displayName: cleanDisplayName,
        password: cleanPassword,
        role: role,
      ),
    );
    notifyListeners();
    return true;
  }

  bool updateUser({
    required String id,
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) {
    final cleanUsername = username.trim();
    final cleanDisplayName = displayName.trim();
    final cleanPassword = password.trim();

    if (cleanUsername.isEmpty ||
        cleanDisplayName.isEmpty ||
        cleanPassword.isEmpty) {
      return false;
    }

    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      return false;
    }

    if (_usernameExists(cleanUsername, excludeId: id)) {
      return false;
    }

    final updated = _users[index].copyWith(
      displayName: cleanDisplayName,
      username: cleanUsername,
      password: cleanPassword,
      role: role,
    );

    _users[index] = updated;
    if (_currentUser?.id == id) {
      _currentUser = updated;
    }
    notifyListeners();
    return true;
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  bool _usernameExists(String username, {String? excludeId}) {
    final normalized = username.toLowerCase();
    for (final user in _users) {
      if (excludeId != null && user.id == excludeId) {
        continue;
      }
      if (user.username.toLowerCase() == normalized) {
        return true;
      }
    }
    return false;
  }
}
