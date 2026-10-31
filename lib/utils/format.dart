import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../state/settings_controller.dart';

const List<String> _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const List<String> _weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Nov 14"
String formatShortDate(DateTime d) => '${_months[d.month - 1]} ${d.day}';

/// "Sat, Nov 14"
String formatDayDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${formatShortDate(d)}';

/// "Nov 14 – 15, 2026", "Nov 30 – Dec 2, 2026" or "Nov 14, 2026" for one day.
String formatDateRange(DateTime start, DateTime end) {
  if (DateUtils.isSameDay(start, end)) return '${formatShortDate(start)}, ${start.year}';
  if (start.year == end.year && start.month == end.month) {
    return '${formatShortDate(start)} – ${end.day}, ${end.year}';
  }
  if (start.year == end.year) {
    return '${formatShortDate(start)} – ${formatShortDate(end)}, ${end.year}';
  }
  return '${formatShortDate(start)}, ${start.year} – ${formatShortDate(end)}, ${end.year}';
}

/// "In 6 days", "Today", "Happening now", "Finished".
String tripCountdown(Trip trip) {
  final int days = daysBetween(DateTime.now(), trip.startDate);
  if (trip.isPast) return 'Finished';
  if (trip.isOngoing) return days == 0 ? 'Starts today' : 'Happening now';
  if (days == 1) return 'Tomorrow';
  return 'In $days days';
}

/// Straight-line distance in km between two coordinates (haversine).
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadiusKm = 6371;
  double rad(double deg) => deg * math.pi / 180;
  final double dLat = rad(lat2 - lat1);
  final double dLon = rad(lon2 - lon1);
  final double a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

/// Distance from home to [place], in km.
double distanceFromHome(Place place) =>
    distanceKm(homeLatitude, homeLongitude, place.latitude, place.longitude);

/// "3.2 km" or "2.0 mi" depending on the user's setting.
String formatDistance(double km, DistanceUnit unit) {
  if (unit == DistanceUnit.mi) return '${(km * 0.621371).toStringAsFixed(1)} mi';
  return '${km.toStringAsFixed(1)} km';
}

/// "Lakeview Park" -> "LP", "Christopher Kiige" -> "CK".
String initials(String name) {
  final List<String> parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((String p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}
