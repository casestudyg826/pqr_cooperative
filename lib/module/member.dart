enum MemberStatus { active, inactive }

class Member {
  const Member({
    required this.id,
    required this.memberCode,
    required this.fullName,
    required this.address,
    required this.phone,
    required this.joinedAt,
    this.status = MemberStatus.active,
  });

  final String id;
  final String memberCode;
  final String fullName;
  final String address;
  final String phone;
  final DateTime joinedAt;
  final MemberStatus status;

  Member copyWith({
    String? memberCode,
    String? fullName,
    String? address,
    String? phone,
    DateTime? joinedAt,
    MemberStatus? status,
  }) {
    return Member(
      id: id,
      memberCode: memberCode ?? this.memberCode,
      fullName: fullName ?? this.fullName,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      joinedAt: joinedAt ?? this.joinedAt,
      status: status ?? this.status,
    );
  }

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'].toString(),
      memberCode: (json['member_code'] ?? json['memberCode']).toString(),
      fullName: (json['full_name'] ?? json['fullName']).toString(),
      address: json['address'].toString(),
      phone: json['phone'].toString(),
      joinedAt: DateTime.parse(
        (json['joined_at'] ?? json['joinedAt']).toString(),
      ),
      status: _statusFromJson(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_code': memberCode,
      'full_name': fullName,
      'address': address,
      'phone': phone,
      'joined_at': joinedAt.toIso8601String(),
      'status': status.name,
    };
  }

  static MemberStatus _statusFromJson(Object? value) {
    switch (value?.toString()) {
      case 'active':
        return MemberStatus.active;
      case 'inactive':
        return MemberStatus.inactive;
    }
    throw FormatException('Unknown member status: $value');
  }
}
