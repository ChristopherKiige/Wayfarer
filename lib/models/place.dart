import 'package:flutter/material.dart';

/// The four kinds of outing the Discover screen can filter by.
enum PlaceCategory {
  outdoors('Outdoors', Icons.park, Color(0xFF7FB77E)),
  food('Food', Icons.restaurant, Color(0xFFF2A65A)),
  culture('Culture', Icons.museum, Color(0xFF9B8AD8)),
  fun('Fun', Icons.local_activity, Color(0xFF5DA9E9));

  const PlaceCategory(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

/// A place the user can discover, save, and add to a trip.
///
/// For now these come from a hardcoded list (see data/sample_places.dart).
/// The plan is to fill this from the Google Places API for the final.
class Place {
  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.rating,
  });

  final String id;
  final String name;
  final PlaceCategory category;
  final String description;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
}
