import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';

enum _TripFilter { upcoming, past, all }

/// List of the user's trips. Swipe a trip to delete it (with Undo).
class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  _TripFilter _filter = _TripFilter.upcoming;

  Future<void> _createTrip() async {
    final Trip? trip = await Navigator.push<Trip>(
      context,
      MaterialPageRoute<Trip>(builder: (_) => const TripFormScreen()),
    );
    if (trip == null || !mounted) return;
    setState(() => _filter = trip.isPast ? _TripFilter.past : _TripFilter.upcoming);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Created "${trip.name}"')));
  }

  void _deleteTrip(AppState app, Trip trip) {
    app.trips.removeTrip(trip.id);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Deleted "${trip.name}"'),
          action: SnackBarAction(label: 'Undo', onPressed: () => app.trips.addTrip(trip)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(title: const Text('My trips')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'trips-fab',
        onPressed: _createTrip,
        icon: const Icon(Icons.add),
        label: const Text('New trip'),
      ),
      body: ListenableBuilder(
        listenable: app.trips,
        builder: (BuildContext context, Widget? _) {
          final List<Trip> trips = switch (_filter) {
            _TripFilter.upcoming => app.trips.upcomingTrips,
            _TripFilter.past => app.trips.pastTrips,
            _TripFilter.all => app.trips.trips,
          };

          return Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SegmentedButton<_TripFilter>(
                  segments: const <ButtonSegment<_TripFilter>>[
                    ButtonSegment<_TripFilter>(
                      value: _TripFilter.upcoming,
                      label: Text('Upcoming'),
                    ),
                    ButtonSegment<_TripFilter>(value: _TripFilter.past, label: Text('Past')),
                    ButtonSegment<_TripFilter>(value: _TripFilter.all, label: Text('All')),
                  ],
                  selected: <_TripFilter>{_filter},
                  showSelectedIcon: false,
                  onSelectionChanged: (Set<_TripFilter> s) => setState(() => _filter = s.first),
                ),
              ),
              Expanded(
                child: trips.isEmpty
                    ? EmptyState(
                        icon: Icons.luggage_outlined,
                        title: _filter == _TripFilter.past
                            ? 'No past trips yet'
                            : 'No trips planned',
                        message: 'Plan an outing and it will show up here.',
                        action: FilledButton.icon(
                          onPressed: _createTrip,
                          icon: const Icon(Icons.add),
                          label: const Text('Plan a trip'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        itemCount: trips.length,
                        itemBuilder: (BuildContext context, int i) {
                          final Trip trip = trips[i];
                          return Dismissible(
                            key: ValueKey<String>(trip.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) => _deleteTrip(app, trip),
                            child: TripCard(trip: trip),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One trip in the list.
class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => TripDetailScreen(tripId: trip.id)),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 8, color: trip.color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              trip.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            tripCountdown(trip),
                            style: theme.textTheme.labelMedium?.copyWith(color: trip.color),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(trip.destination, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 6),
                      Row(
                        children: <Widget>[
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formatDateRange(trip.startDate, trip.endDate),
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.flag, size: 14, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            '${trip.stops.length} ${trip.stops.length == 1 ? 'stop' : 'stops'}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
