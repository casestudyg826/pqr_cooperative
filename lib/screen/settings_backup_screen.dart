import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/app_user.dart';

class SettingsBackupScreen extends StatefulWidget {
  const SettingsBackupScreen({super.key});

  @override
  State<SettingsBackupScreen> createState() => _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends State<SettingsBackupScreen> {
  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.auth.currentUser!;
    final summary = app.reports.buildSummary(
      members: app.members,
      savings: app.savings,
      loans: app.loans,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Security and Backup',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'This prototype simulates role-based access and backup status for the case study.',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 840;
              final accessCard = _InfoCard(
                title: 'Current Access',
                icon: Icons.verified_user_outlined,
                children: [
                  _Line(label: 'User', value: user.displayName),
                  _Line(label: 'Role', value: user.roleLabel),
                  _Line(
                    label: 'Member records',
                    value: user.isAdministrator
                        ? 'Manage'
                        : 'Read through transactions',
                  ),
                  _Line(label: 'Savings and loans', value: 'Manage'),
                  _Line(label: 'Reports', value: 'View'),
                ],
              );
              final backupCard = _InfoCard(
                title: 'Backup Status',
                icon: Icons.backup_outlined,
                children: [
                  const _Line(label: 'Status', value: 'Prototype only'),
                  _Line(
                    label: 'Records included',
                    value:
                        '${summary.totalMembers} members, ${summary.activeLoans + summary.pendingLoans} active/pending loans',
                  ),
                  const _Line(label: 'Storage', value: 'Not implemented yet'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _runBackup,
                    icon: const Icon(Icons.cloud_done_outlined),
                    label: const Text('Run backup now'),
                  ),
                ],
              );

              if (!isWide) {
                return Column(
                  children: [
                    accessCard,
                    const SizedBox(height: 16),
                    backupCard,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: accessCard),
                  const SizedBox(width: 16),
                  Expanded(child: backupCard),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          _UserManagementCard(
            currentUser: user,
            onAdd: () => _showUserDialog(context),
            onEdit: (target) => _showUserDialog(context, user: target),
          ),
        ],
      ),
    );
  }

  void _runBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup does nothing for now.')),
    );
  }

  Future<void> _showUserDialog(BuildContext context, {AppUser? user}) async {
    final app = AppScope.of(context);
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final usernameController = TextEditingController(
      text: user?.username ?? '',
    );
    final passwordController = TextEditingController(
      text: user?.password ?? '',
    );
    final formKey = GlobalKey<FormState>();
    var role = user?.role ?? UserRole.administrator;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEdit ? 'Edit user' : 'Add user'),
              content: SizedBox(
                width: 520,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display name',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<UserRole>(
                        initialValue: role,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(
                            value: UserRole.administrator,
                            child: Text('Administrator'),
                          ),
                          DropdownMenuItem(
                            value: UserRole.treasurer,
                            child: Text('Treasurer'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => role = value);
                          }
                        },
                      ),
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
                  onPressed: () {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final success = isEdit
                        ? app.auth.updateUser(
                            id: user.id,
                            displayName: nameController.text,
                            username: usernameController.text,
                            password: passwordController.text,
                            role: role,
                          )
                        : app.auth.addUser(
                            displayName: nameController.text,
                            username: usernameController.text,
                            password: passwordController.text,
                            role: role,
                          );

                    if (!success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Unable to save user. Check fields or username uniqueness.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'User updated.' : 'User added.'),
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (!mounted) {
      return;
    }
  }

  static String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required.';
    }
    return null;
  }
}

class _UserManagementCard extends StatelessWidget {
  const _UserManagementCard({
    required this.currentUser,
    required this.onAdd,
    required this.onEdit,
  });

  final AppUser currentUser;
  final VoidCallback onAdd;
  final ValueChanged<AppUser> onEdit;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final users = app.auth.users;

    return _InfoCard(
      title: 'User Management',
      icon: Icons.manage_accounts_outlined,
      children: [
        if (!currentUser.isAdministrator)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Only administrators can add and edit user credentials.',
            ),
          )
        else
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add user'),
            ),
          ),
        const SizedBox(height: 12),
        for (final user in users)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE0E4DD)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFE8EFE9),
                  foregroundColor: Color(0xFF235347),
                  child: Icon(Icons.person_outline, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text('${user.username} • ${user.roleLabel}'),
                    ],
                  ),
                ),
                if (currentUser.isAdministrator)
                  OutlinedButton.icon(
                    onPressed: () => onEdit(user),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFE8EFE9),
                  foregroundColor: const Color(0xFF235347),
                  child: Icon(icon),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
