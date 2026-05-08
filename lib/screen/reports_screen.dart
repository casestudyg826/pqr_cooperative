import 'package:flutter/material.dart';

import '../controller/app_controller.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final summary = app.reports.buildSummary(
      members: app.members,
      savings: app.savings,
      loans: app.loans,
    );
    final exposure = app.reports.loanExposureByStatus(app.loans);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generated from current local member, savings, and loan records.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 900;
              final financial = _ReportCard(
                title: 'Financial Summary',
                rows: [
                  _ReportRow('Total savings', _money(summary.totalSavings)),
                  _ReportRow(
                    'Loan principal',
                    _money(summary.totalLoanPrincipal),
                  ),
                  _ReportRow(
                    'Expected interest',
                    _money(summary.totalLoanInterest),
                  ),
                  _ReportRow(
                    'Repayments collected',
                    _money(summary.totalRepayments),
                  ),
                  _ReportRow(
                    'Outstanding exposure',
                    _money(summary.outstandingLoans),
                  ),
                ],
              );
              final compliance = _ReportCard(
                title: 'CDA Compliance Snapshot',
                rows: [
                  _ReportRow('Registered members', '${summary.totalMembers}'),
                  _ReportRow('Active members', '${summary.activeMembers}'),
                  _ReportRow(
                    'Pending loan applications',
                    '${summary.pendingLoans}',
                  ),
                  _ReportRow('Active loans', '${summary.activeLoans}'),
                  _ReportRow('Overdue loans', '${summary.overdueLoans}'),
                ],
              );

              if (!isWide) {
                return Column(
                  children: [financial, const SizedBox(height: 16), compliance],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: financial),
                  const SizedBox(width: 16),
                  Expanded(child: compliance),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _ReportCard(
            title: 'Loan Exposure by Status',
            rows: [
              for (final entry in exposure.entries)
                _ReportRow(_title(entry.key), _money(entry.value)),
            ],
          ),
          const SizedBox(height: 16),
          _ReportCard(
            title: 'Report Notes',
            rows: const [
              _ReportRow('Storage mode', 'Local in-memory prototype'),
              _ReportRow('External banking integration', 'Not included'),
              _ReportRow('Backup', 'Simulated from backup screen'),
              _ReportRow('Data quality', 'Depends on staff-entered records'),
            ],
          ),
        ],
      ),
    );
  }

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
  static String _title(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.rows});

  final String title;
  final List<_ReportRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 7),
                child: Row(
                  children: [
                    Expanded(child: Text(row.label)),
                    const SizedBox(width: 12),
                    Text(
                      row.value,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReportRow {
  const _ReportRow(this.label, this.value);

  final String label;
  final String value;
}
