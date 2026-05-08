enum UserRole { administrator, treasurer }

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.password,
    required this.role,
  });

  final String id;
  final String username;
  final String displayName;
  final String password;
  final UserRole role;

  bool get isAdministrator => role == UserRole.administrator;
  bool get isTreasurer => role == UserRole.treasurer;

  String get roleLabel {
    switch (role) {
      case UserRole.administrator:
        return 'Administrator';
      case UserRole.treasurer:
        return 'Treasurer';
    }
  }

  AppUser copyWith({
    String? username,
    String? displayName,
    String? password,
    UserRole? role,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      password: password ?? this.password,
      role: role ?? this.role,
    );
  }
}
