class ReportSummary {
  const ReportSummary({
    required this.totalMembers,
    required this.activeMembers,
    required this.totalSavings,
    required this.totalLoanPrincipal,
    required this.totalLoanInterest,
    required this.totalRepayments,
    required this.pendingLoans,
    required this.activeLoans,
    required this.overdueLoans,
  });

  final int totalMembers;
  final int activeMembers;
  final double totalSavings;
  final double totalLoanPrincipal;
  final double totalLoanInterest;
  final double totalRepayments;
  final int pendingLoans;
  final int activeLoans;
  final int overdueLoans;

  double get outstandingLoans {
    final value = totalLoanPrincipal + totalLoanInterest - totalRepayments;
    return value < 0 ? 0 : value;
  }
}
