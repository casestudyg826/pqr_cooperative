class Repayment {
  const Repayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final String loanId;
  final double amount;
  final DateTime date;
  final String note;

  factory Repayment.fromJson(Map<String, dynamic> json) {
    return Repayment(
      id: json['id'].toString(),
      loanId: (json['loan_id'] ?? json['loanId']).toString(),
      amount: _toDouble(json['amount']),
      date: DateTime.parse((json['paid_at'] ?? json['date']).toString()),
      note: (json['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'loan_id': loanId,
      'amount': amount,
      'paid_at': date.toIso8601String(),
      'note': note,
    };
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }
}
