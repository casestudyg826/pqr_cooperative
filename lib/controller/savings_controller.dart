import 'package:flutter/foundation.dart';

import '../module/savings_transaction.dart';

class SavingsController extends ChangeNotifier {
  final List<SavingsTransaction> _transactions = [
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
  ];

  List<SavingsTransaction> get transactions =>
      List.unmodifiable(_transactions.reversed);

  double get totalSavings => _transactions.fold(
    0,
    (sum, transaction) => sum + transaction.signedAmount,
  );

  double balanceFor(String memberId) {
    return _transactions
        .where((transaction) => transaction.memberId == memberId)
        .fold(0, (sum, transaction) => sum + transaction.signedAmount);
  }

  void recordTransaction({
    required String memberId,
    required SavingsTransactionType type,
    required double amount,
    required String note,
  }) {
    _transactions.add(
      SavingsTransaction(
        id: 's${DateTime.now().microsecondsSinceEpoch}',
        memberId: memberId,
        type: type,
        amount: amount,
        date: DateTime.now(),
        note: note.trim().isEmpty ? type.name : note.trim(),
      ),
    );
    notifyListeners();
  }
}
