import 'package:flutter/material.dart';

import '../screens/settings_screen.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

/// Side drawer shared by all four tabs: jumps between tabs, has a quick
/// dark-mode switch, and opens Settings and About.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final ColorScheme scheme = Theme.of(context).colorScheme;

    void goToTab(int index) {
      Navigator.pop(context); // close the drawer
      app.tab.value = index;
    }

    return Drawer(
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[app.settings, app.tab]),
        builder: (BuildContext context, Widget? _) {
          final int current = app.tab.value;
          final bool isDark =
              app.settings.themeMode == ThemeMode.dark ||
              (app.settings.themeMode == ThemeMode.system &&
                  MediaQuery.platformBrightnessOf(context) == Brightness.dark);

          return ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(color: scheme.primary),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: scheme.onPrimary,
                      child: Text(
                        initials(app.settings.displayName),
                        style: TextStyle(color: scheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      app.settings.displayName,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Plan your next outing',
                      style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              _tabTile(Icons.explore, 'Discover', AppState.discoverTab, current, goToTab),
              _tabTile(Icons.list_alt, 'My trips', AppState.tripsTab, current, goToTab),
              _tabTile(Icons.map, 'Map', AppState.mapTab, current, goToTab),
              _tabTile(Icons.person, 'Profile', AppState.profileTab, current, goToTab),
              const Divider(),
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                value: isDark,
                onChanged: (bool on) {
                  app.settings.themeMode = on ? ThemeMode.dark : ThemeMode.light;
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('About Wayfarer'),
                onTap: () {
                  Navigator.pop(context);
                  showAboutDialog(
                    context: context,
                    applicationName: 'Wayfarer',
                    applicationVersion: 'Check-in build (Part 2)',
                    applicationIcon: Icon(Icons.explore, color: scheme.primary, size: 40),
                    children: const <Widget>[
                      Text('A local outings and trip planner. CSCI 3101U, Fall 2026.'),
                      SizedBox(height: 8),
                      Text('Weather by Open-Meteo. Map data © OpenStreetMap contributors.'),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabTile(IconData icon, String label, int index, int current, void Function(int) onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: index == current,
      onTap: () => onTap(index),
    );
  }
}
