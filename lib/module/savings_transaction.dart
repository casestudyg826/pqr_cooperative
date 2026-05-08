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
}
