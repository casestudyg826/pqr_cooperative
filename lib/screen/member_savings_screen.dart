import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/savings_transaction.dart';

class MemberSavingsScreen extends StatelessWidget {
  const MemberSavingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final memberId = app.auth.currentUser?.memberId;
    final member = memberId == null ? null : app.members.findById(memberId);
    final transactions = memberId == null
        ? const <SavingsTransaction>[]
        : app.savings.transactionsFor(memberId);
    final balance = memberId == null ? 0.0 : app.savings.balanceFor(memberId);
    final totalDeposits = transactions
        .where((item) => item.type == SavingsTransactionType.contribution)
        .fold<double>(0, (sum, item) => sum + item.amount);
    final totalWithdrawals = transactions
        .where((item) => item.type == SavingsTransactionType.withdrawal)
        .fold<double>(0, (sum, item) => sum + item.amount);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 1080;
        if (!isLargeScreen) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SavingsSummaryCard(
                  memberName: member?.fullName ?? 'Member',
                  memberCode: member?.memberCode ?? '-',
                  balance: balance,
                  totalDeposits: totalDeposits,
                  totalWithdrawals: totalWithdrawals,
                ),
                const SizedBox(height: 16),
                _SavingsHistoryCard(transactions: transactions, compact: true),
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
                child: _SavingsSummaryCard(
                  memberName: member?.fullName ?? 'Member',
                  memberCode: member?.memberCode ?? '-',
                  balance: balance,
                  totalDeposits: totalDeposits,
                  totalWithdrawals: totalWithdrawals,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _SavingsHistoryCard(transactions: transactions)),
            ],
          ),
        );
      },
    );
  }
}

class _SavingsSummaryCard extends StatelessWidget {
  const _SavingsSummaryCard({
    required this.memberName,
    required this.memberCode,
    required this.balance,
    required this.totalDeposits,
    required this.totalWithdrawals,
  });

  final String memberName;
  final String memberCode;
  final double balance;
  final double totalDeposits;
  final double totalWithdrawals;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Savings Balance',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(memberName),
            Text(
              memberCode,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF1EC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available balance'),
                  const SizedBox(height: 4),
                  Text(
                    _money(balance),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SummaryLine(label: 'Total deposits', value: _money(totalDeposits)),
            _SummaryLine(
              label: 'Total withdrawals',
              value: _money(totalWithdrawals),
            ),
            _SummaryLine(
              label: 'Net movement',
              value: _money(totalDeposits - totalWithdrawals),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsHistoryCard extends StatelessWidget {
  const _SavingsHistoryCard({required this.transactions, this.compact = false});

  final List<SavingsTransaction> transactions;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings Transactions',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              const Text('No transactions yet.')
            else if (compact)
              ListView.separated(
                itemCount: transactions.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return _SavingsTransactionTile(transaction: transaction);
                },
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: transactions.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _SavingsTransactionTile(transaction: transaction);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavingsTransactionTile extends StatelessWidget {
  const _SavingsTransactionTile({required this.transaction});

  final SavingsTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isDeposit = transaction.type == SavingsTransactionType.contribution;
    final valueColor = isDeposit
        ? const Color(0xFF1B7B43)
        : const Color(0xFF9B1D1D);
    final prefix = isDeposit ? '+' : '-';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: isDeposit
            ? const Color(0xFFE3F4E8)
            : const Color(0xFFF9E5E5),
        child: Icon(
          isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
          size: 16,
          color: valueColor,
        ),
      ),
      title: Text(transaction.typeLabel),
      subtitle: Text(
        '${_date(transaction.date)}${transaction.note.isEmpty ? '' : ' • ${transaction.note}'}',
      ),
      trailing: Text(
        '$prefix${_money(transaction.amount)}',
        style: TextStyle(fontWeight: FontWeight.w700, color: valueColor),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
