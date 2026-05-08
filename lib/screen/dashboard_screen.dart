import 'package:flutter/material.dart';

import '../controller/app_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final summary = app.reports.buildSummary(
      members: app.members,
      savings: app.savings,
      loans: app.loans,
    );
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 960;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operational overview',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Monitor membership, savings balances, loans, and overdue accounts.',
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 12.0;
              final columns = constraints.maxWidth >= 1200
                  ? 5
                  : constraints.maxWidth >= 760
                  ? 3
                  : 1;
              final cardWidth =
                  (constraints.maxWidth - (spacing * (columns - 1))) / columns;
              final metrics = [
                _DashboardMetric(
                  title: 'Total Members',
                  value: '${summary.totalMembers}',
                  icon: Icons.groups,
                ),
                _DashboardMetric(
                  title: 'Total Savings',
                  value: _money(summary.totalSavings),
                  icon: Icons.savings,
                ),
                _DashboardMetric(
                  title: 'Active Loans',
                  value: '${summary.activeLoans}',
                  icon: Icons.assignment_turned_in,
                ),
                _DashboardMetric(
                  title: 'Pending Loans',
                  value: '${summary.pendingLoans}',
                  icon: Icons.hourglass_top,
                ),
                _DashboardMetric(
                  title: 'Overdue Payments',
                  value: '${summary.overdueLoans}',
                  icon: Icons.warning_amber,
                ),
              ];

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final metric in metrics)
                    SizedBox(
                      width: cardWidth,
                      child: _SummaryCard(
                        title: metric.title,
                        value: metric.value,
                        icon: metric.icon,
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 900;
              final savingsPanel = _ActivityPanel(
                title: 'Recent Savings Activity',
                compact: isDesktop,
                children: app.savings.transactions.take(4).map((transaction) {
                  return ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -2),
                    minVerticalPadding: 0,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      transaction.signedAmount >= 0
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                    ),
                    title: Text(app.members.nameFor(transaction.memberId)),
                    subtitle: Text(transaction.typeLabel),
                    trailing: Text(_money(transaction.signedAmount)),
                  );
                }).toList(),
              );
              final loanPanel = _ActivityPanel(
                title: 'Loan Queue',
                compact: isDesktop,
                children: app.loans.loans.take(4).map((loan) {
                  return ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -2),
                    minVerticalPadding: 0,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.request_quote_outlined),
                    title: Text(app.members.nameFor(loan.memberId)),
                    subtitle: Text(loan.statusLabel),
                    trailing: Text(_money(loan.outstandingBalance)),
                  );
                }).toList(),
              );

              if (!twoColumns) {
                return Column(
                  children: [
                    savingsPanel,
                    const SizedBox(height: 16),
                    loanPanel,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: savingsPanel),
                  const SizedBox(width: 16),
                  Expanded(child: loanPanel),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFE8EFE9),
              foregroundColor: const Color(0xFF235347),
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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

class _DashboardMetric {
  const _DashboardMetric({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({
    required this.title,
    required this.children,
    this.compact = false,
  });

  final String title;
  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: compact ? 4 : 8),
            if (children.isEmpty)
              const Text('No activity yet.')
            else
              ...children,
          ],
        ),
      ),
    );
  }
}
