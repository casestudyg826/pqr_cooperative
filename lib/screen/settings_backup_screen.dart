import 'package:flutter/material.dart';

import '../controller/app_controller.dart';

class SettingsBackupScreen extends StatefulWidget {
  const SettingsBackupScreen({super.key});

  @override
  State<SettingsBackupScreen> createState() => _SettingsBackupScreenState();
}

class _SettingsBackupScreenState extends State<SettingsBackupScreen> {
  DateTime? _lastBackup;

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
                  _Line(
                    label: 'Last backup',
                    value: _lastBackup == null
                        ? 'Not yet created'
                        : _dateTime(_lastBackup!),
                  ),
                  _Line(
                    label: 'Records included',
                    value:
                        '${summary.totalMembers} members, ${summary.activeLoans + summary.pendingLoans} active/pending loans',
                  ),
                  _Line(label: 'Storage', value: 'Simulated local backup'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () =>
                        setState(() => _lastBackup = DateTime.now()),
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
        ],
      ),
    );
  }

  static String _dateTime(DateTime value) {
    final date =
        '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
    final time =
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return '$date $time';
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
