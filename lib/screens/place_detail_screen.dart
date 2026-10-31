import 'package:flutter/material.dart';

import '../models/place.dart';
import '../models/trip.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/stop_editor_dialog.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';

/// Details for one place, with "Save" and "Add to trip".
class PlaceDetailScreen extends StatelessWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  /// Add to trip: pick a trip (bottom sheet), then a day and time (dialog
  /// with date and time pickers), then confirm with a snackbar.
  Future<void> _addToTrip(BuildContext context) async {
    final AppState app = AppScope.read(context);
    final List<Trip> trips = app.trips.upcomingTrips;

    Trip? chosen;
    if (trips.isEmpty) {
      chosen = await _offerNewTrip(context);
    } else {
      final String? pickedId = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (BuildContext sheetContext) => _TripPickerSheet(trips: trips),
      );
      if (pickedId == null || !context.mounted) return;
      if (pickedId == _TripPickerSheet.newTrip) {
        chosen = await Navigator.push<Trip>(
          context,
          MaterialPageRoute<Trip>(builder: (_) => const TripFormScreen()),
        );
      } else {
        chosen = app.trips.tripById(pickedId);
      }
    }
    if (chosen == null || !context.mounted) return;

    final TripStop? stop = await showStopEditor(context, trip: chosen, place: place);
    if (stop == null || !context.mounted) return;

    app.trips.addStop(chosen.id, stop);
    final String tripId = chosen.id;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added to ${chosen.name}'),
        action: SnackBarAction(
          label: 'View trip',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => TripDetailScreen(tripId: tripId)),
          ),
        ),
      ),
    );
  }

  Future<Trip?> _offerNewTrip(BuildContext context) async {
    final bool? create = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('No upcoming trips'),
        content: const Text('Create a trip first, then add this place to it.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Create trip'),
          ),
        ],
      ),
    );
    if (create != true || !context.mounted) return null;
    return Navigator.push<Trip>(
      context,
      MaterialPageRoute<Trip>(builder: (_) => const TripFormScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final ThemeData theme = Theme.of(context);
    final String distance = formatDistance(distanceFromHome(place), app.settings.distanceUnit);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            backgroundColor: place.category.color,
            foregroundColor: Colors.white,
            actions: <Widget>[
              ListenableBuilder(
                listenable: app.trips,
                builder: (BuildContext context, Widget? _) {
                  final bool saved = app.trips.isSaved(place.id);
                  return IconButton(
                    tooltip: saved ? 'Remove from saved' : 'Save',
                    icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                    onPressed: () {
                      final bool nowSaved = app.trips.toggleSaved(place.id);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              nowSaved ? 'Saved to your profile' : 'Removed from saved',
                            ),
                          ),
                        );
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(place.name, style: const TextStyle(color: Colors.white)),
              background: Container(
                color: place.category.color,
                alignment: Alignment.center,
                child: Icon(
                  place.category.icon,
                  size: 96,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList.list(
              children: <Widget>[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    Chip(
                      avatar: Icon(place.category.icon, size: 16),
                      label: Text(place.category.label),
                    ),
                    Chip(
                      avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                      label: Text('${place.rating}'),
                    ),
                    Chip(
                      avatar: const Icon(Icons.near_me, size: 16),
                      label: Text('$distance away'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(place.description, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined),
                  title: Text(place.address),
                  subtitle: Text(
                    '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _addToTrip(context),
                  icon: const Icon(Icons.playlist_add),
                  label: const Text('Add to a trip'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet listing upcoming trips, plus "New trip". Pops the chosen
/// trip's id, or [newTrip].
class _TripPickerSheet extends StatelessWidget {
  const _TripPickerSheet({required this.trips});

  static const String newTrip = '__new__';

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Add to which trip?', style: Theme.of(context).textTheme.titleMedium),
          ),
          for (final Trip t in trips)
            ListTile(
              leading: CircleAvatar(
                backgroundColor: t.color,
                child: const Icon(Icons.luggage, color: Colors.white),
              ),
              title: Text(t.name),
              subtitle: Text(formatDateRange(t.startDate, t.endDate)),
              onTap: () => Navigator.pop(context, t.id),
            ),
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.add)),
            title: const Text('New trip'),
            onTap: () => Navigator.pop(context, newTrip),
          ),
        ],
      ),
    );
  }
}
