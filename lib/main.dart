import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'state/app_state.dart';
import 'theme.dart';

Future<void> main() async {
  // Needed before reading local storage in AppState.load().
  WidgetsFlutterBinding.ensureInitialized();
  final AppState state = await AppState.load();
  runApp(WayfarerApp(state: state));
}

class WayfarerApp extends StatelessWidget {
  const WayfarerApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      // Rebuild the whole app when a UI setting changes, so theme, accent
      // colour and text size update instantly.
      child: ListenableBuilder(
        listenable: state.settings,
        builder: (BuildContext context, Widget? _) {
          return MaterialApp(
            title: 'Wayfarer',
            debugShowCheckedModeBanner: false,
            themeMode: state.settings.themeMode,
            theme: buildTheme(state.settings.accent.color, Brightness.light),
            darkTheme: buildTheme(state.settings.accent.color, Brightness.dark),
            builder: (BuildContext context, Widget? child) {
              return MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(state.settings.textScale)),
                child: child!,
              );
            },
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
