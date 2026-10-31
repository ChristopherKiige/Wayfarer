import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

/// Create a new trip, or edit one when [existing] is given.
///
/// A validated Form: name and destination are text fields, the dates come
/// from a date-range picker (wrapped in a FormField so the Form can
/// validate it), plus a cover colour, a reminder switch and notes.
/// Pops the saved [Trip].
class TripFormScreen extends StatefulWidget {
  const TripFormScreen({super.key, this.existing});

  final Trip? existing;

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _destinationController;
  late final TextEditingController _notesController;
  DateTimeRange? _dates;
  late int _colorIndex;
  late bool _reminder;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final Trip? t = widget.existing;
    _nameController = TextEditingController(text: t?.name ?? '');
    _destinationController = TextEditingController(text: t?.destination ?? '');
    _notesController = TextEditingController(text: t?.notes ?? '');
    _dates = t == null ? null : DateTimeRange(start: t.startDate, end: t.endDate);
    _colorIndex = t?.colorIndex ?? 0;
    _reminder = t?.reminder ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<DateTimeRange?> _pickDates() {
    final DateTime today = dateOnly(DateTime.now());
    return showDateRangePicker(
      context: context,
      // Allow past dates only when editing an old trip.
      firstDate: _isEditing ? DateTime(today.year - 2) : today,
      lastDate: DateTime(today.year + 2, 12, 31),
      initialDateRange: _dates,
      helpText: 'Trip dates',
      saveText: 'Done',
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fix the highlighted fields')));
      return;
    }
    _formKey.currentState!.save();

    final AppState app = AppScope.read(context);
    final Trip trip = Trip(
      id: widget.existing?.id ?? newId(),
      name: _nameController.text.trim(),
      destination: _destinationController.text.trim(),
      startDate: dateOnly(_dates!.start),
      endDate: dateOnly(_dates!.end),
      notes: _notesController.text.trim(),
      colorIndex: _colorIndex,
      reminder: _reminder,
      stops: widget.existing?.stops ?? const <TripStop>[],
    );

    if (_isEditing) {
      app.trips.updateTrip(trip);
    } else {
      app.trips.addTrip(trip);
    }
    Navigator.pop(context, trip);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit trip' : 'New trip'),
        actions: <Widget>[
          TextButton(
            onPressed: _save,
            style: TextButton.styleFrom(foregroundColor: theme.appBarTheme.foregroundColor),
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 40,
              decoration: const InputDecoration(
                labelText: 'Trip name',
                hintText: 'e.g. Waterfront weekend',
                prefixIcon: Icon(Icons.luggage),
              ),
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) return 'Please name your trip';
                if (text.length < 3) return 'Use at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _destinationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Destination',
                hintText: 'City or area',
                prefixIcon: Icon(Icons.place),
              ),
              validator: (String? value) =>
                  (value?.trim() ?? '').isEmpty ? 'Where are you going?' : null,
            ),
            const SizedBox(height: 16),

            // Dates: a FormField so validate() also checks them.
            FormField<DateTimeRange>(
              initialValue: _dates,
              validator: (DateTimeRange? value) => value == null ? 'Pick your trip dates' : null,
              builder: (FormFieldState<DateTimeRange> field) {
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    final DateTimeRange? picked = await _pickDates();
                    if (picked == null) return;
                    setState(() => _dates = picked);
                    field.didChange(picked);
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Dates',
                      prefixIcon: const Icon(Icons.date_range),
                      suffixIcon: const Icon(Icons.edit_calendar),
                      errorText: field.errorText,
                    ),
                    isEmpty: _dates == null,
                    child: Text(
                      _dates == null
                          ? ''
                          : '${formatDateRange(_dates!.start, _dates!.end)}  (${daysBetween(_dates!.start, _dates!.end) + 1} days)',
                    ),
                  ),
                );
              },
            ),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  'Stops outside the new dates will be removed.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            Text('Cover colour', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: <Widget>[
                for (int i = 0; i < tripColors.length; i++)
                  Semantics(
                    label: 'Colour ${i + 1}',
                    selected: i == _colorIndex,
                    button: true,
                    child: GestureDetector(
                      onTap: () => setState(() => _colorIndex = i),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: tripColors[i],
                        child: i == _colorIndex
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Remind me the day before'),
              value: _reminder,
              onChanged: (bool v) => setState(() => _reminder = v),
            ),
            const SizedBox(height: 8),

            TextFormField(
              controller: _notesController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Save changes' : 'Create trip'),
            ),
          ],
        ),
      ),
    );
  }
}
