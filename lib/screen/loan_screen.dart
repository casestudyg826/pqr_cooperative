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
  final _rateController = TextEditingController(text: '12');
  final _termController = TextEditingController(text: '12');
  String? _memberId = 'm001';

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _termController.dispose();
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
              rateController: _rateController,
              termController: _termController,
              onMemberChanged: (value) => setState(() => _memberId = value),
              onSubmit: _apply,
            ),
          ),
          SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
          if (isWide)
            Expanded(child: _LoanList())
          else
            SizedBox(width: double.infinity, child: _LoanList()),
        ],
      ),
    );
  }

  void _apply() {
    final principal = double.tryParse(_principalController.text.trim());
    final rate = double.tryParse(_rateController.text.trim());
    final term = int.tryParse(_termController.text.trim());
    if (_memberId == null ||
        principal == null ||
        principal <= 0 ||
        rate == null ||
        rate < 0 ||
        term == null ||
        term <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid loan application details.')),
      );
      return;
    }

    AppScope.of(context).loans.addLoan(
      memberId: _memberId!,
      principal: principal,
      annualInterestRate: rate / 100,
      termMonths: term,
    );
    _principalController.clear();
  }
}

class _LoanForm extends StatelessWidget {
  const _LoanForm({
    required this.memberId,
    required this.principalController,
    required this.rateController,
    required this.termController,
    required this.onMemberChanged,
    required this.onSubmit,
  });

  final String? memberId;
  final TextEditingController principalController;
  final TextEditingController rateController;
  final TextEditingController termController;
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
                labelText: 'Principal',
                prefixText: 'PHP ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
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
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Loan records',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final loan in app.loans.loans)
              _LoanTile(
                loan: loan,
                memberName: app.members.nameFor(loan.memberId),
              ),
          ],
        ),
      ),
    );
  }
}

class _LoanTile extends StatelessWidget {
  const _LoanTile({required this.loan, required this.memberName});

  final Loan loan;
  final String memberName;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
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
                Text('Principal: ${_money(loan.principal)}'),
                Text('Interest: ${_money(loan.interest)}'),
                Text('Paid: ${_money(loan.totalPaid)}'),
                Text('Outstanding: ${_money(loan.outstandingBalance)}'),
                Text('Due: ${_date(loan.dueDate)}'),
              ],
            ),
            if (loan.repayments.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Repayments: ${loan.repayments.map((item) => _money(item.amount)).join(', ')}',
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (loan.status == LoanStatus.pending) ...[
                  OutlinedButton(
                    onPressed: () =>
                        app.loans.updateStatus(loan.id, LoanStatus.approved),
                    child: const Text('Approve'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        app.loans.updateStatus(loan.id, LoanStatus.rejected),
                    child: const Text('Reject'),
                  ),
                ],
                if (loan.status == LoanStatus.approved)
                  FilledButton.tonal(
                    onPressed: () => _showPaymentDialog(context, loan),
                    child: const Text('Record payment'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, Loan loan) {
    final amountController = TextEditingController(
      text: loan.outstandingBalance.toStringAsFixed(2),
    );
    final noteController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Record repayment'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
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
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (amount == null || amount <= 0) {
                  return;
                }
                AppScope.of(context).loans.recordPayment(
                  loanId: loan.id,
                  amount: amount,
                  note: noteController.text,
                );
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
