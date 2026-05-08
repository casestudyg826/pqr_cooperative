import 'repayment.dart';

enum LoanStatus { pending, approved, paid, rejected }

class Loan {
  const Loan({
    required this.id,
    required this.memberId,
    required this.principal,
    required this.annualInterestRate,
    required this.termMonths,
    required this.appliedAt,
    required this.dueDate,
    required this.status,
    this.repayments = const [],
  });

  final String id;
  final String memberId;
  final double principal;
  final double annualInterestRate;
  final int termMonths;
  final DateTime appliedAt;
  final DateTime dueDate;
  final LoanStatus status;
  final List<Repayment> repayments;

  double get interest => principal * annualInterestRate * (termMonths / 12);
  double get totalPayable => principal + interest;
  double get totalPaid => repayments.fold(0, (sum, item) => sum + item.amount);
  double get outstandingBalance {
    final balance = totalPayable - totalPaid;
    return balance < 0 ? 0 : balance;
  }

  bool get isOverdue {
    return status == LoanStatus.approved &&
        outstandingBalance > 0 &&
        dueDate.isBefore(DateTime.now());
  }

  String get statusLabel {
    switch (status) {
      case LoanStatus.pending:
        return 'Pending';
      case LoanStatus.approved:
        return 'Approved';
      case LoanStatus.paid:
        return 'Paid';
      case LoanStatus.rejected:
        return 'Rejected';
    }
  }

  Loan copyWith({LoanStatus? status, List<Repayment>? repayments}) {
    return Loan(
      id: id,
      memberId: memberId,
      principal: principal,
      annualInterestRate: annualInterestRate,
      termMonths: termMonths,
      appliedAt: appliedAt,
      dueDate: dueDate,
      status: status ?? this.status,
      repayments: repayments ?? this.repayments,
    );
  }
}
