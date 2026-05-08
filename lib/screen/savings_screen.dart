import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/savings_transaction.dart';

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _memberId = 'm001';
  SavingsTransactionType _type = SavingsTransactionType.contribution;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Flex(
        direction: isWide ? Axis.horizontal : Axis.vertical,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: isWide ? 380 : double.infinity,
            child: _SavingsForm(
              memberId: _memberId,
              type: _type,
              amountController: _amountController,
              noteController: _noteController,
              onMemberChanged: (value) => setState(() => _memberId = value),
              onTypeChanged: (value) => setState(() => _type = value),
              onSubmit: _record,
            ),
          ),
          SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
          if (isWide)
            Expanded(child: _SavingsLedger())
          else
            SizedBox(width: double.infinity, child: _SavingsLedger()),
        ],
      ),
    );
  }

  void _record() {
    final amount = double.tryParse(_amountController.text.trim());
    if (_memberId == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a member and enter a valid amount.'),
        ),
      );
      return;
    }

    AppScope.of(context).savings.recordTransaction(
      memberId: _memberId!,
      type: _type,
      amount: amount,
      note: _noteController.text,
    );
    _amountController.clear();
    _noteController.clear();
  }
}

class _SavingsForm extends StatelessWidget {
  const _SavingsForm({
    required this.memberId,
    required this.type,
    required this.amountController,
    required this.noteController,
    required this.onMemberChanged,
    required this.onTypeChanged,
    required this.onSubmit,
  });

  final String? memberId;
  final SavingsTransactionType type;
  final TextEditingController amountController;
  final TextEditingController noteController;
  final ValueChanged<String?> onMemberChanged;
  final ValueChanged<SavingsTransactionType> onTypeChanged;
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
              'Record savings',
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
            SegmentedButton<SavingsTransactionType>(
              segments: const [
                ButtonSegment(
                  value: SavingsTransactionType.contribution,
                  label: Text('Deposit'),
                ),
                ButtonSegment(
                  value: SavingsTransactionType.withdrawal,
                  label: Text('Withdraw'),
                ),
              ],
              selected: {type},
              onSelectionChanged: (selected) => onTypeChanged(selected.first),
            ),
            const SizedBox(height: 12),
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
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSubmit,
              icon: const Icon(Icons.save),
              label: const Text('Record transaction'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsLedger extends StatelessWidget {
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
              'Savings ledger',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text('Total balance: ${_money(app.savings.totalSavings)}'),
            const Divider(height: 28),
            for (final transaction in app.savings.transactions)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  child: Icon(
                    transaction.signedAmount >= 0
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                  ),
                ),
                title: Text(app.members.nameFor(transaction.memberId)),
                subtitle: Text(
                  '${transaction.typeLabel} • ${_date(transaction.date)} • ${transaction.note}',
                ),
                trailing: Text(_money(transaction.signedAmount)),
              ),
          ],
        ),
      ),
    );
  }

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
