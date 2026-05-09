import 'package:flutter/foundation.dart';

import '../module/loan.dart';
import '../module/repayment.dart';

class LoanController extends ChangeNotifier {
  final List<Loan> _loans = [
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

  List<Loan> get loans => List.unmodifiable(_loans.reversed);
  List<Loan> loansForMember(String memberId) {
    return _loans.reversed.where((loan) => loan.memberId == memberId).toList();
  }

  int get pendingCount =>
      _loans.where((loan) => loan.status == LoanStatus.pending).length;
  int get activeCount => _loans
      .where(
        (loan) =>
            loan.status == LoanStatus.approved && loan.outstandingBalance > 0,
      )
      .length;
  int get overdueCount => _loans.where((loan) => loan.isOverdue).length;
  double get totalPrincipal =>
      _loans.fold(0, (sum, loan) => sum + loan.principal);
  double get totalInterest =>
      _loans.fold(0, (sum, loan) => sum + loan.interest);
  double get totalRepayments =>
      _loans.fold(0, (sum, loan) => sum + loan.totalPaid);

  void addLoan({
    required String memberId,
    required double principal,
    required double annualInterestRate,
    required int termMonths,
  }) {
    final now = DateTime.now();
    _loans.add(
      Loan(
        id: 'l${now.microsecondsSinceEpoch}',
        memberId: memberId,
        principal: principal,
        annualInterestRate: annualInterestRate,
        termMonths: termMonths,
        appliedAt: now,
        dueDate: DateTime(now.year, now.month + termMonths, now.day),
        status: LoanStatus.pending,
      ),
    );
    notifyListeners();
  }

  void updateStatus(String loanId, LoanStatus status) {
    final index = _loans.indexWhere((loan) => loan.id == loanId);
    if (index == -1) {
      return;
    }
    _loans[index] = _loans[index].copyWith(status: status);
    notifyListeners();
  }

  void recordPayment({
    required String loanId,
    required double amount,
    required String note,
  }) {
    final index = _loans.indexWhere((loan) => loan.id == loanId);
    if (index == -1) {
      return;
    }

    final loan = _loans[index];
    final repayment = Repayment(
      id: 'r${DateTime.now().microsecondsSinceEpoch}',
      loanId: loanId,
      amount: amount,
      date: DateTime.now(),
      note: note.trim().isEmpty ? 'Loan repayment' : note.trim(),
    );
    final repayments = [...loan.repayments, repayment];
    final updatedLoan = loan.copyWith(repayments: repayments);
    final status = updatedLoan.outstandingBalance <= 0
        ? LoanStatus.paid
        : LoanStatus.approved;
    _loans[index] = updatedLoan.copyWith(status: status);
    notifyListeners();
  }

  void deleteLoansForMember(String memberId) {
    _loans.removeWhere((loan) => loan.memberId == memberId);
    notifyListeners();
  }
}
