import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/place.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/app_drawer.dart';
import 'place_detail_screen.dart';
import 'settings_screen.dart';

/// Profile: name (editable), trip stats and a grid of saved places.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppState app = AppScope.of(context);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: app.trips,
        builder: (BuildContext context, Widget? _) {
          final List<Place> saved = samplePlaces
              .where((Place p) => app.trips.isSaved(p.id))
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      initials(app.settings.displayName),
                      style: TextStyle(fontSize: 24, color: theme.colorScheme.onPrimary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(app.settings.displayName, style: theme.textTheme.titleLarge),
                        Text('Home: $homeLabel', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit name',
                    icon: const Icon(Icons.edit),
                    onPressed: () => showEditNameDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  _Stat(label: 'Trips', value: app.trips.trips.length),
                  _Stat(label: 'Upcoming', value: app.trips.upcomingTrips.length),
                  _Stat(label: 'Stops', value: app.trips.totalStops),
                  _Stat(label: 'Saved', value: saved.length),
                ],
              ),
              const SizedBox(height: 24),
              Text('Saved places', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (saved.isEmpty)
                Text(
                  'Tap the bookmark on any place in Discover to save it here.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: saved.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (BuildContext context, int i) => _SavedTile(place: saved[i]),
                ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.restart_alt),
                      title: const Text('Reset sample data'),
                      subtitle: const Text('Restore the demo trips and saved places'),
                      onTap: () => _confirmReset(context, app),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, AppState app) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Reset sample data?'),
        content: const Text('Your trips and saved places will be replaced with the sample ones.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    app.trips.resetToSamples();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Sample data restored')));
  }
}

/// Asks for a new display name and saves it. Used by Profile and Settings.
Future<void> showEditNameDialog(BuildContext context) async {
  final AppState app = AppScope.read(context);
  final String? name = await showDialog<String>(
    context: context,
    builder: (_) => _EditNameDialog(initial: app.settings.displayName),
  );
  if (name == null || !context.mounted) return;
  app.settings.displayName = name;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name changed to $name')));
}

/// Dialog with a small validated form. Stateful so the text controller is
/// disposed only after the dialog has fully closed.
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.initial});

  final String initial;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 30,
          decoration: const InputDecoration(
            labelText: 'Display name',
            prefixIcon: Icon(Icons.person),
          ),
          validator: (String? v) => (v?.trim() ?? '').isEmpty ? 'Name can\'t be empty' : null,
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: <Widget>[
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SavedTile extends StatelessWidget {
  const _SavedTile({required this.place});

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(place: place)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: place.category.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(place.category.icon, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                place.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
