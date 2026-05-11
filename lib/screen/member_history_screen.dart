import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../controller/app_controller.dart';
import '../module/loan.dart';
import '../module/savings_transaction.dart';

class MemberHistoryScreen extends StatefulWidget {
  const MemberHistoryScreen({super.key});

  @override
  State<MemberHistoryScreen> createState() => _MemberHistoryScreenState();
}

class _MemberHistoryScreenState extends State<MemberHistoryScreen> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final memberId = app.auth.currentUser?.memberId;
    final member = memberId == null ? null : app.members.findById(memberId);
    final savingsTransactions = memberId == null
        ? const <SavingsTransaction>[]
        : app.savings.transactionsFor(memberId);
    final loans = memberId == null
        ? const <Loan>[]
        : app.loans.loansForMember(memberId);
    final entries = _historyEntries(savingsTransactions, loans);
    final isLargeScreen = MediaQuery.sizeOf(context).width >= 1080;

    if (!isLargeScreen) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MemberHistoryInfoCard(
              memberName: member?.fullName ?? 'Member',
              memberCode: member?.memberCode ?? '-',
              transactionCount: savingsTransactions.length,
              loanCount: loans.length,
              isExporting: _isExporting,
              onExport: member == null
                  ? null
                  : () => _export(
                      member.fullName,
                      member.memberCode,
                      savingsTransactions,
                      loans,
                    ),
            ),
            const SizedBox(height: 16),
            _MemberHistoryTimelineCard(entries: entries, compact: true),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 360,
            child: _MemberHistoryInfoCard(
              memberName: member?.fullName ?? 'Member',
              memberCode: member?.memberCode ?? '-',
              transactionCount: savingsTransactions.length,
              loanCount: loans.length,
              isExporting: _isExporting,
              onExport: member == null
                  ? null
                  : () => _export(
                      member.fullName,
                      member.memberCode,
                      savingsTransactions,
                      loans,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(child: _MemberHistoryTimelineCard(entries: entries)),
        ],
      ),
    );
  }

  Future<void> _export(
    String memberName,
    String memberCode,
    List<SavingsTransaction> savingsTransactions,
    List<Loan> loans,
  ) async {
    setState(() => _isExporting = true);
    try {
      final bytes = await AppScope.of(context).pdfReports
          .buildMemberTransactionsReport(
            memberName: memberName,
            memberCode: memberCode,
            savingsTransactions: savingsTransactions,
            loans: loans,
          );
      await Printing.sharePdf(
        bytes: bytes,
        filename:
            '${memberCode.toLowerCase()}-transactions-${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transactions exported to PDF.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to export PDF: $error')));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}

class _MemberHistoryInfoCard extends StatelessWidget {
  const _MemberHistoryInfoCard({
    required this.memberName,
    required this.memberCode,
    required this.transactionCount,
    required this.loanCount,
    required this.isExporting,
    required this.onExport,
  });

  final String memberName;
  final String memberCode;
  final int transactionCount;
  final int loanCount;
  final bool isExporting;
  final VoidCallback? onExport;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Personal History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(memberName),
            Text(
              memberCode,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            _HistoryMetric(
              label: 'Savings transactions',
              value: '$transactionCount',
            ),
            _HistoryMetric(label: 'Loan applications', value: '$loanCount'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: isExporting ? null : onExport,
              icon: isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(
                isExporting ? 'Exporting...' : 'Export Transactions PDF',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberHistoryTimelineCard extends StatelessWidget {
  const _MemberHistoryTimelineCard({
    required this.entries,
    this.compact = false,
  });

  final List<_HistoryEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = entries.isEmpty
        ? const Center(child: Text('No history records yet.'))
        : ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(entry.icon, color: const Color(0xFF235347)),
                title: Text(entry.title),
                subtitle: Text('${_date(entry.date)} • ${entry.detail}'),
                trailing: entry.amountLabel == null
                    ? null
                    : Text(
                        entry.amountLabel!,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
              );
            },
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Activity Timeline',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (compact)
              SizedBox(height: 420, child: content)
            else
              Expanded(child: content),
          ],
        ),
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _HistoryEntry {
  const _HistoryEntry({
    required this.date,
    required this.title,
    required this.detail,
    required this.icon,
    this.amountLabel,
  });

  final DateTime date;
  final String title;
  final String detail;
  final IconData icon;
  final String? amountLabel;
}

List<_HistoryEntry> _historyEntries(
  List<SavingsTransaction> savingsTransactions,
  List<Loan> loans,
) {
  final entries = <_HistoryEntry>[
    for (final transaction in savingsTransactions)
      _HistoryEntry(
        date: transaction.date,
        title: transaction.typeLabel,
        detail: transaction.note.isEmpty
            ? 'Savings transaction'
            : transaction.note,
        icon: transaction.type == SavingsTransactionType.contribution
            ? Icons.arrow_downward
            : Icons.arrow_upward,
        amountLabel:
            '${transaction.type == SavingsTransactionType.contribution ? '+' : '-'}${_money(transaction.amount)}',
      ),
  ];

  for (final loan in loans) {
    entries.add(
      _HistoryEntry(
        date: loan.appliedAt,
        title: 'Loan application submitted',
        detail: loan.termMonths == null
            ? loan.statusLabel
            : 'Requested ${loan.termMonths} months',
        icon: Icons.request_quote_outlined,
        amountLabel: _money(loan.principal),
      ),
    );
    if (loan.approvedAt != null) {
      entries.add(
        _HistoryEntry(
          date: loan.approvedAt!,
          title: 'Loan approved',
          detail: loan.termMonths == null
              ? 'Terms set by staff'
              : '${loan.termMonths} months approved',
          icon: Icons.check_circle_outline,
          amountLabel: _money(loan.totalPayable),
        ),
      );
    }
    if (loan.status == LoanStatus.rejected) {
      entries.add(
        _HistoryEntry(
          date: loan.appliedAt,
          title: 'Loan rejected',
          detail: 'Application did not pass review',
          icon: Icons.cancel_outlined,
          amountLabel: _money(loan.principal),
        ),
      );
    }
    for (final repayment in loan.repayments) {
      entries.add(
        _HistoryEntry(
          date: repayment.date,
          title: 'Loan repayment',
          detail: repayment.note.isEmpty ? 'Payment posted' : repayment.note,
          icon: Icons.payments_outlined,
          amountLabel: _money(repayment.amount),
        ),
      );
    }
  }

  entries.sort((left, right) => right.date.compareTo(left.date));
  return entries;
}

String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
