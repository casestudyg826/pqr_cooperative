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

  factory Loan.fromJson(
    Map<String, dynamic> json, {
    List<Repayment> repayments = const [],
  }) {
    return Loan(
      id: json['id'].toString(),
      memberId: (json['member_id'] ?? json['memberId']).toString(),
      principal: _toDouble(json['principal']),
      annualInterestRate: _toDouble(
        json['annual_interest_rate'] ?? json['annualInterestRate'],
      ),
      termMonths: _toInt(json['term_months'] ?? json['termMonths']),
      appliedAt: DateTime.parse(
        (json['applied_at'] ?? json['appliedAt']).toString(),
      ),
      dueDate: DateTime.parse((json['due_date'] ?? json['dueDate']).toString()),
      status: _statusFromJson(json['status']),
      repayments: repayments,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'principal': principal,
      'annual_interest_rate': annualInterestRate,
      'term_months': termMonths,
      'applied_at': appliedAt.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'status': status.name,
      'repayments': repayments.map((repayment) => repayment.toJson()).toList(),
    };
  }

  static LoanStatus _statusFromJson(Object? value) {
    switch (value?.toString()) {
      case 'pending':
        return LoanStatus.pending;
      case 'approved':
        return LoanStatus.approved;
      case 'paid':
        return LoanStatus.paid;
      case 'rejected':
        return LoanStatus.rejected;
    }
    throw FormatException('Unknown loan status: $value');
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.parse(value.toString());
  }
}
