import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/loan.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  final _principalController = TextEditingController();
  String? _memberId = 'm001';

  @override
  void dispose() {
    _principalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final members = app.members.members;
    if (members.isNotEmpty &&
        !members.any((member) => member.id == _memberId)) {
      _memberId = members.first.id;
    }
    final isWide = MediaQuery.sizeOf(context).width >= 980;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Flex(
        direction: isWide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWide ? 380 : double.infinity,
            child: _LoanForm(
              memberId: _memberId,
              principalController: _principalController,
              onMemberChanged: (value) => setState(() => _memberId = value),
              onSubmit: _apply,
            ),
          ),
          SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
          if (isWide)
            Expanded(child: const _LoanList())
          else
            const SizedBox(width: double.infinity, child: _LoanList()),
        ],
      ),
    );
  }

  Future<void> _apply() async {
    final principal = double.tryParse(_principalController.text.trim());
    if (_memberId == null || principal == null || principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid loan application details.')),
      );
      return;
    }

    try {
      await AppScope.of(
        context,
      ).loans.addLoan(memberId: _memberId!, principal: principal);
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

class _LoanForm extends StatelessWidget {
  const _LoanForm({
    required this.memberId,
    required this.principalController,
    required this.onMemberChanged,
    required this.onSubmit,
  });

  final String? memberId;
  final TextEditingController principalController;
  final ValueChanged<String?> onMemberChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Loan application',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Submit amount requests. Interest rate and term are set during approval.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: memberId,
              decoration: const InputDecoration(labelText: 'Member'),
              items: [
                for (final member in app.members.members)
                  DropdownMenuItem(
                    value: member.id,
                    child: Text(member.fullName),
                  ),
              ],
              onChanged: onMemberChanged,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: principalController,
              decoration: const InputDecoration(
                labelText: 'Requested amount',
                prefixText: 'PHP ',
              ),
              keyboardType: TextInputType.number,
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

class _LoanList extends StatelessWidget {
  const _LoanList();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pendingLoans = app.loans.loans
        .where((loan) => loan.status == LoanStatus.pending)
        .toList();
    final activeLoans = app.loans.loans
        .where((loan) => loan.status == LoanStatus.approved)
        .toList();
    final closedLoans = app.loans.loans
        .where(
          (loan) =>
              loan.status == LoanStatus.paid ||
              loan.status == LoanStatus.rejected,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _LoanSection(
          title: 'Pending applications',
          subtitle: 'Review loan requests before release.',
          emptyMessage: 'No loan applications waiting for approval.',
          children: [
            for (final loan in pendingLoans)
              _PendingLoanTile(
                loan: loan,
                memberName: app.members.nameFor(loan.memberId),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _LoanSection(
          title: 'Active loans',
          subtitle: 'Track balances and record member repayments.',
          emptyMessage: 'No active loans right now.',
          children: [
            for (final loan in activeLoans)
              _ActiveLoanTile(
                loan: loan,
                memberName: app.members.nameFor(loan.memberId),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _LoanSection(
          title: 'Closed records',
          subtitle: 'Paid and rejected loan records.',
          emptyMessage: 'No closed loan records yet.',
          children: [
            for (final loan in closedLoans)
              _ClosedLoanTile(
                loan: loan,
                memberName: app.members.nameFor(loan.memberId),
              ),
          ],
        ),
      ],
    );
  }
}

class _LoanSection extends StatelessWidget {
  const _LoanSection({
    required this.title,
    required this.subtitle,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final String subtitle;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(subtitle),
            const SizedBox(height: 14),
            if (children.isEmpty) Text(emptyMessage) else ...children,
          ],
        ),
      ),
    );
  }
}

class _PendingLoanTile extends StatelessWidget {
  const _PendingLoanTile({required this.loan, required this.memberName});

  final Loan loan;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text(
                  memberName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Chip(label: Text(loan.statusLabel)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                Text('Requested: ${_money(loan.principal)}'),
                Text('Applied: ${_date(loan.appliedAt)}'),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _showApprovalDialog(context, loan),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await AppScope.of(
                        context,
                      ).loans.updateStatus(loan.id, LoanStatus.rejected);
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showApprovalDialog(BuildContext context, Loan loan) {
    final rateController = TextEditingController(text: '12');
    final termController = TextEditingController(text: '12');

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Approve loan'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: rateController,
                  decoration: const InputDecoration(
                    labelText: 'Annual interest rate',
                    suffixText: '%',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: termController,
                  decoration: const InputDecoration(
                    labelText: 'Term',
                    suffixText: 'months',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final rate = double.tryParse(rateController.text.trim());
                final term = int.tryParse(termController.text.trim());
                if (rate == null || rate < 0 || term == null || term <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter valid approval details.'),
                    ),
                  );
                  return;
                }

                try {
                  await AppScope.of(context).loans.updateStatus(
                    loan.id,
                    LoanStatus.approved,
                    annualInterestRate: rate / 100,
                    termMonths: term,
                  );
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                } catch (error) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(error.toString())));
                }
              },
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );
  }
}

