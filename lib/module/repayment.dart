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
}
