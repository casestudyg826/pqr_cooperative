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
            'Role-based staff access and backup runs are stored in the backend.',
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
                  _Line(
                    label: 'Status',
                    value: app.backupRuns.isEmpty
                        ? 'No backend backup yet'
                        : 'Last backup completed',
                  ),
                  _Line(
                    label: 'Records included',
                    value:
                        '${summary.totalMembers} members, ${summary.activeLoans + summary.pendingLoans} active/pending loans',
                  ),
                  const _Line(label: 'Storage', value: 'Supabase Postgres'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      _runBackup();
                    },
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
            onAddMemberAccount: () => _showMemberAccountDialog(context),
            onEdit: (target) => _showUserDialog(context, user: target),
          ),
        ],
      ),
    );
  }

  Future<void> _runBackup() async {
    try {
      final backup = await AppScope.of(context).runBackup();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup completed: ${backup.id}')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _showUserDialog(BuildContext context, {AppUser? user}) async {
    final app = AppScope.of(context);
    final isEdit = user != null;
    final nameController = TextEditingController(text: user?.displayName ?? '');
    final usernameController = TextEditingController(
      text: user?.username ?? '',
    );
    final passwordController = TextEditingController();
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
                        validator: (value) {
                          if (!isEdit) {
                            return _required(value);
                          }
                          return null;
                        },
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
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) {
                      return;
                    }

                    final success = isEdit
                        ? await app.auth.updateUser(
                            id: user.id,
                            displayName: nameController.text,
                            username: usernameController.text,
                            password: passwordController.text,
                            role: role,
                          )
                        : await app.auth.addUser(
                            displayName: nameController.text,
                            username: usernameController.text,
                            password: passwordController.text,
                            role: role,
                          );

                    if (!context.mounted || !dialogContext.mounted) {
                      return;
                    }

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

  Future<void> _showMemberAccountDialog(BuildContext context) async {
    final app = AppScope.of(context);
    final fullNameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add member account'),
          content: SizedBox(
            width: 560,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: 'Full name'),
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
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: _required,
                    obscureText: true,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required.';
                      }
                      if (value != passwordController.text) {
                        return 'Passwords do not match.';
                      }
                      return null;
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
              onPressed: () async {
                if (!formKey.currentState!.validate()) {
                  return;
                }

                final success = await app.addMemberAccount(
                  fullName: fullNameController.text,
                  address: addressController.text,
                  phone: phoneController.text,
                  username: usernameController.text,
                  password: passwordController.text,
                );

                if (!context.mounted || !dialogContext.mounted) {
                  return;
                }

                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Unable to create member account. Check fields or username uniqueness.',
                      ),
                    ),
                  );
                  return;
                }

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Member account created.')),
                );
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
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
    required this.onAddMemberAccount,
    required this.onEdit,
  });

  final AppUser currentUser;
  final VoidCallback onAdd;
  final VoidCallback onAddMemberAccount;
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('addUserButton'),
                onPressed: onAdd,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Add user'),
              ),
              OutlinedButton.icon(
                key: const Key('addMemberAccountButton'),
                onPressed: onAddMemberAccount,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('Add member account'),
              ),
            ],
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
                      Text(
                        user.memberId == null
                            ? '${user.username} • ${user.roleLabel}'
                            : '${user.username} • ${user.roleLabel} • ${app.members.findById(user.memberId!)?.memberCode ?? 'No member'}',
                      ),
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
