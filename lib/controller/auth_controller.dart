import 'package:flutter/foundation.dart';

import '../module/app_user.dart';

class AuthController extends ChangeNotifier {
  AppUser? _currentUser;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  bool login(String username, String password) {
    final normalized = username.trim().toLowerCase();
    if (normalized == 'admin' && password == 'admin123') {
      _currentUser = const AppUser(
        username: 'admin',
        displayName: 'System Administrator',
        role: UserRole.administrator,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    if (normalized == 'treasurer' && password == 'treasurer123') {
      _currentUser = const AppUser(
        username: 'treasurer',
        displayName: 'Cooperative Treasurer',
        role: UserRole.treasurer,
      );
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Invalid username or password.';
    notifyListeners();
    return false;
  }

  void logout() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
