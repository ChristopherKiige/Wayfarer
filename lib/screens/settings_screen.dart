import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../state/settings_controller.dart';
import 'profile_screen.dart';

/// UI settings. Every change applies to the whole app immediately and is
/// saved on the device.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsController s = AppScope.of(context).settings;
    final ThemeData theme = Theme.of(context);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: <Widget>[
          section('Appearance'),
          const ListTile(leading: Icon(Icons.brightness_6), title: Text('Theme')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const <ButtonSegment<ThemeMode>>[
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: Icon(Icons.phone_android),
                  label: Text('System'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Light'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Dark'),
                ),
              ],
              selected: <ThemeMode>{s.themeMode},
              onSelectionChanged: (Set<ThemeMode> v) => s.themeMode = v.first,
            ),
          ),
          const ListTile(leading: Icon(Icons.palette), title: Text('Accent colour')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final AccentColor c in AccentColor.values)
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: c.color),
                    label: Text(c.label),
                    selected: s.accent == c,
                    showCheckmark: false,
                    onSelected: (_) => s.accent = c,
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.format_size),
            title: const Text('Text size'),
            trailing: Text('${(s.textScale * 100).round()}%'),
          ),
          Slider(
            value: s.textScale,
            min: 0.85,
            max: 1.3,
            divisions: 9,
            label: '${(s.textScale * 100).round()}%',
            onChanged: (double v) => s.textScale = v,
          ),

          section('Units'),
          const ListTile(leading: Icon(Icons.straighten), title: Text('Distance')),
          RadioGroup<DistanceUnit>(
            groupValue: s.distanceUnit,
            onChanged: (DistanceUnit? v) {
              if (v != null) s.distanceUnit = v;
            },
            child: const Column(
              children: <Widget>[
                RadioListTile<DistanceUnit>(value: DistanceUnit.km, title: Text('Kilometres')),
                RadioListTile<DistanceUnit>(value: DistanceUnit.mi, title: Text('Miles')),
              ],
            ),
          ),
          const ListTile(leading: Icon(Icons.thermostat), title: Text('Temperature')),
          RadioGroup<TempUnit>(
            groupValue: s.tempUnit,
            onChanged: (TempUnit? v) {
              if (v != null) s.tempUnit = v;
            },
            child: const Column(
              children: <Widget>[
                RadioListTile<TempUnit>(value: TempUnit.celsius, title: Text('Celsius (°C)')),
                RadioListTile<TempUnit>(value: TempUnit.fahrenheit, title: Text('Fahrenheit (°F)')),
              ],
            ),
          ),

          section('Account'),
          ListTile(
            leading: const Icon(Icons.badge),
            title: const Text('Display name'),
            subtitle: Text(s.displayName),
            trailing: const Icon(Icons.edit),
            onTap: () => showEditNameDialog(context),
          ),
          const Divider(height: 32),
          Center(
            child: TextButton.icon(
              onPressed: () {
                s.reset();
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Settings reset to defaults')));
              },
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset settings'),
            ),
          ),
        ],
      ),
    );
  }
}
