import 'package:flutter/material.dart';

/// Cover colours a trip can use. Stored as an index so the JSON stays small.
const List<Color> tripColors = <Color>[
  Color(0xFF2B5BA8),
  Color(0xFF00897B),
  Color(0xFF6A4FB3),
  Color(0xFFE0663A),
  Color(0xFFC2185B),
  Color(0xFF5D7A2E),
];

/// Strips the time part so trip dates compare cleanly.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole calendar days from [a] to [b]. Uses UTC so a daylight-saving
/// change in between can't make it off by one.
int daysBetween(DateTime a, DateTime b) =>
    DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// One stop on a trip's itinerary, e.g. "Lakeview Park, Sat 10:00".
class TripStop {
  const TripStop({
    required this.id,
    required this.title,
    required this.date,
    required this.minutes,
    this.placeId,
    this.note = '',
  });

  final String id;
  final String title;

  /// The day of the stop (no time part).
  final DateTime date;

  /// Time of day as minutes after midnight (600 = 10:00 am).
  final int minutes;

  /// Set when the stop came from a Discover place, so it can go on the map.
  final String? placeId;
  final String note;

  TimeOfDay get time => TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'date': date.toIso8601String(),
    'minutes': minutes,
    'placeId': placeId,
    'note': note,
  };

  factory TripStop.fromJson(Map<String, dynamic> json) => TripStop(
    id: json['id'] as String,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    minutes: json['minutes'] as int,
    placeId: json['placeId'] as String?,
    note: (json['note'] as String?) ?? '',
  );
}

/// A planned trip or outing with its itinerary of stops.
class Trip {
  const Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    this.notes = '',
    this.colorIndex = 0,
    this.reminder = true,
    this.stops = const <TripStop>[],
  });

  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String notes;
  final int colorIndex;

  /// Whether the user wants a reminder before the trip. Saved now; the
  /// notification itself is planned for the final submission.
  final bool reminder;
  final List<TripStop> stops;

  Color get color => tripColors[colorIndex % tripColors.length];

  /// Number of days, counting both the first and last day.
  int get dayCount => daysBetween(startDate, endDate) + 1;

  /// Every date of the trip, in order.
  List<DateTime> get days => List<DateTime>.generate(
    dayCount,
    (int i) => DateTime(startDate.year, startDate.month, startDate.day + i),
  );

  bool get isPast => dateOnly(endDate).isBefore(dateOnly(DateTime.now()));

  bool get isOngoing {
    final DateTime today = dateOnly(DateTime.now());
    return !today.isBefore(dateOnly(startDate)) && !today.isAfter(dateOnly(endDate));
  }

  /// Stops on [day], earliest first.
  List<TripStop> stopsOn(DateTime day) {
    final List<TripStop> list =
        stops.where((TripStop s) => DateUtils.isSameDay(s.date, day)).toList()
          ..sort((TripStop a, TripStop b) => a.minutes.compareTo(b.minutes));
    return list;
  }

  /// All stops in itinerary order.
  List<TripStop> get orderedStops => <TripStop>[for (final DateTime day in days) ...stopsOn(day)];

  Trip copyWith({
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    int? colorIndex,
    bool? reminder,
    List<TripStop>? stops,
  }) {
    return Trip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      notes: notes ?? this.notes,
      colorIndex: colorIndex ?? this.colorIndex,
      reminder: reminder ?? this.reminder,
      stops: stops ?? this.stops,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'destination': destination,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'notes': notes,
    'colorIndex': colorIndex,
    'reminder': reminder,
    'stops': stops.map((TripStop s) => s.toJson()).toList(),
  };

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
    id: json['id'] as String,
    name: json['name'] as String,
    destination: json['destination'] as String,
    startDate: DateTime.parse(json['startDate'] as String),
    endDate: DateTime.parse(json['endDate'] as String),
    notes: (json['notes'] as String?) ?? '',
    colorIndex: (json['colorIndex'] as int?) ?? 0,
    reminder: (json['reminder'] as bool?) ?? true,
    stops: ((json['stops'] as List<dynamic>?) ?? <dynamic>[])
        .map((dynamic s) => TripStop.fromJson(s as Map<String, dynamic>))
        .toList(),
  );
}

/// Simple unique id based on the clock; good enough for local data.
String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
