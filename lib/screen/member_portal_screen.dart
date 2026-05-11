import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/loan.dart';

class MemberPortalScreen extends StatefulWidget {
  const MemberPortalScreen({super.key});

  @override
  State<MemberPortalScreen> createState() => _MemberPortalScreenState();
}

class _MemberPortalScreenState extends State<MemberPortalScreen> {
  final _principalController = TextEditingController();

  @override
  void dispose() {
    _principalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.auth.currentUser!;
    final memberId = user.memberId;
    final member = memberId == null ? null : app.members.findById(memberId);
    final loans = memberId == null
        ? <Loan>[]
        : app.loans.loansForMember(memberId);
    final savingsBalance = memberId == null
        ? 0.0
        : app.savings.balanceFor(memberId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(member == null ? user.displayName : member.fullName),
          const SizedBox(height: 20),
          _BalanceCard(balance: savingsBalance),
          const SizedBox(height: 16),
          _LoanApplicationCard(
            principalController: _principalController,
            onSubmit: () => _applyLoan(memberId),
          ),
          const SizedBox(height: 16),
          _MyLoansCard(loans: loans),
        ],
      ),
    );
  }

  Future<void> _applyLoan(String? memberId) async {
    if (memberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member account is not linked.')),
      );
      return;
    }

    final principal = double.tryParse(_principalController.text.trim());
    if (principal == null || principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid loan amount.')),
      );
      return;
    }

    try {
      await AppScope.of(
        context,
      ).loans.addLoan(memberId: memberId, principal: principal);
      _principalController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final double balance;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings Balance',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              _money(balance),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoanApplicationCard extends StatelessWidget {
  const _LoanApplicationCard({
    required this.principalController,
    required this.onSubmit,
  });

  final TextEditingController principalController;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Apply for a Loan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the amount you need. The loan terms are added after staff review.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: principalController,
              decoration: const InputDecoration(
                labelText: 'Requested amount',
                prefixText: 'PHP ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.send),
              label: const Text('Submit application'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyLoansCard extends StatelessWidget {
  const _MyLoansCard({required this.loans});

  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    final pending = loans
        .where((loan) => loan.status == LoanStatus.pending)
        .toList();
    final approved = loans
        .where(
          (loan) =>
              loan.status == LoanStatus.approved && loan.outstandingBalance > 0,
        )
        .toList();
    final closed = loans
        .where(
          (loan) =>
              loan.status == LoanStatus.paid ||
              loan.status == LoanStatus.rejected,
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'My Loan Applications',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _LoanGroup(title: 'Pending review', loans: pending),
            const SizedBox(height: 12),
            _LoanGroup(title: 'Approved', loans: approved),
            const SizedBox(height: 12),
            _LoanGroup(title: 'Closed', loans: closed),
          ],
        ),
      ),
    );
  }
}

class _LoanGroup extends StatelessWidget {
  const _LoanGroup({required this.title, required this.loans});

  final String title;
  final List<Loan> loans;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (loans.isEmpty)
          const Text('No records.')
        else
          for (final loan in loans)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('${loan.statusLabel} • ${_money(loan.principal)}'),
              subtitle: Text(
                loan.dueDate == null
                    ? 'Awaiting approval'
                    : 'Due ${_date(loan.dueDate!)}',
              ),
              trailing: Text(_money(loan.outstandingBalance)),
            ),
      ],
    );
  }
}

String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
