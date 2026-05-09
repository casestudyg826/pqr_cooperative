import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/loan.dart';
import '../module/member.dart';

class MemberScreen extends StatefulWidget {
  const MemberScreen({super.key});

  @override
  State<MemberScreen> createState() => _MemberScreenState();
}

class _MemberScreenState extends State<MemberScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final members = app.members.search(_searchController.text);
    final isWide = MediaQuery.sizeOf(context).width >= 860;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            onAdd: () => _showMemberDialog(context),
            searchController: _searchController,
            onSearchChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isWide
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 28,
                        headingRowHeight: 44,
                        dataRowMinHeight: 56,
                        dataRowMaxHeight: 72,
                        columns: const [
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Address')),
                          DataColumn(label: Text('Joined')),
                          DataColumn(label: Text('Savings')),
                          DataColumn(label: Text('Loan Applied')),
                          DataColumn(label: Text('Loan Status')),
                          DataColumn(label: Text('Outstanding')),
                          DataColumn(label: Text('Member Status')),
                          DataColumn(label: Text('Actions')),
                        ],
                        rows: [
                          for (final member in members)
                            DataRow(
                              cells: [
                                DataCell(Text(member.memberCode)),
                                DataCell(Text(member.fullName)),
                                DataCell(Text(member.phone)),
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      member.address,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(_date(member.joinedAt))),
                                DataCell(
                                  Text(
                                    _money(app.savings.balanceFor(member.id)),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _loanAppliedLabel(
                                      app.loans.loansForMember(member.id),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _loanStatusLabel(
                                      app.loans.loansForMember(member.id),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    _money(
                                      _outstandingLoanBalance(
                                        app.loans.loansForMember(member.id),
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(member.status.name)),
                                DataCell(
                                  _MemberActions(
                                    member: member,
                                    compact: true,
                                    onView: () =>
                                        _showMemberDetails(context, member),
                                    onEdit: () => _showMemberDialog(
                                      context,
                                      member: member,
                                    ),
                                    onDelete: () =>
                                        _confirmDeleteMember(context, member),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        for (final member in members)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(member.fullName),
                            subtitle: Text(
                              '${member.memberCode} • ${member.phone}\n'
                              'Savings: ${_money(app.savings.balanceFor(member.id))} • '
                              'Loans: ${_loanStatusLabel(app.loans.loansForMember(member.id))}',
                            ),
                            isThreeLine: true,
                            trailing: _MemberActions(
                              member: member,
                              compact: true,
                              onEdit: () =>
                                  _showMemberDialog(context, member: member),
                              onDelete: () =>
                                  _confirmDeleteMember(context, member),
                            ),
                            onTap: () => _showMemberDetails(context, member),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberDialog(BuildContext context, {Member? member}) {
    final app = AppScope.of(context);
    final nameController = TextEditingController(text: member?.fullName ?? '');
    final addressController = TextEditingController(
      text: member?.address ?? '',
    );
    final phoneController = TextEditingController(text: member?.phone ?? '');
    var status = member?.status ?? MemberStatus.active;
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(member == null ? 'Add Member' : 'Edit Member'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        key: const Key('memberNameField'),
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(labelText: 'Phone'),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Address'),
                        minLines: 2,
                        maxLines: 3,
                        validator: _required,
                      ),
                      if (member != null) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<MemberStatus>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: MemberStatus.active,
                              child: Text('Active'),
                            ),
                            DropdownMenuItem(
                              value: MemberStatus.inactive,
                              child: Text('Inactive'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => status = value);
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('saveMemberButton'),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    try {
                      if (member == null) {
                        await app.members.addMember(
                          fullName: nameController.text,
                          address: addressController.text,
                          phone: phoneController.text,
                        );
                      } else {
                        await app.members.updateMember(
                          member.copyWith(
                            fullName: nameController.text.trim(),
                            address: addressController.text.trim(),
                            phone: phoneController.text.trim(),
                            status: status,
                          ),
                        );
                      }
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
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMemberDetails(BuildContext context, Member member) {
    final app = AppScope.of(context);
    final memberLoans = app.loans.loansForMember(member.id);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(member.fullName),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Member code', value: member.memberCode),
                _DetailRow(label: 'Phone', value: member.phone),
                _DetailRow(label: 'Address', value: member.address),
                _DetailRow(label: 'Joined', value: _date(member.joinedAt)),
                _DetailRow(
                  label: 'Savings balance',
                  value: _money(app.savings.balanceFor(member.id)),
                ),
                _DetailRow(
                  label: 'Loan applied',
                  value: _loanAppliedLabel(memberLoans),
                ),
                _DetailRow(
                  label: 'Loan status',
                  value: _loanStatusLabel(memberLoans),
                ),
                _DetailRow(
                  label: 'Outstanding loan',
                  value: _money(_outstandingLoanBalance(memberLoans)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteMember(BuildContext context, Member member) async {
    final app = AppScope.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete member'),
          content: Text(
            'Delete ${member.fullName}? This removes their savings transactions and loan records from the backend.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await app.members.deleteMember(member.id);
      app.savings.deleteTransactionsForMember(member.id);
      app.loans.deleteLoansForMember(member.id);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${member.fullName} deleted.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required.' : null;
  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _loanAppliedLabel(List<Loan> loans) {
    if (loans.isEmpty) {
      return 'No';
    }
    return 'Yes (${loans.length})';
  }

  static String _loanStatusLabel(List<Loan> loans) {
    if (loans.isEmpty) {
      return 'No loans';
    }
    final pending = loans
        .where((loan) => loan.status == LoanStatus.pending)
        .length;
    final active = loans
        .where(
          (loan) =>
              loan.status == LoanStatus.approved && loan.outstandingBalance > 0,
        )
        .length;
    final paid = loans.where((loan) => loan.status == LoanStatus.paid).length;
    final rejected = loans
        .where((loan) => loan.status == LoanStatus.rejected)
        .length;
    final parts = <String>[];
    if (pending > 0) {
      parts.add('$pending pending');
    }
    if (active > 0) {
      parts.add('$active active');
    }
    if (paid > 0) {
      parts.add('$paid paid');
    }
    if (rejected > 0) {
      parts.add('$rejected rejected');
    }
    return parts.join(', ');
  }

  static double _outstandingLoanBalance(List<Loan> loans) {
    return loans.fold(0, (sum, loan) => sum + loan.outstandingBalance);
  }
}

class _MemberActions extends StatelessWidget {
  const _MemberActions({
    required this.member,
    required this.onEdit,
    required this.onDelete,
    this.onView,
    this.compact = false,
  });

  final Member member;
  final VoidCallback? onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final actions = <Widget>[
      if (onView != null)
        _ActionIconButton(
          key: Key('viewMember_${member.id}'),
          tooltip: 'View',
          icon: Icons.visibility_outlined,
          onPressed: onView!,
        ),
      if (onView != null) _ActionDivider(color: colors.outlineVariant),
      _ActionIconButton(
        key: Key('editMember_${member.id}'),
        tooltip: 'Edit',
        icon: Icons.edit_outlined,
        onPressed: onEdit,
      ),
      _ActionDivider(color: colors.outlineVariant),
      _ActionIconButton(
        key: Key('deleteMember_${member.id}'),
        tooltip: 'Delete',
        icon: Icons.delete_outline,
        color: colors.error,
        onPressed: onDelete,
      ),
    ];

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: actions,
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      color: color,
      onPressed: onPressed,
      icon: Icon(icon),
    );
  }
}

class _ActionDivider extends StatelessWidget {
  const _ActionDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: VerticalDivider(width: 1, thickness: 1, color: color),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onAdd,
    required this.searchController,
    required this.onSearchChanged,
  });

  final VoidCallback onAdd;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search members by name, code, or phone',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        FilledButton.icon(
          key: const Key('addMemberButton'),
          onPressed: onAdd,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add member'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
