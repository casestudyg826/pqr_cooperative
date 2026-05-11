import 'repayment.dart';

enum LoanStatus { pending, approved, paid, rejected }

class Loan {
  const Loan({
    required this.id,
    required this.memberId,
    required this.principal,
    this.annualInterestRate,
    this.termMonths,
    required this.appliedAt,
    this.dueDate,
    this.approvedAt,
    required this.status,
    this.repayments = const [],
  });

  final String id;
  final String memberId;
  final double principal;
  final double? annualInterestRate;
  final int? termMonths;
  final DateTime appliedAt;
  final DateTime? dueDate;
  final DateTime? approvedAt;
  final LoanStatus status;
  final List<Repayment> repayments;

  double get interest {
    if (annualInterestRate == null || termMonths == null) {
      return 0;
    }
    return principal * annualInterestRate! * (termMonths! / 12);
  }

  double get totalPayable => principal + interest;
  double get totalPaid => repayments.fold(0, (sum, item) => sum + item.amount);
  double get outstandingBalance {
    final balance = totalPayable - totalPaid;
    return balance < 0 ? 0 : balance;
  }

  bool get isOverdue {
    return status == LoanStatus.approved &&
        outstandingBalance > 0 &&
        dueDate != null &&
        dueDate!.isBefore(DateTime.now());
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

  Loan copyWith({
    LoanStatus? status,
    List<Repayment>? repayments,
    double? annualInterestRate,
    int? termMonths,
    DateTime? dueDate,
    DateTime? approvedAt,
  }) {
    return Loan(
      id: id,
      memberId: memberId,
      principal: principal,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      termMonths: termMonths ?? this.termMonths,
      appliedAt: appliedAt,
      dueDate: dueDate ?? this.dueDate,
      approvedAt: approvedAt ?? this.approvedAt,
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
      annualInterestRate: _toNullableDouble(
        json['annual_interest_rate'] ?? json['annualInterestRate'],
      ),
      termMonths: _toNullableInt(json['term_months'] ?? json['termMonths']),
      appliedAt: DateTime.parse(
        (json['applied_at'] ?? json['appliedAt']).toString(),
      ),
      dueDate: _toNullableDate(json['due_date'] ?? json['dueDate']),
      approvedAt: _toNullableDate(json['approved_at'] ?? json['approvedAt']),
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
      'due_date': dueDate?.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
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

  static double? _toNullableDouble(Object? value) {
    if (value == null) {
      return null;
    }
    return _toDouble(value);
  }

  static int? _toNullableInt(Object? value) {
    if (value == null) {
      return null;
    }
    return _toInt(value);
  }

  static DateTime? _toNullableDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.parse(value.toString());
  }
}
