import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../backend/backend_api.dart';
import '../module/app_user.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._backend, this._sessionToken);

  final BackendApi _backend;
  final String Function() _sessionToken;
  final List<AppUser> _users = [];

  AppUser? _currentUser;
  String? _errorMessage;
  String? _token;

  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  String? get sessionToken => _token;
  bool get isLoggedIn => _currentUser != null && _token != null;
  UnmodifiableListView<AppUser> get users => UnmodifiableListView(_users);

  Future<bool> login(String username, String password) async {
    try {
      final result = await _backend.login(
        username: username,
        password: password,
      );
      _currentUser = result.user;
      _token = result.token;
      _errorMessage = null;
      notifyListeners();
      return true;
    } on BackendException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to sign in. Check the backend connection.';
    }

    _currentUser = null;
    _token = null;
    notifyListeners();
    return false;
  }

  void replaceUsers(List<AppUser> users) {
    _users
      ..clear()
      ..addAll(users);
    notifyListeners();
  }

  Future<bool> addUser({
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    try {
      final user = await _backend.addUser(
        _sessionToken(),
        displayName: displayName,
        username: username,
        password: password,
        role: role,
      );
      _users.add(user);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateUser({
    required String id,
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    try {
      final updated = await _backend.updateUser(
        _sessionToken(),
        id: id,
        displayName: displayName,
        username: username,
        password: password,
        role: role,
      );
      final index = _users.indexWhere((user) => user.id == id);
      if (index == -1) {
        return false;
      }

      _users[index] = updated;
      if (_currentUser?.id == id) {
        _currentUser = updated;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _errorMessage = null;
    _users.clear();
    notifyListeners();
  }
}
