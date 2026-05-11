import 'package:flutter/foundation.dart';

import '../backend/backend_api.dart';
import '../module/loan.dart';

class LoanController extends ChangeNotifier {
  LoanController(this._backend, this._sessionToken);

  final BackendApi _backend;
  final String Function() _sessionToken;
  final List<Loan> _loans = [];

  List<Loan> get loans => List.unmodifiable(_loans.reversed);

  void replaceAll(List<Loan> loans) {
    _loans
      ..clear()
      ..addAll(loans);
    notifyListeners();
  }

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

  Future<void> addLoan({
    required String memberId,
    required double principal,
  }) async {
    final loan = await _backend.addLoan(
      _sessionToken(),
      memberId: memberId,
      principal: principal,
    );
    _loans.add(loan);
    notifyListeners();
  }

  Future<void> updateStatus(
    String loanId,
    LoanStatus status, {
    double? annualInterestRate,
    int? termMonths,
  }) async {
    final updated = await _backend.updateLoanStatus(
      _sessionToken(),
      loanId: loanId,
      status: status,
      annualInterestRate: annualInterestRate,
      termMonths: termMonths,
    );
    final index = _loans.indexWhere((loan) => loan.id == loanId);
    if (index == -1) {
      return;
    }
    _loans[index] = updated.copyWith(repayments: _loans[index].repayments);
    notifyListeners();
  }

  Future<void> recordPayment({
    required String loanId,
    required double amount,
    required String note,
  }) async {
    final result = await _backend.recordLoanPayment(
      _sessionToken(),
      loanId: loanId,
      amount: amount,
      note: note,
    );
    final index = _loans.indexWhere((loan) => loan.id == loanId);
    if (index == -1) {
      return;
    }

    final repayments = [..._loans[index].repayments, result.repayment];
    _loans[index] = result.loan.copyWith(repayments: repayments);
    notifyListeners();
  }

  void deleteLoansForMember(String memberId) {
    _loans.removeWhere((loan) => loan.memberId == memberId);
    notifyListeners();
  }
}
