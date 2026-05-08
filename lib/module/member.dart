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
}
