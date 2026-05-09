import 'package:flutter/foundation.dart';

import '../backend/backend_api.dart';
import '../module/member.dart';

class MemberController extends ChangeNotifier {
  MemberController(this._backend, this._sessionToken);

  final BackendApi _backend;
  final String Function() _sessionToken;
  final List<Member> _members = [];

  List<Member> get members => List.unmodifiable(_members);
  int get activeCount =>
      _members.where((member) => member.status == MemberStatus.active).length;

  void replaceAll(List<Member> members) {
    _members
      ..clear()
      ..addAll(members);
    notifyListeners();
  }

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

  Future<void> addMember({
    required String fullName,
    required String address,
    required String phone,
  }) async {
    final member = await _backend.addMember(
      _sessionToken(),
      fullName: fullName,
      address: address,
      phone: phone,
    );
    _members.add(member);
    notifyListeners();
  }

  Future<void> updateMember(Member updatedMember) async {
    final member = await _backend.updateMember(_sessionToken(), updatedMember);
    final index = _members.indexWhere((item) => item.id == member.id);
    if (index == -1) {
      return;
    }
    _members[index] = member;
    notifyListeners();
  }

  Future<bool> deleteMember(String memberId) async {
    await _backend.deleteMember(_sessionToken(), memberId);
    final removedCount = _members.length;
    _members.removeWhere((member) => member.id == memberId);
    final deleted = _members.length != removedCount;
    if (deleted) {
      notifyListeners();
    }
    return deleted;
  }
}
