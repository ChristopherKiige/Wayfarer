import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/empty_state.dart';
import '../widgets/stop_editor_dialog.dart';
import 'map_screen.dart';
import 'place_detail_screen.dart';
import 'trip_form_screen.dart';

enum _TripAction { map, delete }

enum _StopAction { edit, delete }

/// One trip: summary card plus a day-by-day itinerary of stops.
class TripDetailScreen extends StatelessWidget {
  const TripDetailScreen({super.key, required this.tripId});

  final String tripId;

  Future<void> _addStop(BuildContext context, Trip trip) async {
    final TripStop? stop = await showStopEditor(context, trip: trip);
    if (stop == null || !context.mounted) return;
    AppScope.read(context).trips.addStop(trip.id, stop);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added ${stop.title} on ${formatDayDate(stop.date)}')));
  }

  Future<void> _editStop(BuildContext context, Trip trip, TripStop stop) async {
    final TripStop? edited = await showStopEditor(context, trip: trip, existing: stop);
    if (edited == null || !context.mounted) return;
    AppScope.read(context).trips.updateStop(trip.id, edited);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stop updated')));
  }

  void _deleteStop(BuildContext context, Trip trip, TripStop stop) {
    final AppState app = AppScope.read(context);
    app.trips.removeStop(trip.id, stop.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Removed ${stop.title}'),
          action: SnackBarAction(label: 'Undo', onPressed: () => app.trips.addStop(trip.id, stop)),
        ),
      );
  }

  Future<void> _confirmDeleteTrip(BuildContext context, Trip trip) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: const Icon(Icons.delete_outline),
        title: Text('Delete "${trip.name}"?'),
        content: Text('This removes the trip and its ${trip.stops.length} stops.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final AppState app = AppScope.read(context);
    // Grab the messenger before leaving this screen; it belongs to the app,
    // so the snackbar still shows on the previous screen.
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    app.trips.removeTrip(trip.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${trip.name}"'),
          action: SnackBarAction(label: 'Undo', onPressed: () => app.trips.addTrip(trip)),
        ),
      );
  }

  void _openOnMap(BuildContext context, Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => MapScreen(initialTripId: trip.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);

    return ListenableBuilder(
      listenable: app.trips,
      builder: (BuildContext context, Widget? _) {
        final Trip? trip = app.trips.tripById(tripId);
        if (trip == null) {
          // Happens for a moment after the trip is deleted.
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.luggage_outlined,
              title: 'Trip not found',
              message: 'It may have been deleted.',
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(trip.name),
            backgroundColor: trip.color,
            foregroundColor: Colors.white,
            actions: <Widget>[
              IconButton(
                tooltip: 'Edit trip',
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final Trip? saved = await Navigator.push<Trip>(
                    context,
                    MaterialPageRoute<Trip>(builder: (_) => TripFormScreen(existing: trip)),
                  );
                  if (saved != null && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Trip updated')));
                  }
                },
              ),
              PopupMenuButton<_TripAction>(
                onSelected: (_TripAction a) {
                  switch (a) {
                    case _TripAction.map:
                      _openOnMap(context, trip);
                    case _TripAction.delete:
                      _confirmDeleteTrip(context, trip);
                  }
                },
                itemBuilder: (_) => const <PopupMenuEntry<_TripAction>>[
                  PopupMenuItem<_TripAction>(
                    value: _TripAction.map,
                    child: ListTile(leading: Icon(Icons.map), title: Text('View on map')),
                  ),
                  PopupMenuItem<_TripAction>(
                    value: _TripAction.delete,
                    child: ListTile(
                      leading: Icon(Icons.delete_outline),
                      title: Text('Delete trip'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'trip-detail-fab',
            onPressed: () => _addStop(context, trip),
            icon: const Icon(Icons.add_location_alt),
            label: const Text('Add stop'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: <Widget>[
              _SummaryCard(trip: trip, onMap: () => _openOnMap(context, trip)),
              const SizedBox(height: 8),
              for (final (int i, DateTime day) in trip.days.indexed) ...<Widget>[
                _DayHeader(index: i + 1, day: day),
                if (trip.stopsOn(day).isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'Nothing planned yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                for (final TripStop stop in trip.stopsOn(day))
                  _StopTile(
                    stop: stop,
                    color: trip.color,
                    onAction: (_StopAction a) {
                      switch (a) {
                        case _StopAction.edit:
                          _editStop(context, trip, stop);
                        case _StopAction.delete:
                          _deleteStop(context, trip, stop);
                      }
                    },
                  ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.trip, required this.onMap});

  final Trip trip;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.place, color: trip.color),
                const SizedBox(width: 6),
                Expanded(child: Text(trip.destination, style: theme.textTheme.titleMedium)),
                Chip(
                  label: Text(tripCountdown(trip)),
                  backgroundColor: trip.color.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${formatDateRange(trip.startDate, trip.endDate)} · '
              '${trip.dayCount} ${trip.dayCount == 1 ? 'day' : 'days'} · '
              '${trip.stops.length} ${trip.stops.length == 1 ? 'stop' : 'stops'}',
              style: theme.textTheme.bodyMedium,
            ),
            if (trip.reminder)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.notifications_active,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text('Reminder the day before', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            if (trip.notes.isNotEmpty) ...<Widget>[
              const Divider(height: 24),
              Text(
                trip.notes,
                style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onMap,
                icon: const Icon(Icons.map_outlined),
                label: const Text('View route on map'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.index, required this.day});

  final int index;
  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        'Day $index · ${formatDayDate(day)}',
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({required this.stop, required this.color, required this.onAction});

  final TripStop stop;
  final Color color;
  final ValueChanged<_StopAction> onAction;

  @override
  Widget build(BuildContext context) {
    final Place? place = placeById(stop.placeId);
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: place?.category.color ?? color,
          child: Icon(place?.category.icon ?? Icons.flag, color: Colors.white, size: 20),
        ),
        title: Text(stop.title),
        subtitle: Text(
          stop.note.isEmpty
              ? stop.time.format(context)
              : '${stop.time.format(context)} · ${stop.note}',
          style: theme.textTheme.bodySmall,
        ),
        onTap: place == null
            ? () => onAction(_StopAction.edit)
            : () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(place: place)),
              ),
        trailing: PopupMenuButton<_StopAction>(
          onSelected: onAction,
          itemBuilder: (_) => const <PopupMenuEntry<_StopAction>>[
            PopupMenuItem<_StopAction>(value: _StopAction.edit, child: Text('Edit')),
            PopupMenuItem<_StopAction>(value: _StopAction.delete, child: Text('Remove')),
          ],
        ),
      ),
    );
  }
}
