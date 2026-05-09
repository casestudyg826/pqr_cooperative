import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/member.dart';
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

    final selectedMember = _memberId == null
        ? null
        : app.members.findById(_memberId!);
    final isWide = MediaQuery.sizeOf(context).width >= 980;
    final selectedBalance = selectedMember == null
        ? 0.0
        : app.savings.balanceFor(selectedMember.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Savings Accounts',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text('Cooperative total: ${_money(app.savings.totalSavings)}'),
          const SizedBox(height: 20),
          Flex(
            direction: isWide ? Axis.horizontal : Axis.vertical,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: isWide ? 360 : double.infinity,
                child: _SavingsForm(
                  memberId: _memberId,
                  selectedBalance: selectedBalance,
                  type: _type,
                  amountController: _amountController,
                  noteController: _noteController,
                  onMemberChanged: (value) => setState(() => _memberId = value),
                  onTypeChanged: (value) => setState(() => _type = value),
                  onSubmit: () {
                    _record();
                  },
                ),
              ),
              SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),
              if (isWide)
                Expanded(
                  child: _SavingsAccountWorkspace(
                    members: members,
                    selectedMemberId: _memberId,
                    selectedMember: selectedMember,
                    onMemberSelected: (value) =>
                        setState(() => _memberId = value),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: _SavingsAccountWorkspace(
                    members: members,
                    selectedMemberId: _memberId,
                    selectedMember: selectedMember,
                    onMemberSelected: (value) =>
                        setState(() => _memberId = value),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _record() async {
    final app = AppScope.of(context);
    final amount = double.tryParse(_amountController.text.trim());
    if (_memberId == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a member and enter a valid amount.'),
        ),
      );
      return;
    }

    final currentBalance = app.savings.balanceFor(_memberId!);
    if (_type == SavingsTransactionType.withdrawal && amount > currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal exceeds account balance.')),
      );
      return;
    }

    try {
      await app.savings.recordTransaction(
        memberId: _memberId!,
        type: _type,
        amount: amount,
        note: _noteController.text,
      );
      _amountController.clear();
      _noteController.clear();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
}

class _SavingsForm extends StatelessWidget {
  const _SavingsForm({
    required this.memberId,
    required this.selectedBalance,
    required this.type,
    required this.amountController,
    required this.noteController,
    required this.onMemberChanged,
    required this.onTypeChanged,
    required this.onSubmit,
  });

  final String? memberId;
  final double selectedBalance;
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Record transaction',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text('Selected balance: ${_money(selectedBalance)}'),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              key: ValueKey(memberId),
              initialValue: memberId,
              decoration: const InputDecoration(labelText: 'Member account'),
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
                  icon: Icon(Icons.add),
                  label: Text('Deposit'),
                ),
                ButtonSegment(
                  value: SavingsTransactionType.withdrawal,
                  icon: Icon(Icons.remove),
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

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
}

class _SavingsAccountWorkspace extends StatelessWidget {
  const _SavingsAccountWorkspace({
    required this.members,
    required this.selectedMemberId,
    required this.selectedMember,
    required this.onMemberSelected,
  });

  final List<Member> members;
  final String? selectedMemberId;
  final Member? selectedMember;
  final ValueChanged<String> onMemberSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SavingsAccountsPanel(
          members: members,
          selectedMemberId: selectedMemberId,
          onMemberSelected: onMemberSelected,
        ),
        const SizedBox(height: 16),
        _SavingsLedger(member: selectedMember),
      ],
    );
  }
}

class _SavingsAccountsPanel extends StatefulWidget {
  const _SavingsAccountsPanel({
    required this.members,
    required this.selectedMemberId,
    required this.onMemberSelected,
  });

  final List<Member> members;
  final String? selectedMemberId;
  final ValueChanged<String> onMemberSelected;

  @override
  State<_SavingsAccountsPanel> createState() => _SavingsAccountsPanelState();
}

class _SavingsAccountsPanelState extends State<_SavingsAccountsPanel> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final filteredMembers = widget.members.where((member) {
      if (query.isEmpty) {
        return true;
      }
      return member.fullName.toLowerCase().contains(query) ||
          member.memberCode.toLowerCase().contains(query) ||
          member.phone.toLowerCase().contains(query);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Member accounts',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search accounts by name, code, or phone',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 3
                    : constraints.maxWidth >= 600
                    ? 2
                    : 1;
                const tileHeight = 96.0;
                const spacing = 10.0;
                final maxVisibleRows = columns == 1 ? 5 : 2;
                final rows = (filteredMembers.length / columns).ceil();
                final visibleRows = rows == 0
                    ? 1
                    : rows > maxVisibleRows
                    ? maxVisibleRows
                    : rows;
                final gridHeight =
                    (visibleRows * tileHeight) + ((visibleRows - 1) * spacing);

                if (filteredMembers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('No matching member accounts.'),
                  );
                }

                return SizedBox(
                  height: gridHeight,
                  child: GridView.builder(
                    itemCount: filteredMembers.length,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: spacing,
                      mainAxisSpacing: spacing,
                      mainAxisExtent: tileHeight,
                    ),
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      final isSelected = member.id == widget.selectedMemberId;
                      return _SavingsAccountTile(
                        member: member,
                        balance: app.savings.balanceFor(member.id),
                        isSelected: isSelected,
                        onTap: () => widget.onMemberSelected(member.id),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SavingsAccountTile extends StatelessWidget {
  const _SavingsAccountTile({
    required this.member,
    required this.balance,
    required this.isSelected,
    required this.onTap,
  });

  final Member member;
  final double balance;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8EFE9) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? colorScheme.primary : const Color(0xFFE0E4DD),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    member.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            Text(
              member.memberCode,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              _money(balance),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
}

class _SavingsLedger extends StatelessWidget {
  const _SavingsLedger({required this.member});

  final Member? member;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final transactions = member == null
        ? <SavingsTransaction>[]
        : app.savings.transactionsFor(member!.id);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Account transaction history',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              member == null
                  ? 'No account selected'
                  : '${member!.fullName} • ${member!.memberCode}',
            ),
            const Divider(height: 28),
            if (transactions.isEmpty)
              const Text('No transactions recorded.')
            else
              for (final transaction in transactions)
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(vertical: -2),
                  minVerticalPadding: 0,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    child: Icon(
                      transaction.signedAmount >= 0
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                      size: 18,
                    ),
                  ),
                  title: Text(transaction.typeLabel),
                  subtitle: Text(
                    '${_date(transaction.date)} • ${transaction.note}',
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
