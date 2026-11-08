import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../services/weather_service.dart';
import '../state/app_state.dart';
import '../state/settings_controller.dart';
import '../utils/format.dart';
import '../widgets/app_drawer.dart';
import '../widgets/empty_state.dart';
import '../widgets/place_card.dart';
import 'trip_detail_screen.dart';
import 'trip_form_screen.dart';

enum _SortBy { distance, rating, name }

/// Home page: live weather, search, category filter and the list of nearby
/// places. Also shows the next upcoming trip as a shortcut.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  PlaceCategory? _category; // null = All
  _SortBy _sortBy = _SortBy.distance;

  Weather? _weather;
  bool _weatherFailed = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final WeatherService service = AppScope.read(context).weather;
    try {
      final Weather w = await service.current(homeLatitude, homeLongitude);
      if (!mounted) return;
      setState(() {
        _weather = w;
        _weatherFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _weatherFailed = true);
    }
  }

  List<Place> _visiblePlaces() {
    final String query = _searchController.text.trim().toLowerCase();
    final List<Place> list = samplePlaces.where((Place p) {
      final bool categoryOk = _category == null || p.category == _category;
      final bool queryOk =
          query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.address.toLowerCase().contains(query);
      return categoryOk && queryOk;
    }).toList();

    switch (_sortBy) {
      case _SortBy.distance:
        list.sort((Place a, Place b) => distanceFromHome(a).compareTo(distanceFromHome(b)));
      case _SortBy.rating:
        list.sort((Place a, Place b) => b.rating.compareTo(a.rating));
      case _SortBy.name:
        list.sort((Place a, Place b) => a.name.compareTo(b.name));
    }
    return list;
  }

  Future<void> _createTrip() async {
    final Trip? trip = await Navigator.push<Trip>(
      context,
      MaterialPageRoute<Trip>(builder: (_) => const TripFormScreen()),
    );
    if (trip == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created "${trip.name}"'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => TripDetailScreen(tripId: trip.id)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final List<Place> places = _visiblePlaces();
    final bool filtering = _searchController.text.isNotEmpty || _category != null;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Wayfarer'),
        actions: <Widget>[
          PopupMenuButton<_SortBy>(
            tooltip: 'Sort places',
            icon: const Icon(Icons.sort),
            initialValue: _sortBy,
            onSelected: (_SortBy s) => setState(() => _sortBy = s),
            itemBuilder: (_) => const <PopupMenuEntry<_SortBy>>[
              PopupMenuItem<_SortBy>(value: _SortBy.distance, child: Text('Sort by distance')),
              PopupMenuItem<_SortBy>(value: _SortBy.rating, child: Text('Sort by rating')),
              PopupMenuItem<_SortBy>(value: _SortBy.name, child: Text('Sort by name')),
            ],
          ),
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.account_circle_outlined, size: 28),
            onPressed: () => app.tab.value = AppState.profileTab,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'discover-fab',
        onPressed: _createTrip,
        icon: const Icon(Icons.add),
        label: const Text('New trip'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadWeather,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 96),
          children: <Widget>[
            _buildLocationRow(app.settings.tempUnit),
            _buildSearchBar(),
            _buildCategoryChips(),
            const SizedBox(height: 4),
            if (!filtering)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _NextTripBanner(store: app),
              ),
            if (places.isEmpty)
              const EmptyState(
                icon: Icons.search_off,
                title: 'No outings match',
                message: 'Try a different search or category.',
              ),
            for (final Place place in places)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: PlaceCard(place: place),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(TempUnit unit) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    Widget weather;
    if (_weather != null) {
      final double temp = unit == TempUnit.celsius ? _weather!.celsius : _weather!.fahrenheit;
      weather = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_weather!.icon, size: 16, color: Colors.orange),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${temp.round()}°${unit == TempUnit.celsius ? 'C' : 'F'} · ${_weather!.description}',
            ),
          ),
        ],
      );
    } else if (_weatherFailed) {
      weather = TextButton.icon(
        onPressed: _loadWeather,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('Weather unavailable'),
      );
    } else {
      weather = const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 4,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.place, size: 16, color: scheme.primary),
              const SizedBox(width: 4),
              const Flexible(
                child: Text('Near $homeLabel', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          weather,
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search outings...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(_searchController.clear),
                ),
          filled: true,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final List<PlaceCategory?> options = <PlaceCategory?>[null, ...PlaceCategory.values];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          final PlaceCategory? c = options[i];
          return ChoiceChip(
            label: Text(c?.label ?? 'All'),
            avatar: c == null ? null : Icon(c.icon, size: 16),
            selected: _category == c,
            showCheckmark: false,
            onSelected: (_) => setState(() => _category = c),
          );
        },
      ),
    );
  }
}

/// "Next trip" card at the top of Discover; leads into the trip workflow.
class _NextTripBanner extends StatelessWidget {
  const _NextTripBanner({required this.store});

  final AppState store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store.trips,
      builder: (BuildContext context, Widget? _) {
        final Trip? trip = store.trips.nextTrip;
        if (trip == null) return const SizedBox.shrink();
        final ThemeData theme = Theme.of(context);
        return Card(
          color: trip.color,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => TripDetailScreen(tripId: trip.id)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.luggage, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'NEXT TRIP · ${tripCountdown(trip).toUpperCase()}',
                          style: theme.textTheme.labelSmall?.copyWith(color: Colors.white70),
                        ),
                        Text(
                          trip.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${formatDateRange(trip.startDate, trip.endDate)} · ${trip.stops.length} stops',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
