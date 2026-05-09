enum UserRole { administrator, treasurer }

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    this.password = '',
    this.isActive = true,
  });

  final String id;
  final String username;
  final String displayName;
  final String password;
  final UserRole role;
  final bool isActive;

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
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      password: password ?? this.password,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      username: json['username'].toString(),
      displayName: (json['display_name'] ?? json['displayName']).toString(),
      role: _roleFromJson(json['role']),
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'role': role.name,
      'is_active': isActive,
    };
  }

  static UserRole _roleFromJson(Object? value) {
    switch (value?.toString()) {
      case 'administrator':
        return UserRole.administrator;
      case 'treasurer':
        return UserRole.treasurer;
    }
    throw FormatException('Unknown user role: $value');
  }
}
