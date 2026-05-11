enum UserRole { administrator, treasurer, member }

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    this.memberId,
    this.password = '',
    this.isActive = true,
  });

  final String id;
  final String username;
  final String displayName;
  final String? memberId;
  final String password;
  final UserRole role;
  final bool isActive;

  bool get isAdministrator => role == UserRole.administrator;
  bool get isTreasurer => role == UserRole.treasurer;
  bool get isMember => role == UserRole.member;

  String get roleLabel {
    switch (role) {
      case UserRole.administrator:
        return 'Administrator';
      case UserRole.treasurer:
        return 'Treasurer';
      case UserRole.member:
        return 'Member';
    }
  }

  AppUser copyWith({
    String? username,
    String? displayName,
    String? memberId,
    String? password,
    UserRole? role,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      memberId: memberId ?? this.memberId,
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
      memberId: (json['member_id'] ?? json['memberId'])?.toString(),
      role: _roleFromJson(json['role']),
      isActive: json['is_active'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'member_id': memberId,
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
      case 'member':
        return UserRole.member;
    }
    throw FormatException('Unknown user role: $value');
  }
}
