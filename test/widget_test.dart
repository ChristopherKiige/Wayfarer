import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wayfarer/main.dart';
import 'package:wayfarer/models/trip.dart';
import 'package:wayfarer/state/app_state.dart';

Future<AppState> _freshState() async {
  // In-memory storage, so tests never touch real device data.
  SharedPreferences.setMockInitialValues(<String, Object>{});
  return AppState.load();
}

void main() {
  testWidgets('App launches on Discover with sample places', (WidgetTester tester) async {
    await tester.pumpWidget(WayfarerApp(state: await _freshState()));
    await tester.pump();

    expect(find.text('Wayfarer'), findsOneWidget);
    expect(find.text('Lakeview Park'), findsOneWidget);
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
    await tester.tap(find.text('Create trip'));
    await tester.pump();

    expect(find.text('Please name your trip'), findsOneWidget);
    expect(find.text('Pick your trip dates'), findsOneWidget);
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
