import 'backend_api.dart';
import '../module/app_user.dart';
import '../module/loan.dart';
import '../module/member.dart';
import '../module/repayment.dart';
import '../module/savings_transaction.dart';

class MemoryBackendApi implements BackendApi {
  MemoryBackendApi.seeded()
    : _users = [
        const AppUser(
          id: 'u001',
          username: 'admin',
          displayName: 'System Administrator',
          role: UserRole.administrator,
        ),
        const AppUser(
          id: 'u002',
          username: 'treasurer',
          displayName: 'Cooperative Treasurer',
          role: UserRole.treasurer,
        ),
      ],
      _passwords = {'admin': 'admin123', 'treasurer': 'treasurer123'},
      _members = [
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
      ],
      _savingsTransactions = [
        SavingsTransaction(
          id: 's001',
          memberId: 'm001',
          type: SavingsTransactionType.contribution,
          amount: 15000,
          date: DateTime(2025, 1, 15),
          note: 'Opening savings balance',
        ),
        SavingsTransaction(
          id: 's002',
          memberId: 'm002',
          type: SavingsTransactionType.contribution,
          amount: 9200,
          date: DateTime(2025, 2, 7),
          note: 'Monthly contribution',
        ),
        SavingsTransaction(
          id: 's003',
          memberId: 'm003',
          type: SavingsTransactionType.contribution,
          amount: 12500,
          date: DateTime(2025, 2, 18),
          note: 'Opening savings balance',
        ),
        SavingsTransaction(
          id: 's004',
          memberId: 'm001',
          type: SavingsTransactionType.withdrawal,
          amount: 2000,
          date: DateTime(2025, 3, 10),
          note: 'Member withdrawal',
        ),
      ],
      _loans = [
        Loan(
          id: 'l001',
          memberId: 'm001',
          principal: 30000,
          annualInterestRate: 0.12,
          termMonths: 12,
          appliedAt: DateTime(2025, 1, 20),
          dueDate: DateTime(2026, 1, 20),
          status: LoanStatus.approved,
          repayments: [
            Repayment(
              id: 'r001',
              loanId: 'l001',
              amount: 7000,
              date: DateTime(2025, 4, 2),
              note: 'Partial repayment',
            ),
          ],
        ),
        Loan(
          id: 'l002',
          memberId: 'm002',
          principal: 18000,
          annualInterestRate: 0.1,
          termMonths: 10,
          appliedAt: DateTime(2025, 4, 5),
          dueDate: DateTime(2026, 2, 5),
          status: LoanStatus.pending,
        ),
      ];

  final List<AppUser> _users;
  final Map<String, String> _passwords;
  final List<Member> _members;
  final List<SavingsTransaction> _savingsTransactions;
  final List<Loan> _loans;
  final List<BackupRun> _backupRuns = [];

