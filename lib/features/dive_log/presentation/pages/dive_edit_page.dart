import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/entities/dive.dart';
import '../providers/dive_providers.dart';

class DiveEditPage extends ConsumerStatefulWidget {
  final String? diveId;

  const DiveEditPage({
    super.key,
    this.diveId,
  });

  bool get isEditing => diveId != null;

  @override
  ConsumerState<DiveEditPage> createState() => _DiveEditPageState();
}

class _DiveEditPageState extends ConsumerState<DiveEditPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;

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

  // Existing dive for editing
  Dive? _existingDive;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();

    if (widget.isEditing) {
      _loadExistingDive();
    }
  }

  Future<void> _loadExistingDive() async {
    setState(() => _isLoading = true);
    try {
      final repository = ref.read(diveRepositoryProvider);
      final dive = await repository.getDiveById(widget.diveId!);
      if (dive != null && mounted) {
        setState(() {
          _existingDive = dive;
          _selectedDate = dive.dateTime;
          _selectedTime = TimeOfDay.fromDateTime(dive.dateTime);
          _durationController.text = dive.duration?.inMinutes.toString() ?? '';
          _maxDepthController.text = dive.maxDepth?.toString() ?? '';
          _avgDepthController.text = dive.avgDepth?.toString() ?? '';
          _waterTempController.text = dive.waterTemp?.toString() ?? '';
          _airTempController.text = dive.airTemp?.toString() ?? '';
          _buddyController.text = dive.buddy ?? '';
          _diveMasterController.text = dive.diveMaster ?? '';
          _notesController.text = dive.notes;
          _selectedDiveType = dive.diveType;
          _selectedVisibility = dive.visibility ?? Visibility.unknown;
          _rating = dive.rating ?? 0;

          // Load tank data if available
          if (dive.tanks.isNotEmpty) {
            final tank = dive.tanks.first;
            _tankVolumeController.text = tank.volume?.toString() ?? '12';
            _startPressureController.text = tank.startPressure?.toString() ?? '200';
            _endPressureController.text = tank.endPressure?.toString() ?? '50';
            _o2PercentController.text = tank.gasMix.o2.toString();
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Edit Dive' : 'Log Dive'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Dive' : 'Log Dive'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
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
                    label: Text(DateFormat('MMM d, y').format(_selectedDate)),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Site picker coming soon'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.location_on),
              label: Text(_existingDive?.site?.name ?? 'Select Dive Site'),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
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

  Future<void> _saveDive() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // Build the DateTime from date and time
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // Parse form values
      final duration = _durationController.text.isNotEmpty
          ? Duration(minutes: int.parse(_durationController.text))
          : null;
      final maxDepth = _maxDepthController.text.isNotEmpty
          ? double.parse(_maxDepthController.text)
          : null;
      final avgDepth = _avgDepthController.text.isNotEmpty
          ? double.parse(_avgDepthController.text)
          : null;
      final waterTemp = _waterTempController.text.isNotEmpty
          ? double.parse(_waterTempController.text)
          : null;
      final airTemp = _airTempController.text.isNotEmpty
          ? double.parse(_airTempController.text)
          : null;

      // Parse tank values
      final tankVolume = _tankVolumeController.text.isNotEmpty
          ? double.parse(_tankVolumeController.text)
          : null;
      final startPressure = _startPressureController.text.isNotEmpty
          ? int.parse(_startPressureController.text)
          : null;
      final endPressure = _endPressureController.text.isNotEmpty
          ? int.parse(_endPressureController.text)
          : null;
      final o2Percent = _o2PercentController.text.isNotEmpty
          ? double.parse(_o2PercentController.text)
          : 21.0;

      // Create tank
      final tanks = <DiveTank>[];
      if (tankVolume != null || startPressure != null || endPressure != null) {
        tanks.add(DiveTank(
          id: '',
          volume: tankVolume,
          startPressure: startPressure,
          endPressure: endPressure,
          gasMix: GasMix(o2: o2Percent),
          order: 0,
        ));
      }

      // Create dive entity
      final dive = Dive(
        id: widget.diveId ?? '',
        diveNumber: _existingDive?.diveNumber,
        dateTime: dateTime,
        duration: duration,
        maxDepth: maxDepth,
        avgDepth: avgDepth,
        waterTemp: waterTemp,
        airTemp: airTemp,
        visibility: _selectedVisibility != Visibility.unknown ? _selectedVisibility : null,
        diveType: _selectedDiveType,
        buddy: _buddyController.text.isNotEmpty ? _buddyController.text : null,
        diveMaster: _diveMasterController.text.isNotEmpty ? _diveMasterController.text : null,
        notes: _notesController.text,
        rating: _rating > 0 ? _rating : null,
        site: _existingDive?.site,
        tanks: tanks,
      );

      // Save using the notifier
      final notifier = ref.read(diveListNotifierProvider.notifier);
      if (widget.isEditing) {
        await notifier.updateDive(dive);
      } else {
        await notifier.addDive(dive);
      }

      if (mounted) {
        context.go('/dives');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving dive: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}
