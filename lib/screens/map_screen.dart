import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../data/sample_data.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/app_drawer.dart';
import 'place_detail_screen.dart';

/// OpenStreetMap view (flutter_map, no API key needed).
///
/// "All places" shows every Discover place. Picking a trip shows its stops
/// numbered in itinerary order, joined by a line.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.initialTripId});

  /// When set, the map was opened from a trip and starts on that trip.
  final String? initialTripId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _home = LatLng(homeLatitude, homeLongitude);

  final MapController _controller = MapController();
  String? _tripId;
  bool _mapReady = false;
  LatLng? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _tripId = widget.initialTripId;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Points for the current selection, in order.
  List<_Pin> _pins(AppState app) {
    final Trip? trip = _tripId == null ? null : app.trips.tripById(_tripId!);
    if (trip == null) {
      return <_Pin>[for (final Place p in samplePlaces) _Pin(place: p)];
    }
    final List<_Pin> pins = <_Pin>[];
    for (final TripStop stop in trip.orderedStops) {
      final Place? p = placeById(stop.placeId);
      if (p != null) pins.add(_Pin(place: p, number: pins.length + 1, stop: stop));
    }
    return pins;
  }

  /// Moves the camera so every pin is visible.
  void _fitTo(List<_Pin> pins) {
    if (!_mapReady) return;
    if (pins.isEmpty) {
      _controller.move(_home, 12);
    } else if (pins.length == 1) {
      _controller.move(pins.first.point, 14);
    } else {
      _controller.fitCamera(
        CameraFit.coordinates(
          coordinates: pins.map((_Pin p) => p.point).toList(),
          padding: const EdgeInsets.fromLTRB(48, 80, 48, 48),
          maxZoom: 15,
        ),
      );
    }
  }

  void _select(AppState app, String? tripId) {
    setState(() => _tripId = tripId);
    _fitTo(_pins(app));
  }

  void _showPin(_Pin pin) {
    final AppState app = AppScope.read(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        final Place p = pin.place;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(p.name, style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  pin.stop == null
                      ? '${p.category.label} · ${formatDistance(distanceFromHome(p), app.settings.distanceUnit)}'
                      : 'Stop ${pin.number} · ${formatDayDate(pin.stop!.date)} at ${pin.stop!.time.format(sheetContext)}',
                ),
                const SizedBox(height: 8),
                Text(p.description),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(place: p)),
                    );
                  },
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Open details'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _goToCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled.')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is permanently denied in settings.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = userLatLng;
      });

      _controller.move(userLatLng, 15.0);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final bool openedFromTrip = widget.initialTripId != null;
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      drawer: openedFromTrip ? null : const AppDrawer(),
      appBar: AppBar(title: const Text('Map')),
      // floatingActionButton: FloatingActionButton.small(
      //   heroTag: 'map-fab',
      //   tooltip: 'Fit all pins',
      //   onPressed: () => _fitTo(_pins(app)),
      //   child: const Icon(Icons.center_focus_strong),
      // ),
      body: ListenableBuilder(
        listenable: app.trips,
        builder: (BuildContext context, Widget? _) {
          // If the selected trip was deleted, fall back to all places.
          if (_tripId != null && app.trips.tripById(_tripId!) == null) _tripId = null;
          final List<_Pin> pins = _pins(app);
          final Trip? trip = _tripId == null ? null : app.trips.tripById(_tripId!);
          final Color lineColor = trip?.color ?? scheme.primary;

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _home,
                    initialZoom: 12,
                    minZoom: 4,
                    maxZoom: 18,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    onMapReady: () {
                      _mapReady = true;
                      _fitTo(_pins(app));
                    },
                  ),
                  children: <Widget>[
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.wayfarer.wayfarer',
                    ),
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _currentPosition!,
                            width: 40,
                            height: 40,
                            child: const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                        ],
                      ),
                    if (trip != null && pins.length > 1)
                      PolylineLayer<Object>(
                        polylines: <Polyline<Object>>[
                          Polyline<Object>(
                            points: pins.map((_Pin p) => p.point).toList(),
                            strokeWidth: 4,
                            color: lineColor.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: <Marker>[
                        const Marker(point: _home, width: 28, height: 28, child: _HomeDot()),
                        for (final _Pin pin in pins)
                          Marker(
                            point: pin.point,
                            width: 40,
                            height: 40,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onTap: () => _showPin(pin),
                              child: _PinIcon(
                                pin: pin,
                                color: pin.number == null ? pin.place.category.color : lineColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const RichAttributionWidget(
                      alignment: AttributionAlignment.bottomLeft,
                      attributions: <SourceAttribution>[
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                right: 16,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'map-location-fab',
                      onPressed: _isLoadingLocation ? null : _goToCurrentLocation,
                      tooltip: 'My Location',
                      child: _isLoadingLocation
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                          : const Icon(Icons.my_location),
                    ),

                    const SizedBox(height: 12),

                    FloatingActionButton.small(
                      heroTag: 'map-fit-fab',
                      tooltip: 'Fit all pins',
                      onPressed: () => _fitTo(_pins(app)),
                      child: const Icon(Icons.center_focus_strong),
                    ),
                  ],
                ),
              ),

              // Trip selector chips over the map.
              Positioned(
                left: 0,
                right: 0,
                top: 8,
                child: SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: <Widget>[
                      _chip(context, 'All places', null, app),
                      for (final Trip t in app.trips.trips) _chip(context, t.name, t.id, app),
                    ],
                  ),
                ),
              ),

              if (trip != null && pins.isEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '"${trip.name}" has no stops linked to a place yet. '
                        'Add a stop from Discover to see it here.',
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String? tripId, AppState app) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _tripId == tripId,
        showCheckmark: false,
        elevation: 2,
        onSelected: (_) => _select(app, tripId),
      ),
    );
  }
}

/// One marker: a place, plus its number and stop when showing a trip.
class _Pin {
  const _Pin({required this.place, this.number, this.stop});

  final Place place;
  final int? number;
  final TripStop? stop;

  LatLng get point => LatLng(place.latitude, place.longitude);
}

class _PinIcon extends StatelessWidget {
  const _PinIcon({required this.pin, required this.color});

  final _Pin pin;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: <Widget>[
        Icon(Icons.location_on, size: 40, color: color),
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: pin.number == null
              ? Icon(pin.place.category.icon, size: 14, color: Colors.white)
              : Text(
                  '${pin.number}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
        ),
      ],
    );
  }
}

class _HomeDot extends StatelessWidget {
  const _HomeDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const <BoxShadow>[BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
    );
  }
}
