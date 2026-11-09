import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_data.dart';
import '../models/trip.dart';
import '../services/notification_service.dart';

/// Owns the user's trips and saved places, and writes them to local
/// storage (shared_preferences, as JSON) after every change.
///
/// Screens listen to this with ListenableBuilder, so any change made on one
/// screen shows up everywhere else straight away.
class TripStore extends ChangeNotifier {
  TripStore(this._prefs) {
    final String? raw = _prefs.getString(_kTrips);
    if (raw == null) {
      // First launch: start with sample trips so the app isn't empty.
      _trips = buildSampleTrips();
      _savedPlaceIds = <String>{'parkwood', 'lakeview-park'};
      _save();
    } else {
      _trips = _decode(raw);
      _savedPlaceIds = (_prefs.getStringList(_kSaved) ?? <String>[]).toSet();
    }
  }

  static const String _kTrips = 'data.trips';
  static const String _kSaved = 'data.savedPlaces';

  final SharedPreferences _prefs;
  late List<Trip> _trips;
  late Set<String> _savedPlaceIds;

  /// Trips sorted by start date.
  List<Trip> get trips {
    final List<Trip> sorted = List<Trip>.of(_trips)
      ..sort((Trip a, Trip b) => a.startDate.compareTo(b.startDate));
    return List<Trip>.unmodifiable(sorted);
  }

  List<Trip> get upcomingTrips => trips.where((Trip t) => !t.isPast).toList();
  List<Trip> get pastTrips => trips.where((Trip t) => t.isPast).toList().reversed.toList();

  /// The next trip that hasn't finished yet, if any.
  Trip? get nextTrip {
    final List<Trip> upcoming = upcomingTrips;
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Set<String> get savedPlaceIds => Set<String>.unmodifiable(_savedPlaceIds);

  int get totalStops => _trips.fold(0, (int sum, Trip t) => sum + t.stops.length);

  Trip? tripById(String id) {
    for (final Trip t in _trips) {
      if (t.id == id) return t;
    }
    return null;
  }

  // ---- Trips ----

  void addTrip(Trip trip) async {
    _trips.add(trip);
    _changed();

    if (trip.reminder) {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleTripReminder(
        id: trip.id.hashCode,
        tripTitle: trip.name,
        scheduledDate: trip.startDate.subtract(const Duration(days: 1)),
      );
    }
  }

  void updateTrip(Trip trip) async {
    final int i = _trips.indexWhere((Trip t) => t.id == trip.id);
    if (i == -1) return;
    final List<TripStop> kept = trip.stops
        .where(
          (TripStop s) =>
      !dateOnly(s.date).isBefore(dateOnly(trip.startDate)) &&
          !dateOnly(s.date).isAfter(dateOnly(trip.endDate)),
    )
        .toList();
    final updatedTrip = trip.copyWith(stops: kept);
    _trips[i] = updatedTrip;
    _changed();

    if (updatedTrip.reminder) {
      await NotificationService.instance.requestPermissions();
      await NotificationService.instance.scheduleTripReminder(
        id: updatedTrip.id.hashCode,
        tripTitle: updatedTrip.name,
        scheduledDate: updatedTrip.startDate.subtract(const Duration(days: 1)),
      );
    } else {
      await NotificationService.instance.cancelReminder(updatedTrip.id.hashCode);
    }
  }

  void removeTrip(String id) async {
    _trips.removeWhere((Trip t) => t.id == id);
    _changed();
    await NotificationService.instance.cancelReminder(id.hashCode);
  }

  // ---- Stops ----

  void addStop(String tripId, TripStop stop) {
    final Trip? trip = tripById(tripId);
    if (trip == null) return;
    _replace(trip.copyWith(stops: <TripStop>[...trip.stops, stop]));
  }

  void updateStop(String tripId, TripStop stop) {
    final Trip? trip = tripById(tripId);
    if (trip == null) return;
    _replace(
      trip.copyWith(
        stops: <TripStop>[for (final TripStop s in trip.stops) s.id == stop.id ? stop : s],
      ),
    );
  }

  void removeStop(String tripId, String stopId) {
    final Trip? trip = tripById(tripId);
    if (trip == null) return;
    _replace(trip.copyWith(stops: trip.stops.where((TripStop s) => s.id != stopId).toList()));
  }

  // ---- Saved places ----

  bool isSaved(String placeId) => _savedPlaceIds.contains(placeId);

  /// Saves or un-saves a place. Returns true if it is now saved.
  bool toggleSaved(String placeId) {
    final bool nowSaved = !_savedPlaceIds.remove(placeId);
    if (nowSaved) _savedPlaceIds.add(placeId);
    _changed();
    return nowSaved;
  }

  /// Puts the sample trips and saved places back (handy before a demo).
  void resetToSamples() {
    _trips = buildSampleTrips();
    _savedPlaceIds = <String>{'parkwood', 'lakeview-park'};
    _changed();
  }

  // ---- Internals ----

  void _replace(Trip trip) {
    final int i = _trips.indexWhere((Trip t) => t.id == trip.id);
    if (i != -1) _trips[i] = trip;
    _changed();
  }

  void _changed() {
    _save();
    notifyListeners();
  }

  void _save() {
    _prefs.setString(_kTrips, jsonEncode(_trips.map((Trip t) => t.toJson()).toList()));
    _prefs.setStringList(_kSaved, _savedPlaceIds.toList());
  }

  static List<Trip> _decode(String raw) {
    try {
      final List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((dynamic e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint('Could not read saved trips, starting fresh: $e');
      return <Trip>[];
    }
  }
}
