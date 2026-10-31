import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'discover_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'trips_screen.dart';

/// The main frame: bottom navigation with four tabs. The selected tab lives
/// in AppState so the drawer (and other screens) can switch tabs too.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Tabs are only built the first time they're opened (the map loads
  // tiles, so there is no point building it until it's needed). After that
  // the IndexedStack keeps each tab's state, e.g. scroll position.
  final Set<int> _opened = <int>{AppState.discoverTab};

  Widget _buildTab(int index) {
    switch (index) {
      case AppState.tripsTab:
        return const TripsScreen();
      case AppState.mapTab:
        return const MapScreen();
      case AppState.profileTab:
        return const ProfileScreen();
      default:
        return const DiscoverScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);

    return ValueListenableBuilder<int>(
      valueListenable: app.tab,
      builder: (BuildContext context, int index, Widget? _) {
        _opened.add(index);
        return Scaffold(
          body: IndexedStack(
            index: index,
            children: <Widget>[
              for (int i = 0; i < 4; i++)
                _opened.contains(i) ? _buildTab(i) : const SizedBox.shrink(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: (int i) => app.tab.value = i,
            destinations: const <NavigationDestination>[
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Discover',
              ),
              NavigationDestination(
                icon: Icon(Icons.list_alt_outlined),
                selectedIcon: Icon(Icons.list_alt),
                label: 'Trips',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
