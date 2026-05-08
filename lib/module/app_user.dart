enum UserRole { administrator, treasurer }

class AppUser {
  const AppUser({
    required this.username,
    required this.displayName,
    required this.role,
  });

  final String username;
  final String displayName;
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
}
