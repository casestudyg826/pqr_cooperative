import '../module/loan.dart';
import '../module/member.dart';
import '../module/report_summary.dart';
import 'loan_controller.dart';
import 'member_controller.dart';
import 'savings_controller.dart';

class ReportController {
  ReportSummary buildSummary({
    required MemberController members,
    required SavingsController savings,
    required LoanController loans,
  }) {
    return ReportSummary(
      totalMembers: members.members.length,
      activeMembers: members.activeCount,
      totalSavings: savings.totalSavings,
      totalLoanPrincipal: loans.totalPrincipal,
      totalLoanInterest: loans.totalInterest,
      totalRepayments: loans.totalRepayments,
      pendingLoans: loans.pendingCount,
      activeLoans: loans.activeCount,
      overdueLoans: loans.overdueCount,
    );
  }

  Map<String, double> loanExposureByStatus(LoanController loans) {
    final values = <String, double>{};
    for (final status in LoanStatus.values) {
      values[status.name] = 0;
    }
    for (final loan in loans.loans) {
      values[loan.status.name] =
          (values[loan.status.name] ?? 0) + loan.outstandingBalance;
    }
    return values;
  }

  List<Member> activeMembers(MemberController members) {
    return members.members
        .where((member) => member.status == MemberStatus.active)
        .toList();
  }
}
