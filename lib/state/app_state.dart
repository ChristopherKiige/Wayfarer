import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/weather_service.dart';
import 'settings_controller.dart';
import 'trip_store.dart';

/// Everything the screens share: settings, trips, the selected bottom tab
/// and the weather service. Created once in main() and handed down the
/// widget tree by [AppScope].
class AppState {
  AppState._(SharedPreferences prefs)
    : settings = SettingsController(prefs),
      trips = TripStore(prefs);

  final SettingsController settings;
  final TripStore trips;
  final WeatherService weather = WeatherService();

  /// Which bottom-navigation tab is showing. The drawer changes it too.
  final ValueNotifier<int> tab = ValueNotifier<int>(0);

  /// Bottom tab indexes.
  static const int discoverTab = 0;
  static const int tripsTab = 1;
  static const int mapTab = 2;
  static const int profileTab = 3;

  static Future<AppState> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return AppState._(prefs);
  }
}

/// Makes the [AppState] reachable from any widget.
///
/// `AppScope.of(context)` also subscribes the widget to settings changes,
/// so anything that shows a unit, name or colour rebuilds when the user
/// changes it in Settings. Use `AppScope.read(context)` in initState or
/// callbacks, where subscribing isn't allowed or needed.
class AppScope extends InheritedNotifier<SettingsController> {
  AppScope({super.key, required this.state, required super.child})
    : super(notifier: state.settings);

  final AppState state;

  static AppState of(BuildContext context) {
    final AppScope? scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget');
    return scope!.state;
  }

  static AppState read(BuildContext context) {
    final AppScope? scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this widget');
    return scope!.state;
  }
}
