import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
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
                  ? SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Code')),
                          DataColumn(label: Text('Name')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Savings')),
                          DataColumn(label: Text('Status')),
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
                                  Text(
                                    _money(app.savings.balanceFor(member.id)),
                                  ),
                                ),
                                DataCell(Text(member.status.name)),
                                DataCell(
                                  Wrap(
                                    spacing: 4,
                                    children: [
                                      IconButton(
                                        tooltip: 'View',
                                        onPressed: () =>
                                            _showMemberDetails(context, member),
                                        icon: const Icon(
                                          Icons.visibility_outlined,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Edit',
                                        onPressed: () => _showMemberDialog(
                                          context,
                                          member: member,
                                        ),
                                        icon: const Icon(Icons.edit_outlined),
                                      ),
                                    ],
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
                              '${member.memberCode} • ${member.phone}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _showMemberDialog(context, member: member),
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
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }
                    if (member == null) {
                      app.members.addMember(
                        fullName: nameController.text,
                        address: addressController.text,
                        phone: phoneController.text,
                      );
                    } else {
                      app.members.updateMember(
                        member.copyWith(
                          fullName: nameController.text.trim(),
                          address: addressController.text.trim(),
                          phone: phoneController.text.trim(),
                          status: status,
                        ),
                      );
                    }
                    Navigator.of(dialogContext).pop();
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

  static String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required.' : null;
  static String _money(double value) => 'PHP ${value.toStringAsFixed(2)}';
  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
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
