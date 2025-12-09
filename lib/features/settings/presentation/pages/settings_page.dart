import 'package:flutter/material.dart';

import '../../../../core/constants/units.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Settings state
  DepthUnit _depthUnit = DepthUnit.meters;
  TemperatureUnit _tempUnit = TemperatureUnit.celsius;
  PressureUnit _pressureUnit = PressureUnit.bar;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'Units'),
          _buildUnitTile(
            context,
            title: 'Depth',
            value: _depthUnit.symbol,
            onTap: () => _showDepthUnitPicker(),
          ),
          _buildUnitTile(
            context,
            title: 'Temperature',
            value: '°${_tempUnit.symbol}',
            onTap: () => _showTempUnitPicker(),
          ),
          _buildUnitTile(
            context,
            title: 'Pressure',
            value: _pressureUnit.symbol,
            onTap: () => _showPressureUnitPicker(),
          ),
          const Divider(),

          _buildSectionHeader(context, 'Appearance'),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              // TODO: Apply theme change
            },
          ),
          const Divider(),

          _buildSectionHeader(context, 'Data'),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import'),
            subtitle: const Text('Import dives from file'),
            onTap: () {
              // TODO: Import functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Export'),
            subtitle: const Text('Export all dives'),
            onTap: () {
              _showExportOptions(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup'),
            subtitle: const Text('Create a backup of your data'),
            onTap: () {
              // TODO: Backup functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore'),
            subtitle: const Text('Restore from backup'),
            onTap: () {
              // TODO: Restore functionality
            },
          ),
          const Divider(),

          _buildSectionHeader(context, 'Dive Computer'),
          ListTile(
            leading: const Icon(Icons.bluetooth),
            title: const Text('Connect Dive Computer'),
            subtitle: const Text('Import dives via Bluetooth'),
            onTap: () {
              // TODO: Dive computer connection
            },
          ),
          const Divider(),

          _buildSectionHeader(context, 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Submersion'),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Open Source Licenses'),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'Submersion',
                applicationVersion: '0.1.0',
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report an Issue'),
            onTap: () {
              // TODO: Open GitHub issues page
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildUnitTile(
    BuildContext context, {
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onTap,
    );
  }

  void _showDepthUnitPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Depth Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DepthUnit.values.map((unit) {
            return RadioListTile<DepthUnit>(
              title: Text(unit == DepthUnit.meters ? 'Meters (m)' : 'Feet (ft)'),
              value: unit,
              groupValue: _depthUnit,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _depthUnit = value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTempUnitPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Temperature Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: TemperatureUnit.values.map((unit) {
            return RadioListTile<TemperatureUnit>(
              title: Text(unit == TemperatureUnit.celsius
                  ? 'Celsius (°C)'
                  : 'Fahrenheit (°F)'),
              value: unit,
              groupValue: _tempUnit,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _tempUnit = value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPressureUnitPicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pressure Unit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: PressureUnit.values.map((unit) {
            return RadioListTile<PressureUnit>(
              title: Text(unit == PressureUnit.bar ? 'Bar' : 'PSI'),
              value: unit,
              groupValue: _pressureUnit,
              onChanged: (value) {
                if (value != null) {
                  setState(() => _pressureUnit = value);
                  Navigator.of(context).pop();
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Export as UDDF'),
              subtitle: const Text('Universal Dive Data Format (XML)'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Export as UDDF
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Export as CSV'),
              subtitle: const Text('Spreadsheet format'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Export as CSV
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Export as PDF'),
              subtitle: const Text('Printable logbook'),
              onTap: () {
                Navigator.of(context).pop();
                // TODO: Export as PDF
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Submersion',
      applicationVersion: '0.1.0',
      applicationIcon: Icon(
        Icons.scuba_diving,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
      children: [
        const Text(
          'An open-source dive logging application.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Track your dives, manage gear, and explore dive sites.',
        ),
      ],
    );
  }
}
