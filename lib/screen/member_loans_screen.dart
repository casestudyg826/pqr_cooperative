import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/loan.dart';

class MemberLoansScreen extends StatefulWidget {
  const MemberLoansScreen({super.key});

  @override
  State<MemberLoansScreen> createState() => _MemberLoansScreenState();
}

class _MemberLoansScreenState extends State<MemberLoansScreen> {
  final _principalController = TextEditingController();
  int _selectedTermMonths = 12;
  _MemberLoanFilter _filter = _MemberLoanFilter.all;

  @override
  void dispose() {
    _principalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final memberId = app.auth.currentUser?.memberId;
    final loans = memberId == null
        ? const <Loan>[]
        : app.loans.loansForMember(memberId);
    final filteredLoans = loans.where((loan) => _filter.matches(loan)).toList();
    final isLargeScreen = MediaQuery.sizeOf(context).width >= 1080;

    if (!isLargeScreen) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MemberLoanSidebar(
              loans: loans,
              principalController: _principalController,
              selectedTermMonths: _selectedTermMonths,
              onTermChanged: (value) =>
                  setState(() => _selectedTermMonths = value),
              onSubmit: () => _submit(memberId),
            ),
            const SizedBox(height: 16),
            _MemberLoanList(
              loans: filteredLoans,
              filter: _filter,
              compact: true,
              onFilterChanged: (value) => setState(() => _filter = value),
            ),
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
            width: 380,
            child: _MemberLoanSidebar(
              loans: loans,
              principalController: _principalController,
              selectedTermMonths: _selectedTermMonths,
              onTermChanged: (value) =>
                  setState(() => _selectedTermMonths = value),
              onSubmit: () => _submit(memberId),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _MemberLoanList(
              loans: filteredLoans,
              filter: _filter,
              onFilterChanged: (value) => setState(() => _filter = value),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(String? memberId) async {
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
      await AppScope.of(context).loans.addLoan(
        memberId: memberId,
        principal: principal,
        termMonths: _selectedTermMonths,
      );
      _principalController.clear();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan application submitted.')),
      );
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

class _MemberLoanSidebar extends StatelessWidget {
  const _MemberLoanSidebar({
    required this.loans,
    required this.principalController,
    required this.selectedTermMonths,
    required this.onTermChanged,
    required this.onSubmit,
  });

  final List<Loan> loans;
  final TextEditingController principalController;
  final int selectedTermMonths;
  final ValueChanged<int> onTermChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final pendingCount = loans
        .where((item) => item.status == LoanStatus.pending)
        .length;
    final approvedCount = loans
        .where((item) => item.status == LoanStatus.approved)
        .length;
    final closedCount = loans
        .where(
          (item) =>
              item.status == LoanStatus.paid ||
              item.status == LoanStatus.rejected,
        )
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Loans',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text('Apply and monitor approval status here.'),
            const SizedBox(height: 16),
            _StatusPill(label: 'Pending review', count: pendingCount),
            const SizedBox(height: 8),
            _StatusPill(label: 'Approved', count: approvedCount),
            const SizedBox(height: 8),
            _StatusPill(label: 'Closed', count: closedCount),
            const SizedBox(height: 20),
            TextField(
              controller: principalController,
              decoration: const InputDecoration(
                labelText: 'Requested amount',
                prefixText: 'PHP ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: selectedTermMonths,
              decoration: const InputDecoration(labelText: 'Preferred term'),
              items: [
                for (final month in <int>[3, 6, 9, 12, 18, 24, 36, 48, 60])
                  DropdownMenuItem(value: month, child: Text('$month months')),
              ],
              onChanged: (value) {
                if (value != null) {
                  onTermChanged(value);
                }
              },
            ),
            const SizedBox(height: 16),
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

class _MemberLoanList extends StatelessWidget {
  const _MemberLoanList({
    required this.loans,
    required this.filter,
    required this.onFilterChanged,
    this.compact = false,
  });

  final List<Loan> loans;
  final _MemberLoanFilter filter;
  final ValueChanged<_MemberLoanFilter> onFilterChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = loans.isEmpty
        ? const Center(child: Text('No loan records for this filter.'))
        : ListView.separated(
            itemCount: loans.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final loan = loans[index];
              return _MemberLoanTile(loan: loan);
            },
          );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan Status',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_MemberLoanFilter>(
              segments: const [
                ButtonSegment(value: _MemberLoanFilter.all, label: Text('All')),
                ButtonSegment(
                  value: _MemberLoanFilter.pending,
                  label: Text('Pending'),
                ),
                ButtonSegment(
                  value: _MemberLoanFilter.approved,
                  label: Text('Approved'),
                ),
                ButtonSegment(
                  value: _MemberLoanFilter.closed,
                  label: Text('Closed'),
                ),
              ],
              selected: {filter},
              onSelectionChanged: (selected) => onFilterChanged(selected.first),
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

class _MemberLoanTile extends StatelessWidget {
  const _MemberLoanTile({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _LoanStatusIcon(status: loan.status),
      title: Text('${loan.statusLabel} • ${_money(loan.principal)}'),
      subtitle: Text(
        [
          'Applied ${_date(loan.appliedAt)}',
          if (loan.termMonths != null) 'Requested ${loan.termMonths} months',
          if (loan.dueDate != null) 'Due ${_date(loan.dueDate!)}',
        ].join(' • '),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _money(loan.outstandingBalance),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          if (loan.status == LoanStatus.approved && loan.termMonths != null)
            Text(
              '${loan.termMonths} mos',
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _LoanStatusIcon extends StatelessWidget {
  const _LoanStatusIcon({required this.status});

  final LoanStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoanStatus.pending:
        return const Icon(Icons.schedule_outlined, color: Color(0xFF8D6B00));
      case LoanStatus.approved:
        return const Icon(Icons.check_circle_outline, color: Color(0xFF1D7E4B));
      case LoanStatus.paid:
        return const Icon(Icons.task_alt_outlined, color: Color(0xFF235347));
      case LoanStatus.rejected:
        return const Icon(Icons.cancel_outlined, color: Color(0xFF8B1A1A));
    }
  }
}

enum _MemberLoanFilter {
  all,
  pending,
  approved,
  closed;

  bool matches(Loan loan) {
    switch (this) {
      case _MemberLoanFilter.all:
        return true;
      case _MemberLoanFilter.pending:
        return loan.status == LoanStatus.pending;
      case _MemberLoanFilter.approved:
        return loan.status == LoanStatus.approved;
      case _MemberLoanFilter.closed:
        return loan.status == LoanStatus.paid ||
            loan.status == LoanStatus.rejected;
    }
  }
}

String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
