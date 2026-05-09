import 'package:flutter/foundation.dart';

import '../module/member.dart';

class MemberController extends ChangeNotifier {
  final List<Member> _members = [
    Member(
      id: 'm001',
      memberCode: 'PQR-0001',
      fullName: 'Maria Santos',
      address: 'Lahug, Cebu City',
      phone: '0917 100 2001',
      joinedAt: DateTime(2021, 3, 12),
    ),
    Member(
      id: 'm002',
      memberCode: 'PQR-0002',
      fullName: 'Juan Dela Cruz',
      address: 'Mabolo, Cebu City',
      phone: '0918 200 3002',
      joinedAt: DateTime(2022, 7, 3),
    ),
    Member(
      id: 'm003',
      memberCode: 'PQR-0003',
      fullName: 'Ana Reyes',
      address: 'Talisay City, Cebu',
      phone: '0919 300 4003',
      joinedAt: DateTime(2023, 1, 22),
    ),
  ];

  List<Member> get members => List.unmodifiable(_members);
  int get activeCount =>
      _members.where((member) => member.status == MemberStatus.active).length;

  List<Member> search(String query) {
    final value = query.trim().toLowerCase();
    if (value.isEmpty) {
      return members;
    }

    return _members.where((member) {
      return member.fullName.toLowerCase().contains(value) ||
          member.memberCode.toLowerCase().contains(value) ||
          member.phone.toLowerCase().contains(value);
    }).toList();
  }

  Member? findById(String id) {
    for (final member in _members) {
      if (member.id == id) {
        return member;
      }
    }
    return null;
  }

  String nameFor(String memberId) {
    return findById(memberId)?.fullName ?? 'Unknown member';
  }

  void addMember({
    required String fullName,
    required String address,
    required String phone,
  }) {
    final nextNumber = _members.length + 1;
    final id = 'm${DateTime.now().microsecondsSinceEpoch}';
    _members.add(
      Member(
        id: id,
        memberCode: 'PQR-${nextNumber.toString().padLeft(4, '0')}',
        fullName: fullName.trim(),
        address: address.trim(),
        phone: phone.trim(),
        joinedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void updateMember(Member updatedMember) {
    final index = _members.indexWhere(
      (member) => member.id == updatedMember.id,
    );
    if (index == -1) {
      return;
    }
    _members[index] = updatedMember;
    notifyListeners();
  }

  bool deleteMember(String memberId) {
    final removedCount = _members.length;
    _members.removeWhere((member) => member.id == memberId);
    final deleted = _members.length != removedCount;
    if (deleted) {
      notifyListeners();
    }
    return deleted;
  }
}