class _ActiveLoanTile extends StatelessWidget {
  const _ActiveLoanTile({required this.loan, required this.memberName});

  final Loan loan;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  memberName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Chip(label: Text(loan.statusLabel)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 18,
              runSpacing: 8,
              children: [
                Text('Monthly due: ${_money(_monthlyDueFor(loan))}'),
                Text('Paid: ${_money(loan.totalPaid)}'),
                Text('Outstanding: ${_money(loan.outstandingBalance)}'),
                Text(
                  loan.dueDate == null
                      ? 'Due: Not set'
                      : 'Due: ${_date(loan.dueDate!)}',
                ),
              ],
            ),
            if (loan.repayments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Repayments: ${loan.repayments.map((item) => _money(item.amount)).join(', ')}',
              ),
            ],
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () => _showPaymentDialog(context, loan),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Record payment'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Loan loan) {
    final monthlyAmount = _monthlyDueFor(loan);
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var mode = _PaymentMode.monthly;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Record repayment'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PaymentSummary(loan: loan, monthlyAmount: monthlyAmount),
                    const SizedBox(height: 14),
                    SegmentedButton<_PaymentMode>(
                      segments: const [
                        ButtonSegment(
                          value: _PaymentMode.monthly,
                          icon: Icon(Icons.calendar_month_outlined),
                          label: Text('Monthly'),
                        ),
                        ButtonSegment(
                          value: _PaymentMode.custom,
                          icon: Icon(Icons.edit_outlined),
                          label: Text('Custom'),
                        ),
                      ],
                      selected: {mode},
                      onSelectionChanged: (selected) {
                        setDialogState(() => mode = selected.first);
                      },
                    ),
                    const SizedBox(height: 12),
                    if (mode == _PaymentMode.monthly)
                      _ReadOnlyAmount(value: monthlyAmount)
                    else
                      TextField(
                        controller: amountController,
                        decoration: const InputDecoration(
                          labelText: 'Custom amount',
                          prefixText: 'PHP ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final paymentAmount = mode == _PaymentMode.monthly
                        ? monthlyAmount
                        : double.tryParse(amountController.text.trim());
                    if (paymentAmount == null ||
                        paymentAmount <= 0 ||
                        paymentAmount > loan.outstandingBalance) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Enter a valid amount within the outstanding balance.',
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await AppScope.of(context).loans.recordPayment(
                        loanId: loan.id,
                        amount: paymentAmount,
                        note: noteController.text.trim().isEmpty
                            ? mode.label
                            : noteController.text,
                      );
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.toString())));
                    }
                  },
                  child: const Text('Save payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ClosedLoanTile extends StatelessWidget {
  const _ClosedLoanTile({required this.loan, required this.memberName});

  final Loan loan;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history_outlined),
      title: Text(memberName),
      subtitle: Text(
        loan.dueDate == null
            ? loan.statusLabel
            : '${loan.statusLabel} • ${_date(loan.dueDate!)}',
      ),
      trailing: Text(_money(loan.totalPayable)),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.loan, required this.monthlyAmount});

  final Loan loan;
  final double monthlyAmount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E4DD)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PaymentLine(
              label: 'Outstanding',
              value: _money(loan.outstandingBalance),
            ),
            _PaymentLine(label: 'Monthly due', value: _money(monthlyAmount)),
            _PaymentLine(
              label: 'Term',
              value: loan.termMonths == null
                  ? 'Not set'
                  : '${loan.termMonths} months',
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentLine extends StatelessWidget {
  const _PaymentLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ReadOnlyAmount extends StatelessWidget {
  const _ReadOnlyAmount({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Payment amount',
        prefixText: 'PHP ',
      ),
      child: Text(
        value.toStringAsFixed(2),
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

enum _PaymentMode {
  monthly('Monthly loan repayment'),
  custom('Custom loan repayment');

  const _PaymentMode(this.label);

  final String label;
}

String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';

String _date(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

double _monthlyDueFor(Loan loan) {
  if (loan.termMonths == null || loan.termMonths == 0) {
    return loan.outstandingBalance;
  }
  final scheduled = loan.totalPayable / loan.termMonths!;
  if (scheduled > loan.outstandingBalance) {
    return loan.outstandingBalance;
  }
  return scheduled;
}
