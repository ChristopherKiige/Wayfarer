import 'package:flutter/material.dart';

import '../models/place.dart';
import '../screens/place_detail_screen.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

/// The coloured square with the category icon, used on cards and lists.
class PlaceThumb extends StatelessWidget {
  const PlaceThumb({super.key, required this.place, this.size = 76, this.radius = 10});

  final Place place;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: place.category.color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(place.category.icon, size: size * 0.42, color: Colors.white),
    );
  }
}

/// One row on the Discover list. Tapping opens the place; the bookmark
/// saves it.
class PlaceCard extends StatelessWidget {
  const PlaceCard({super.key, required this.place});

  final Place place;

  void _toggleSaved(BuildContext context, AppState app) {
    final bool saved = app.trips.toggleSaved(place.id);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(saved ? 'Saved ${place.name}' : 'Removed ${place.name} from saved'),
        action: SnackBarAction(label: 'Undo', onPressed: () => app.trips.toggleSaved(place.id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final ThemeData theme = Theme.of(context);
    final String distance = formatDistance(distanceFromHome(place), app.settings.distanceUnit);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(place: place)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              PlaceThumb(place: place),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      place.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$distance · ${place.category.label}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 2),
                        Text('${place.rating}', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: app.trips,
                builder: (BuildContext context, Widget? _) {
                  final bool saved = app.trips.isSaved(place.id);
                  return IconButton(
                    tooltip: saved ? 'Remove from saved' : 'Save',
                    icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                    color: theme.colorScheme.primary,
                    onPressed: () => _toggleSaved(context, app),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
