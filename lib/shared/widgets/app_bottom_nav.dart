import 'package:flutter/material.dart';

enum AppTab { home, attendance, leave, directory }

class AppBottomNav extends StatelessWidget {
  final AppTab currentTab;
  final ValueChanged<AppTab> onTabSelected;

  const AppBottomNav({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home,
            label: 'Home',
            selected: currentTab == AppTab.home,
            theme: theme,
            onTap: () => onTabSelected(AppTab.home),
          ),
          _NavItem(
            icon: Icons.fingerprint_outlined,
            activeIcon: Icons.fingerprint,
            label: 'Attendance',
            selected: currentTab == AppTab.attendance,
            theme: theme,
            onTap: () => onTabSelected(AppTab.attendance),
          ),
          _NavItem(
            icon: Icons.event_busy_outlined,
            activeIcon: Icons.event_busy,
            label: 'Leave',
            selected: currentTab == AppTab.leave,
            theme: theme,
            onTap: () => onTabSelected(AppTab.leave),
          ),
          _NavItem(
            icon: Icons.contact_phone_outlined,
            activeIcon: Icons.contact_phone,
            label: 'Directory',
            selected: currentTab == AppTab.directory,
            theme: theme,
            onTap: () => onTabSelected(AppTab.directory),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final ThemeData theme;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? theme.colorScheme.primary : theme.colorScheme.secondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
                height: 16 / 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
