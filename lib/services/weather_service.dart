import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Current conditions for one spot.
class Weather {
  const Weather({required this.celsius, required this.code});

  final double celsius;

  /// WMO weather code from Open-Meteo (0 = clear, 61 = rain, ...).
  final int code;

  double get fahrenheit => celsius * 9 / 5 + 32;

  IconData get icon {
    if (code == 0) return Icons.wb_sunny;
    if (code <= 3) return Icons.wb_cloudy;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 95) return Icons.thunderstorm;
    return Icons.umbrella; // drizzle, rain and showers
  }

  String get description {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Cloudy';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Showers';
    if (code >= 95) return 'Thunderstorm';
    return 'Mixed';
  }
}

/// Fetches live weather over HTTP from Open-Meteo (free, no API key).
class WeatherService {
  Future<Weather> current(double latitude, double longitude) async {
    final Uri uri = Uri.https('api.open-meteo.com', '/v1/forecast', <String, String>{
      'latitude': latitude.toStringAsFixed(4),
      'longitude': longitude.toStringAsFixed(4),
      'current': 'temperature_2m,weather_code',
    });

    final http.Response res = await http.get(uri).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('Weather request failed (${res.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(res.body) as Map<String, dynamic>;
    final Map<String, dynamic> now = body['current'] as Map<String, dynamic>;
    return Weather(
      celsius: (now['temperature_2m'] as num).toDouble(),
      code: (now['weather_code'] as num).toInt(),
    );
  }
}