  @override
  Future<AuthResult> login({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    AppUser? user;
    for (final item in _users) {
      if (item.username.toLowerCase() == normalized) {
        user = item;
        break;
      }
    }

    if (user == null || _passwords[normalized] != password) {
      throw const BackendException('Invalid username or password.');
    }

    return AuthResult(token: 'memory-token-${user.id}', user: user);
  }

  @override
  Future<void> logout(String sessionToken) async {}

  @override
  Future<BackendSnapshot> bootstrap(String sessionToken) async {
    return BackendSnapshot(
      users: List.unmodifiable(_users),
      members: List.unmodifiable(_members),
      savingsTransactions: List.unmodifiable(_savingsTransactions),
      loans: List.unmodifiable(_loans),
      repayments: List.unmodifiable(_loans.expand((loan) => loan.repayments)),
      backupRuns: List.unmodifiable(_backupRuns),
    );
  }

  @override
  Future<AppUser> addUser(
    String sessionToken, {
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty || password.trim().isEmpty) {
      throw const BackendException('Unable to save user.');
    }
    if (_users.any(
      (user) => user.username.toLowerCase() == cleanUsername.toLowerCase(),
    )) {
      throw const BackendException('Username already exists.');
    }

    final user = AppUser(
      id: 'u${DateTime.now().microsecondsSinceEpoch}',
      username: cleanUsername,
      displayName: displayName.trim(),
      role: role,
    );
    _users.add(user);
    _passwords[cleanUsername.toLowerCase()] = password.trim();
    return user;
  }

  @override
  Future<AppUser> updateUser(
    String sessionToken, {
    required String id,
    required String displayName,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final index = _users.indexWhere((user) => user.id == id);
    if (index == -1) {
      throw const BackendException('User was not found.');
    }

    final cleanUsername = username.trim();
    if (_users.any(
      (user) =>
          user.id != id &&
          user.username.toLowerCase() == cleanUsername.toLowerCase(),
    )) {
      throw const BackendException('Username already exists.');
    }

    final oldUsername = _users[index].username.toLowerCase();
    final user = _users[index].copyWith(
      username: cleanUsername,
      displayName: displayName.trim(),
      role: role,
    );
    _users[index] = user;
    if (password.trim().isNotEmpty) {
      _passwords.remove(oldUsername);
      _passwords[cleanUsername.toLowerCase()] = password.trim();
    }
    return user;
  }

  @override
  Future<Member> addMember(
    String sessionToken, {
    required String fullName,
    required String address,
    required String phone,
  }) async {
    final nextNumber = _members.length + 1;
    final member = Member(
      id: 'm${DateTime.now().microsecondsSinceEpoch}',
      memberCode: 'PQR-${nextNumber.toString().padLeft(4, '0')}',
      fullName: fullName.trim(),
      address: address.trim(),
      phone: phone.trim(),
      joinedAt: DateTime.now(),
    );
    _members.add(member);
    return member;
  }

  @override
  Future<Member> updateMember(String sessionToken, Member member) async {
    final index = _members.indexWhere((item) => item.id == member.id);
    if (index == -1) {
      throw const BackendException('Member was not found.');
    }
    _members[index] = member;
    return member;
  }

  @override
  Future<void> deleteMember(String sessionToken, String memberId) async {
    _members.removeWhere((member) => member.id == memberId);
    _savingsTransactions.removeWhere(
      (transaction) => transaction.memberId == memberId,
    );
    _loans.removeWhere((loan) => loan.memberId == memberId);
  }

  @override
  Future<SavingsTransaction> recordSavingsTransaction(
    String sessionToken, {
    required String memberId,
    required SavingsTransactionType type,
    required double amount,
    required String note,
  }) async {
    if (type == SavingsTransactionType.withdrawal &&
        amount > _balanceFor(memberId)) {
      throw const BackendException('Withdrawal exceeds account balance.');
    }

    final transaction = SavingsTransaction(
      id: 's${DateTime.now().microsecondsSinceEpoch}',
      memberId: memberId,
      type: type,
      amount: amount,
      date: DateTime.now(),
      note: note.trim().isEmpty ? type.name : note.trim(),
    );
    _savingsTransactions.add(transaction);
    return transaction;
  }

  @override
  Future<Loan> addLoan(
    String sessionToken, {
    required String memberId,
    required double principal,
    required double annualInterestRate,
    required int termMonths,
  }) async {
    final now = DateTime.now();
    final loan = Loan(
      id: 'l${now.microsecondsSinceEpoch}',
      memberId: memberId,
      principal: principal,
      annualInterestRate: annualInterestRate,
      termMonths: termMonths,
      appliedAt: now,
      dueDate: DateTime(now.year, now.month + termMonths, now.day),
      status: LoanStatus.pending,
    );
    _loans.add(loan);
    return loan;
  }

  @override
  Future<Loan> updateLoanStatus(
    String sessionToken, {
    required String loanId,
    required LoanStatus status,
  }) async {
    final index = _loans.indexWhere((loan) => loan.id == loanId);
    if (index == -1) {
      throw const BackendException('Loan was not found.');
    }
    final loan = _loans[index].copyWith(status: status);
    _loans[index] = loan;
    return loan;
  }

  @override
  Future<LoanRepaymentResult> recordLoanPayment(
    String sessionToken, {
    required String loanId,
    required double amount,
    required String note,
  }) async {
    final index = _loans.indexWhere((loan) => loan.id == loanId);
    if (index == -1) {
      throw const BackendException('Loan was not found.');
    }

    final loan = _loans[index];
    if (amount > loan.outstandingBalance) {
      throw const BackendException('Payment exceeds outstanding balance.');
    }

    final repayment = Repayment(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      loanId: loanId,
      amount: amount,
      date: DateTime.now(),
      note: note.trim().isEmpty ? 'Loan repayment' : note.trim(),
    );
    final updated = loan.copyWith(repayments: [...loan.repayments, repayment]);
    final status = updated.outstandingBalance <= 0
        ? LoanStatus.paid
        : LoanStatus.approved;
    final finalLoan = updated.copyWith(status: status);
    _loans[index] = finalLoan;
    return LoanRepaymentResult(loan: finalLoan, repayment: repayment);
  }

  @override
  Future<BackupRun> runBackup(String sessionToken) async {
    final backup = BackupRun(
      id: 'b${DateTime.now().microsecondsSinceEpoch}',
      status: 'completed',
      summary: {
        'total_members': _members.length,
        'active_members': _members
            .where((member) => member.status == MemberStatus.active)
            .length,
        'savings_transactions': _savingsTransactions.length,
        'loans': _loans.length,
        'repayments': _loans.expand((loan) => loan.repayments).length,
      },
      createdAt: DateTime.now(),
    );
    _backupRuns.insert(0, backup);
    return backup;
  }

  double _balanceFor(String memberId) {
    return _savingsTransactions
        .where((transaction) => transaction.memberId == memberId)
        .fold(0, (sum, transaction) => sum + transaction.signedAmount);
  }
}
