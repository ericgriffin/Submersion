import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/enums.dart';

class DiveEditPage extends StatefulWidget {
  final String? diveId;

  const DiveEditPage({
    super.key,
    this.diveId,
  });

  bool get isEditing => diveId != null;

  @override
  State<DiveEditPage> createState() => _DiveEditPageState();
}

class _DiveEditPageState extends State<DiveEditPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final _durationController = TextEditingController();
  final _maxDepthController = TextEditingController();
  final _avgDepthController = TextEditingController();
  final _waterTempController = TextEditingController();
  final _airTempController = TextEditingController();
  final _buddyController = TextEditingController();
  final _diveMasterController = TextEditingController();
  final _notesController = TextEditingController();

  DiveType _selectedDiveType = DiveType.recreational;
  Visibility _selectedVisibility = Visibility.unknown;
  int _rating = 0;

  // Tank data
  final _tankVolumeController = TextEditingController(text: '12');
  final _startPressureController = TextEditingController(text: '200');
  final _endPressureController = TextEditingController(text: '50');
  final _o2PercentController = TextEditingController(text: '21');

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();

    if (widget.isEditing) {
      // TODO: Load existing dive data
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _maxDepthController.dispose();
    _avgDepthController.dispose();
    _waterTempController.dispose();
    _airTempController.dispose();
    _buddyController.dispose();
    _diveMasterController.dispose();
    _notesController.dispose();
    _tankVolumeController.dispose();
    _startPressureController.dispose();
    _endPressureController.dispose();
    _o2PercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Dive' : 'Log Dive'),
        actions: [
          TextButton(
            onPressed: _saveDive,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildDateTimeSection(),
            const SizedBox(height: 16),
            _buildSiteSection(),
            const SizedBox(height: 16),
            _buildDepthDurationSection(),
            const SizedBox(height: 16),
            _buildTankSection(),
            const SizedBox(height: 16),
            _buildConditionsSection(),
            const SizedBox(height: 16),
            _buildBuddySection(),
            const SizedBox(height: 16),
            _buildRatingSection(),
            const SizedBox(height: 16),
            _buildNotesSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date & Time', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dive Site', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Open site picker
              },
              icon: const Icon(Icons.location_on),
              label: const Text('Select Dive Site'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepthDurationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Depth & Duration', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _maxDepthController,
                    decoration: const InputDecoration(
                      labelText: 'Max Depth',
                      suffixText: 'm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _avgDepthController,
                    decoration: const InputDecoration(
                      labelText: 'Avg Depth',
                      suffixText: 'm',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration',
                suffixText: 'min',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTankSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tank', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _tankVolumeController,
                    decoration: const InputDecoration(
                      labelText: 'Volume',
                      suffixText: 'L',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _o2PercentController,
                    decoration: const InputDecoration(
                      labelText: 'O2',
                      suffixText: '%',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startPressureController,
                    decoration: const InputDecoration(
                      labelText: 'Start',
                      suffixText: 'bar',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _endPressureController,
                    decoration: const InputDecoration(
                      labelText: 'End',
                      suffixText: 'bar',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConditionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Conditions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<DiveType>(
              value: _selectedDiveType,
              decoration: const InputDecoration(labelText: 'Dive Type'),
              items: DiveType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDiveType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Visibility>(
              value: _selectedVisibility,
              decoration: const InputDecoration(labelText: 'Visibility'),
              items: Visibility.values.map((vis) {
                return DropdownMenuItem(
                  value: vis,
                  child: Text(vis.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedVisibility = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _waterTempController,
                    decoration: const InputDecoration(
                      labelText: 'Water Temp',
                      suffixText: '°C',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _airTempController,
                    decoration: const InputDecoration(
                      labelText: 'Air Temp',
                      suffixText: '°C',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuddySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Companions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _buddyController,
              decoration: const InputDecoration(
                labelText: 'Buddy',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _diveMasterController,
              decoration: const InputDecoration(
                labelText: 'Dive Master / Guide',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() => _rating = index + 1);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notes', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Add notes about this dive...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _saveDive() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save dive to database
      context.go('/dives');
    }
  }
}
