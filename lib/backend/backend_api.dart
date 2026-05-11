import '../module/app_user.dart';
import '../module/loan.dart';
import '../module/member.dart';
import '../module/repayment.dart';
import '../module/savings_transaction.dart';

class BackendException implements Exception {
  const BackendException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthResult {
  const AuthResult({required this.token, required this.user});

  final String token;
  final AppUser user;
}

class LoanRepaymentResult {
  const LoanRepaymentResult({required this.loan, required this.repayment});

  final Loan loan;
  final Repayment repayment;
}

class BackupRun {
  const BackupRun({
    required this.id,
    required this.status,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String status;
  final Map<String, dynamic> summary;
  final DateTime createdAt;

  factory BackupRun.fromJson(Map<String, dynamic> json) {
    return BackupRun(
      id: json['id'].toString(),
      status: json['status'].toString(),
      summary: Map<String, dynamic>.from(json['summary'] as Map? ?? {}),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'summary': summary,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BackendSnapshot {
  const BackendSnapshot({
    required this.users,
    required this.members,
    required this.savingsTransactions,
    required this.loans,
    required this.repayments,
    required this.backupRuns,
  });

  final List<AppUser> users;
  final List<Member> members;
  final List<SavingsTransaction> savingsTransactions;
  final List<Loan> loans;
  final List<Repayment> repayments;
  final List<BackupRun> backupRuns;

  factory BackendSnapshot.fromJson(Map<String, dynamic> json) {
    final repayments = _list(
      json['repayments'],
    ).map((item) => Repayment.fromJson(item)).toList();

    return BackendSnapshot(
      users: _list(
        json['users'],
      ).map((item) => AppUser.fromJson(item)).toList(),
      members: _list(
        json['members'],
      ).map((item) => Member.fromJson(item)).toList(),
      savingsTransactions: _list(
        json['savings_transactions'],
      ).map((item) => SavingsTransaction.fromJson(item)).toList(),
      loans: _list(json['loans']).map((item) {
        final loanRepayments = repayments
            .where((repayment) => repayment.loanId == item['id'].toString())
            .toList();
        return Loan.fromJson(item, repayments: loanRepayments);
      }).toList(),
      repayments: repayments,
      backupRuns: _list(
        json['backup_runs'],
      ).map((item) => BackupRun.fromJson(item)).toList(),
    );
  }

  static List<Map<String, dynamic>> _list(Object? value) {
    return (value as List? ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}

abstract class BackendApi {
  Future<AuthResult> login({
    required String username,
    required String password,
  });

  Future<AuthResult> signUpMember({
    required String fullName,
    required String address,
    required String phone,
    required String username,
    required String password,
  });

  Future<void> logout(String sessionToken);

  Future<BackendSnapshot> bootstrap(String sessionToken);

  Future<AppUser> addUser(
    String sessionToken, {
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  });

  Future<AppUser> addMemberAccount(
    String sessionToken, {
    required String fullName,
    required String address,
    required String phone,
    required String username,
    required String password,
  });

  Future<AppUser> updateUser(
    String sessionToken, {
    required String id,
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  });

  Future<Member> addMember(
    String sessionToken, {
    required String fullName,
    required String address,
    required String phone,
  });

  Future<Member> updateMember(String sessionToken, Member member);

  Future<void> deleteMember(String sessionToken, String memberId);

  Future<SavingsTransaction> recordSavingsTransaction(
    String sessionToken, {
    required String memberId,
    required SavingsTransactionType type,
    required double amount,
    required String note,
  });

  Future<Loan> addLoan(
    String sessionToken, {
    required String memberId,
    required double principal,
    int? termMonths,
  });

  Future<Loan> updateLoanStatus(
    String sessionToken, {
    required String loanId,
    required LoanStatus status,
    double? annualInterestRate,
    int? termMonths,
  });

  Future<LoanRepaymentResult> recordLoanPayment(
    String sessionToken, {
    required String loanId,
    required double amount,
    required String note,
  });

  Future<BackupRun> runBackup(String sessionToken);
}
