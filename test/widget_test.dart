import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfarer/main.dart';
import 'package:wayfarer/models/trip.dart';
import 'package:wayfarer/screens/settings_screen.dart';
import 'package:wayfarer/screens/trip_detail_screen.dart';
import 'package:wayfarer/screens/trip_form_screen.dart';
import 'package:wayfarer/state/app_state.dart';
import 'package:wayfarer/state/settings_controller.dart';

Future<AppState> _freshState() async {
  // In-memory storage, so tests never touch real device data.
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return AppState.load();
}

Future<AppState> _reloadState() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  return AppState.load();
}

Future<void> _scrollTo(WidgetTester tester, Finder target, Finder screen) async {
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find.descendant(of: screen, matching: find.byType(Scrollable)).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('App launches on Discover with sample places', (WidgetTester tester) async {
    await tester.pumpWidget(WayfarerApp(state: await _freshState()));
    await tester.pump();

    expect(find.text('Wayfarer'), findsOneWidget);
    expect(find.text('Canadian Automotive Museum'), findsOneWidget);
  });

  testWidgets('Searching filters the place list', (WidgetTester tester) async {
    await tester.pumpWidget(WayfarerApp(state: await _freshState()));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'museum');
    await tester.pump();

    expect(find.text('Canadian Automotive Museum'), findsOneWidget);
    expect(find.text('Lakeview Park'), findsNothing);
  });

  testWidgets('New trip form shows validation errors when empty', (WidgetTester tester) async {
    await tester.pumpWidget(WayfarerApp(state: await _freshState()));
    await tester.pump();

    await tester.tap(find.text('New trip'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create trip'));
    await tester.pump();

    expect(find.text('Please name your trip'), findsOneWidget);
    expect(find.text('Pick your trip dates'), findsOneWidget);
  });

  testWidgets('Deleting a trip and Undo restore its stops and saved data', (
    WidgetTester tester,
  ) async {
    final AppState app = await _freshState();
    final Trip trip = app.trips.upcomingTrips.first;
    final int tripCount = app.trips.trips.length;
    await tester.pumpWidget(WayfarerApp(state: app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();

    final Finder card = find.byKey(ValueKey<String>(trip.id));
    await tester.drag(card, Offset(-tester.getSize(card).width, 0));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey<String>(trip.id)), findsNothing);
    expect(find.text('Deleted "${trip.name}"'), findsOneWidget);
    expect(app.trips.tripById(trip.id), isNull);
    expect((await _reloadState()).trips.tripById(trip.id), isNull);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    expect(find.byKey(ValueKey<String>(trip.id)), findsOneWidget);
    expect(app.trips.trips.length, tripCount);
    expect(app.trips.tripById(trip.id)!.toJson(), trip.toJson());
    expect((await _reloadState()).trips.tripById(trip.id)!.toJson(), trip.toJson());
    expect(tester.takeException(), isNull);
  });

  testWidgets('A trip can be created through the form and date picker', (
    WidgetTester tester,
  ) async {
    final AppState app = await _freshState();
    final int tripCount = app.trips.trips.length;
    final DateTime today = dateOnly(DateTime.now());
    final DateTime start = DateTime(today.year, today.month, today.day + 2);
    final DateTime end = DateTime(today.year, today.month, today.day + 3);
    await tester.pumpWidget(WayfarerApp(state: app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Trips'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('New trip'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Trip name'), 'Campus afternoon');
    await tester.enterText(find.widgetWithText(TextFormField, 'Destination'), 'Oshawa');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.edit_calendar));
    await tester.pumpAndSettle();

    final Finder picker = find.byType(DateRangePickerDialog);
    final MaterialLocalizations labels = MaterialLocalizations.of(tester.element(picker));
    await tester.tap(find.byTooltip(labels.inputDateModeButtonLabel));
    await tester.pumpAndSettle();
    final Finder dates = find.descendant(of: picker, matching: find.byType(TextField));
    await tester.enterText(dates.first, labels.formatCompactDate(start));
    await tester.enterText(dates.last, labels.formatCompactDate(end));
    await tester.tap(find.text(labels.okButtonLabel));
    await tester.pumpAndSettle();
    expect(picker, findsNothing);

    await tester.tap(
      find.byWidgetPredicate(
        (Widget widget) => widget is Semantics && widget.properties.label == 'Colour 2',
      ),
    );
    final Finder form = find.byType(TripFormScreen);
    await _scrollTo(tester, find.byType(SwitchListTile), form);
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.widgetWithText(TextFormField, 'Notes (optional)'), form);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes (optional)'),
      'Bring water and a camera.',
    );
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Create trip'), form);
    await tester.tap(find.text('Create trip'));
    await tester.pumpAndSettle();

    expect(form, findsNothing);
    expect(find.text('Campus afternoon'), findsOneWidget);
    expect(find.text('Created "Campus afternoon"'), findsOneWidget);
    expect(app.trips.trips.length, tripCount + 1);
    final Trip trip = app.trips.trips.singleWhere((Trip t) => t.name == 'Campus afternoon');
    expect(trip.destination, 'Oshawa');
    expect(trip.startDate, start);
    expect(trip.endDate, end);
    expect(trip.notes, 'Bring water and a camera.');
    expect(trip.colorIndex, 1);
    expect(trip.reminder, isFalse);
    expect((await _reloadState()).trips.tripById(trip.id)!.toJson(), trip.toJson());

    await tester.tap(find.text('Campus afternoon'));
    await tester.pumpAndSettle();
    expect(find.byType(TripDetailScreen), findsOneWidget);
    expect(find.text('Oshawa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings selected in the UI survive an app-state reload', (
    WidgetTester tester,
  ) async {
    final AppState app = await _freshState();
    await tester.pumpWidget(WayfarerApp(state: app));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Teal'));
    await tester.pumpAndSettle();

    final Finder settings = find.byType(SettingsScreen);
    await _scrollTo(tester, find.byType(Slider), settings);
    final Rect slider = tester.getRect(find.byType(Slider));
    await tester.tapAt(Offset(slider.left + slider.width * 0.75, slider.center.dy));
    await tester.pumpAndSettle();
    final double textScale = app.settings.textScale;
    expect(textScale, greaterThan(1.0));

    await _scrollTo(tester, find.text('Miles'), settings);
    await tester.tap(find.text('Miles'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Show temperature in °F'), settings);
    await tester.tap(find.text('Show temperature in °F'));
    await tester.pumpAndSettle();
    await _scrollTo(tester, find.text('Display name'), settings);
    await tester.tap(find.text('Display name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Suryansh');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    final AppState reloaded = await _reloadState();
    expect(identical(reloaded.settings, app.settings), isFalse);
    expect(reloaded.settings.themeMode, ThemeMode.dark);
    expect(reloaded.settings.accent, AccentColor.teal);
    expect(reloaded.settings.textScale, textScale);
    expect(reloaded.settings.distanceUnit, DistanceUnit.mi);
    expect(reloaded.settings.tempUnit, TempUnit.fahrenheit);
    expect(reloaded.settings.displayName, 'Suryansh');

    await tester.pumpWidget(WayfarerApp(state: reloaded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Suryansh'), findsOneWidget);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SegmentedButton<ThemeMode>>(find.byType(SegmentedButton<ThemeMode>)).selected,
      <ThemeMode>{ThemeMode.dark},
    );
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Teal')).selected, isTrue);
    expect(Theme.of(tester.element(settings)).brightness, Brightness.dark);
    await _scrollTo(tester, find.byType(Slider), settings);
    expect(tester.widget<Slider>(find.byType(Slider)).value, textScale);
    expect(tester.takeException(), isNull);
  });

  test('Trip survives a JSON round trip', () {
    final Trip trip = Trip(
      id: 't1',
      name: 'Test',
      destination: 'Oshawa',
      startDate: DateTime(2026, 11, 14),
      endDate: DateTime(2026, 11, 15),
      stops: <TripStop>[
        TripStop(id: 's1', title: 'Stop', date: DateTime(2026, 11, 15), minutes: 600),
      ],
    );
    final Trip copy = Trip.fromJson(trip.toJson());
    expect(copy.name, 'Test');
    expect(copy.dayCount, 2);
    expect(copy.stops.single.time, const TimeOfDay(hour: 10, minute: 0));
  });
}
