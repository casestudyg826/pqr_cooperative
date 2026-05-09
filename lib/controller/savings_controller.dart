import 'package:flutter/foundation.dart';

import '../backend/backend_api.dart';
import '../module/savings_transaction.dart';

class SavingsController extends ChangeNotifier {
  SavingsController(this._backend, this._sessionToken);

  final BackendApi _backend;
  final String Function() _sessionToken;
  final List<SavingsTransaction> _transactions = [];

  List<SavingsTransaction> get transactions =>
      List.unmodifiable(_transactions.reversed);

  void replaceAll(List<SavingsTransaction> transactions) {
    _transactions
      ..clear()
      ..addAll(transactions);
    notifyListeners();
  }

  List<SavingsTransaction> transactionsFor(String memberId) {
    return _transactions.reversed
        .where((transaction) => transaction.memberId == memberId)
        .toList();
  }

  double get totalSavings => _transactions.fold(
    0,
    (sum, transaction) => sum + transaction.signedAmount,
  );

  double balanceFor(String memberId) {
    return _transactions
        .where((transaction) => transaction.memberId == memberId)
        .fold(0, (sum, transaction) => sum + transaction.signedAmount);
  }

  Future<void> recordTransaction({
    required String memberId,
    required SavingsTransactionType type,
    required double amount,
    required String note,
  }) async {
    final transaction = await _backend.recordSavingsTransaction(
      _sessionToken(),
      memberId: memberId,
      type: type,
      amount: amount,
      note: note,
    );
    _transactions.add(transaction);
    notifyListeners();
  }

  void deleteTransactionsForMember(String memberId) {
    _transactions.removeWhere(
      (transaction) => transaction.memberId == memberId,
    );
    notifyListeners();
  }
}
