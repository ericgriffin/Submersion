import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/entities/gear_item.dart';
import '../providers/gear_providers.dart';

class GearEditPage extends ConsumerStatefulWidget {
  final String? gearId;

  const GearEditPage({super.key, this.gearId});

  bool get isEditing => gearId != null;

  @override
  ConsumerState<GearEditPage> createState() => _GearEditPageState();
}

class _GearEditPageState extends ConsumerState<GearEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();
  final _serviceIntervalController = TextEditingController();
  final _notesController = TextEditingController();

  GearType _selectedType = GearType.regulator;
  DateTime? _purchaseDate;
  DateTime? _lastServiceDate;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _serviceIntervalController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeFromGear(GearItem gear) {
    if (_isInitialized) return;
    _isInitialized = true;

    _nameController.text = gear.name;
    _brandController.text = gear.brand ?? '';
    _modelController.text = gear.model ?? '';
    _serialController.text = gear.serialNumber ?? '';
    _serviceIntervalController.text = gear.serviceIntervalDays?.toString() ?? '';
    _notesController.text = gear.notes;
    _selectedType = gear.type;
    _purchaseDate = gear.purchaseDate;
    _lastServiceDate = gear.lastServiceDate;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final gearAsync = ref.watch(gearItemProvider(widget.gearId!));
      return gearAsync.when(
        data: (gear) {
          if (gear == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Gear Not Found')),
              body: const Center(child: Text('This gear item no longer exists.')),
            );
          }
          _initializeFromGear(gear);
          return _buildForm(context, gear);
        },
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Loading...')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Error: $error')),
        ),
      );
    }

    return _buildForm(context, null);
  }

  Widget _buildForm(BuildContext context, GearItem? existingGear) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Gear' : 'New Gear'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type
            DropdownButtonFormField<GearType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type *',
                prefixIcon: Icon(Icons.category),
              ),
              items: GearType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                prefixIcon: Icon(Icons.label),
                hintText: 'e.g., My Primary Regulator',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Brand & Model
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      prefixIcon: Icon(Icons.info_outline),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Serial Number
            TextFormField(
              controller: _serialController,
              decoration: const InputDecoration(
                labelText: 'Serial Number',
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
            const SizedBox(height: 24),

            // Purchase Date
            _buildDateSection(context),
            const SizedBox(height: 24),

            // Service Settings
            _buildServiceSection(context),
            const SizedBox(height: 24),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
                hintText: 'Additional notes about this gear...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save Button
            FilledButton(
              onPressed: _isLoading ? null : () => _saveGear(existingGear),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? 'Save Changes' : 'Add Gear'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Purchase Date', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectPurchaseDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _purchaseDate != null
                    ? '${_purchaseDate!.month}/${_purchaseDate!.day}/${_purchaseDate!.year}'
                    : 'Select Date',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_purchaseDate != null)
              TextButton(
                onPressed: () => setState(() => _purchaseDate = null),
                child: const Text('Clear Date'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text('Service Settings', style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _serviceIntervalController,
              decoration: const InputDecoration(
                labelText: 'Service Interval (days)',
                prefixIcon: Icon(Icons.schedule),
                hintText: 'e.g., 365 for yearly',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Text(
              'Last Service Date',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _selectLastServiceDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _lastServiceDate != null
                    ? '${_lastServiceDate!.month}/${_lastServiceDate!.day}/${_lastServiceDate!.year}'
                    : 'Select Date',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_lastServiceDate != null)
              TextButton(
                onPressed: () => setState(() => _lastServiceDate = null),
                child: const Text('Clear Date'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPurchaseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _purchaseDate = date);
    }
  }

  Future<void> _selectLastServiceDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _lastServiceDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _lastServiceDate = date);
    }
  }

  Future<void> _saveGear(GearItem? existingGear) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final gear = GearItem(
        id: widget.gearId ?? '',
        name: _nameController.text.trim(),
        type: _selectedType,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
        purchaseDate: _purchaseDate,
        lastServiceDate: _lastServiceDate,
        serviceIntervalDays: _serviceIntervalController.text.isNotEmpty
            ? int.tryParse(_serviceIntervalController.text)
            : null,
        notes: _notesController.text.trim(),
        isActive: existingGear?.isActive ?? true,
      );

      final notifier = ref.read(gearListNotifierProvider.notifier);

      if (widget.isEditing) {
        await notifier.updateGear(gear);
        ref.invalidate(gearItemProvider(widget.gearId!));
      } else {
        await notifier.addGear(gear);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? 'Gear updated' : 'Gear added'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving gear: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
