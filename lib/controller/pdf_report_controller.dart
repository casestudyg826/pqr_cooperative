import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../module/loan.dart';
import '../module/report_definition.dart';
import '../module/savings_transaction.dart';
import 'loan_controller.dart';
import 'member_controller.dart';
import 'report_controller.dart';
import 'savings_controller.dart';

class PdfReportController {
  Future<Uint8List> buildReport({
    required ReportDefinition definition,
    required MemberController members,
    required SavingsController savings,
    required LoanController loans,
    required ReportController reports,
  }) async {
    final document = pw.Document();
    final summary = reports.buildSummary(
      members: members,
      savings: savings,
      loans: loans,
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(
            base: pw.Font.helvetica(),
            bold: pw.Font.helveticaBold(),
          ),
        ),
        header: (context) => _header(definition),
        footer: (context) => _footer(context),
        build: (context) {
          switch (definition.type) {
            case ReportType.monthlyFinancialStatement:
              return _monthlyFinancialStatement(summary, savings, loans);
            case ReportType.memberSavingsReport:
              return _memberSavingsReport(members, savings);
            case ReportType.loanPortfolioReport:
              return _loanPortfolioReport(members, loans);
            case ReportType.cdaComplianceReport:
              return _cdaComplianceReport(summary, members, loans);
            case ReportType.membershipActivityReport:
              return _membershipActivityReport(members, savings, loans);
          }
        },
      ),
    );

    return document.save();
  }

  pw.Widget _header(ReportDefinition definition) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'PQR Cooperative',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            definition.title,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Generated ${_dateTime(DateTime.now())}'),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Page ${context.pageNumber} of ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
      ),
    );
  }

  List<pw.Widget> _monthlyFinancialStatement(
    dynamic summary,
    SavingsController savings,
    LoanController loans,
  ) {
    final deposits = savings.transactions
        .where((item) => item.type == SavingsTransactionType.contribution)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final withdrawals = savings.transactions
        .where((item) => item.type == SavingsTransactionType.withdrawal)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final approvedPrincipal = loans.loans
        .where(
          (loan) =>
              loan.status == LoanStatus.approved ||
              loan.status == LoanStatus.paid,
        )
        .fold<double>(0, (sum, loan) => sum + loan.principal);

    return [
      _sectionTitle('Financial Summary'),
      _keyValueTable([
        ['Total deposits', _money(deposits)],
        ['Total withdrawals', _money(withdrawals)],
        ['Net savings balance', _money(summary.totalSavings)],
        ['Loan releases', _money(approvedPrincipal)],
        ['Expected loan interest', _money(summary.totalLoanInterest)],
        ['Repayments collected', _money(summary.totalRepayments)],
        ['Outstanding exposure', _money(summary.outstandingLoans)],
      ]),
      _sectionTitle('Loan Status Counts'),
      _keyValueTable([
        ['Pending loans', '${summary.pendingLoans}'],
        ['Active loans', '${summary.activeLoans}'],
        ['Overdue loans', '${summary.overdueLoans}'],
      ]),
    ];
  }

  List<pw.Widget> _memberSavingsReport(
    MemberController members,
    SavingsController savings,
  ) {
    return [
      _sectionTitle('Member Balances'),
      _table(
        headers: ['Code', 'Member', 'Phone', 'Balance'],
        rows: members.members.map((member) {
          return [
            member.memberCode,
            member.fullName,
            member.phone,
            _money(savings.balanceFor(member.id)),
          ];
        }).toList(),
      ),
      _sectionTitle('Savings Transactions'),
      _table(
        headers: ['Date', 'Member', 'Type', 'Amount', 'Note'],
        rows: savings.transactions.map((transaction) {
          return [
            _date(transaction.date),
            members.nameFor(transaction.memberId),
            transaction.typeLabel,
            _money(transaction.signedAmount),
            transaction.note,
          ];
        }).toList(),
      ),
    ];
  }

  List<pw.Widget> _loanPortfolioReport(
    MemberController members,
    LoanController loans,
  ) {
    return [
      _sectionTitle('Loan Portfolio'),
      _table(
        headers: [
          'Member',
          'Status',
          'Principal',
          'Interest',
          'Paid',
          'Outstanding',
          'Due',
        ],
        rows: loans.loans.map((loan) {
          return [
            members.nameFor(loan.memberId),
            loan.statusLabel,
            _money(loan.principal),
            _money(loan.interest),
            _money(loan.totalPaid),
            _money(loan.outstandingBalance),
            loan.dueDate == null ? 'Not set' : _date(loan.dueDate!),
          ];
        }).toList(),
      ),
      _sectionTitle('Repayment History'),
      _table(
        headers: ['Date', 'Member', 'Loan ID', 'Amount', 'Note'],
        rows: loans.loans.expand((loan) {
          return loan.repayments.map((repayment) {
            return [
              _date(repayment.date),
              members.nameFor(loan.memberId),
              loan.id,
              _money(repayment.amount),
              repayment.note,
            ];
          });
        }).toList(),
      ),
    ];
  }

  List<pw.Widget> _cdaComplianceReport(
    dynamic summary,
    MemberController members,
    LoanController loans,
  ) {
    return [
      _sectionTitle('Compliance Snapshot'),
      _keyValueTable([
        ['Registered members', '${summary.totalMembers}'],
        ['Active members', '${summary.activeMembers}'],
        ['Inactive members', '${summary.totalMembers - summary.activeMembers}'],
        ['Pending loan applications', '${summary.pendingLoans}'],
        ['Active loans', '${summary.activeLoans}'],
        ['Overdue loans', '${summary.overdueLoans}'],
        ['Total savings', _money(summary.totalSavings)],
        ['Outstanding loan exposure', _money(summary.outstandingLoans)],
      ]),
      _sectionTitle('Submission Notes'),
      pw.Bullet(text: 'Generated from the current cooperative records.'),
      pw.Bullet(
        text:
            'No online banking or external financial integration is included.',
      ),
      pw.Bullet(
        text: 'Figures depend on staff-entered member, savings, and loan data.',
      ),
      _sectionTitle('Member Register'),
      _table(
        headers: ['Code', 'Member', 'Status', 'Joined'],
        rows: members.members.map((member) {
          return [
            member.memberCode,
            member.fullName,
            member.status.name,
            _date(member.joinedAt),
          ];
        }).toList(),
      ),
    ];
  }

  List<pw.Widget> _membershipActivityReport(
    MemberController members,
    SavingsController savings,
    LoanController loans,
  ) {
    return [
      _sectionTitle('Membership Activity'),
      _table(
        headers: ['Code', 'Member', 'Status', 'Joined', 'Savings', 'Loans'],
        rows: members.members.map((member) {
          final memberLoans = loans.loans
              .where((loan) => loan.memberId == member.id)
              .length;
          return [
            member.memberCode,
            member.fullName,
            member.status.name,
            _date(member.joinedAt),
            _money(savings.balanceFor(member.id)),
            '$memberLoans',
          ];
        }).toList(),
      ),
    ];
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 18, bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _keyValueTable(List<List<String>> rows) {
    return _table(headers: ['Metric', 'Value'], rows: rows);
  }

  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows.isEmpty ? [List.filled(headers.length, 'No records')] : rows,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFF235347),
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    );
  }

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';

  static String _date(DateTime value) {
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  static String _dateTime(DateTime value) {
    final date = _date(value);
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
