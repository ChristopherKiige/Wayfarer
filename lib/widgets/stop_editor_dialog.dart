import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/place.dart';
import '../models/trip.dart';
import '../utils/format.dart';

/// Opens the add/edit stop dialog for [trip]. Returns the new or edited
/// stop, or null if the user cancelled.
Future<TripStop?> showStopEditor(
  BuildContext context, {
  required Trip trip,
  TripStop? existing,
  Place? place,
}) {
  return showDialog<TripStop>(
    context: context,
    builder: (_) => StopEditorDialog(trip: trip, existing: existing, place: place),
  );
}

/// A small form in a dialog: stop name, optional linked place, day
/// (date picker limited to the trip), time (time picker) and a note.
class StopEditorDialog extends StatefulWidget {
  const StopEditorDialog({super.key, required this.trip, this.existing, this.place});

  final Trip trip;
  final TripStop? existing;

  /// Pre-fills the stop when adding from a place's detail screen.
  final Place? place;

  @override
  State<StopEditorDialog> createState() => _StopEditorDialogState();
}

class _StopEditorDialogState extends State<StopEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late DateTime _date;
  late TimeOfDay _time;
  String? _placeId;

  @override
  void initState() {
    super.initState();
    final TripStop? e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? widget.place?.name ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _placeId = e?.placeId ?? widget.place?.id;
    _time = e?.time ?? const TimeOfDay(hour: 10, minute: 0);

    // Default to the first trip day that is today or later.
    final DateTime today = dateOnly(DateTime.now());
    _date =
        e?.date ??
        widget.trip.days.firstWhere(
          (DateTime d) => !d.isBefore(today),
          orElse: () => widget.trip.startDate,
        );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.trip.startDate,
      lastDate: widget.trip.endDate,
      helpText: 'Which day of the trip?',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      TripStop(
        id: widget.existing?.id ?? newId(),
        title: _titleController.text.trim(),
        date: dateOnly(_date),
        minutes: _time.hour * 60 + _time.minute,
        placeId: _placeId,
        note: _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool singleDay = widget.trip.dayCount == 1;

    return AlertDialog(
      title: Text(widget.existing == null ? 'Add a stop' : 'Edit stop'),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            DropdownButtonFormField<String?>(
              initialValue: _placeId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Place (optional)',
                prefixIcon: Icon(Icons.place),
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(value: null, child: Text('Custom stop')),
                for (final Place p in samplePlaces)
                  DropdownMenuItem<String?>(
                    value: p.id,
                    child: Text(p.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (String? id) {
                setState(() => _placeId = id);
                // Use the place's name for the stop (the user can still edit it).
                final Place? p = placeById(id);
                if (p != null) _titleController.text = p.name;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Stop name',
                prefixIcon: Icon(Icons.flag),
              ),
              validator: (String? value) {
                final String text = value?.trim() ?? '';
                if (text.isEmpty) return 'Give the stop a name';
                if (text.length > 50) return 'Keep it under 50 characters';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: singleDay ? null : _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(formatShortDate(_date)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule, size: 18),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteController,
              maxLength: 80,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: Text(widget.existing == null ? 'Add' : 'Save')),
      ],
    );
  }
}
