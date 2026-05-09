enum SavingsTransactionType { contribution, withdrawal }

class SavingsTransaction {
  const SavingsTransaction({
    required this.id,
    required this.memberId,
    required this.type,
    required this.amount,
    required this.date,
    required this.note,
  });

  final String id;
  final String memberId;
  final SavingsTransactionType type;
  final double amount;
  final DateTime date;
  final String note;

  double get signedAmount {
    switch (type) {
      case SavingsTransactionType.contribution:
        return amount;
      case SavingsTransactionType.withdrawal:
        return -amount;
    }
  }

  String get typeLabel {
    switch (type) {
      case SavingsTransactionType.contribution:
        return 'Contribution';
      case SavingsTransactionType.withdrawal:
        return 'Withdrawal';
    }
  }

  factory SavingsTransaction.fromJson(Map<String, dynamic> json) {
    return SavingsTransaction(
      id: json['id'].toString(),
      memberId: (json['member_id'] ?? json['memberId']).toString(),
      type: _typeFromJson(json['type']),
      amount: _toDouble(json['amount']),
      date: DateTime.parse((json['occurred_at'] ?? json['date']).toString()),
      note: (json['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_id': memberId,
      'type': type.name,
      'amount': amount,
      'occurred_at': date.toIso8601String(),
      'note': note,
    };
  }

  static SavingsTransactionType _typeFromJson(Object? value) {
    switch (value?.toString()) {
      case 'contribution':
        return SavingsTransactionType.contribution;
      case 'withdrawal':
        return SavingsTransactionType.withdrawal;
    }
    throw FormatException('Unknown savings transaction type: $value');
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.parse(value.toString());
  }
}
