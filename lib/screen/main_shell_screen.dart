import 'package:flutter/material.dart';

import '../controller/app_controller.dart';
import '../module/app_user.dart';
import 'dashboard_screen.dart';
import 'loan_screen.dart';
import 'member_portal_screen.dart';
import 'member_screen.dart';
import 'reports_screen.dart';
import 'savings_screen.dart';
import 'settings_backup_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key});

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final user = app.auth.currentUser!;
    final items = _itemsFor(user.role);
    if (_selectedIndex >= items.length) {
      _selectedIndex = 0;
    }

    final isDesktop = MediaQuery.sizeOf(context).width >= 840;
    final selectedItem = items[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedItem.label),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(child: Text(user.roleLabel)),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: app.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: SafeArea(
                child: _NavigationList(
                  items: items,
                  selectedIndex: _selectedIndex,
                  onSelected: (index) {
                    setState(() => _selectedIndex = index);
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
      body: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NavigationRail(
                  extended: MediaQuery.sizeOf(context).width >= 1120,
                  backgroundColor: Colors.white,
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) =>
                      setState(() => _selectedIndex = index),
                  labelType: MediaQuery.sizeOf(context).width >= 1120
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (final item in items)
                      NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.selectedIcon),
                        label: Text(item.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: selectedItem.screen),
              ],
            )
          : selectedItem.screen,
    );
  }

  List<_NavItem> _itemsFor(UserRole role) {
    if (role == UserRole.member) {
      return const [
        _NavItem(
          label: 'My Account',
          icon: Icons.account_circle_outlined,
          selectedIcon: Icons.account_circle,
          screen: MemberPortalScreen(),
        ),
      ];
    }

    final base = <_NavItem>[
      const _NavItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        screen: DashboardScreen(),
      ),
      const _NavItem(
        label: 'Savings',
        icon: Icons.savings_outlined,
        selectedIcon: Icons.savings,
        screen: SavingsScreen(),
      ),
      const _NavItem(
        label: 'Loans',
        icon: Icons.request_quote_outlined,
        selectedIcon: Icons.request_quote,
        screen: LoanScreen(),
      ),
      const _NavItem(
        label: 'Reports',
        icon: Icons.summarize_outlined,
        selectedIcon: Icons.summarize,
        screen: ReportsScreen(),
      ),
      const _NavItem(
        label: 'Backup',
        icon: Icons.backup_outlined,
        selectedIcon: Icons.backup,
        screen: SettingsBackupScreen(),
      ),
    ];

    if (role == UserRole.administrator) {
      base.insert(
        1,
        const _NavItem(
          label: 'Members',
          icon: Icons.groups_outlined,
          selectedIcon: Icons.groups,
          screen: MemberScreen(),
        ),
      );
    }
    return base;
  }
}

class _NavigationList extends StatelessWidget {
  const _NavigationList({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const ListTile(
          leading: Icon(Icons.account_balance),
          title: Text('PQR Cooperative'),
          subtitle: Text('Management System'),
        ),
        const Divider(),
        for (var index = 0; index < items.length; index++)
          ListTile(
            selected: selectedIndex == index,
            leading: Icon(
              selectedIndex == index
                  ? items[index].selectedIcon
                  : items[index].icon,
            ),
            title: Text(items[index].label),
            onTap: () => onSelected(index),
          ),
      ],
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
