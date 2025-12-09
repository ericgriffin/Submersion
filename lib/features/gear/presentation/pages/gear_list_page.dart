import 'package:flutter/material.dart';

import '../../../../core/constants/enums.dart';

class GearListPage extends StatelessWidget {
  const GearListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gear'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Retired'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // TODO: Implement search
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildEmptyState(context),
            _buildEmptyState(context, isRetired: true),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showAddGearDialog(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Gear'),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {bool isRetired = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isRetired ? 'No retired gear' : 'No gear added yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            isRetired
                ? 'Retired gear will appear here'
                : 'Add your diving equipment to track usage and service',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          if (!isRetired) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                _showAddGearDialog(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Gear'),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddGearDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddGearSheet(),
    );
  }
}

class AddGearSheet extends StatefulWidget {
  const AddGearSheet({super.key});

  @override
  State<AddGearSheet> createState() => _AddGearSheetState();
}

class _AddGearSheetState extends State<AddGearSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();

  GearType _selectedType = GearType.regulator;

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Gear',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GearType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type',
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
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
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
                TextFormField(
                  controller: _brandController,
                  decoration: const InputDecoration(
                    labelText: 'Brand',
                    prefixIcon: Icon(Icons.business),
                    hintText: 'e.g., Scubapro',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    prefixIcon: Icon(Icons.info_outline),
                    hintText: 'e.g., MK25 EVO',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _serialController,
                  decoration: const InputDecoration(
                    labelText: 'Serial Number',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saveGear,
                  child: const Text('Add Gear'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveGear() {
    if (_formKey.currentState!.validate()) {
      // TODO: Save gear to database
      Navigator.of(context).pop();
    }
  }
}

/// List item widget for displaying gear
class GearListTile extends StatelessWidget {
  final String name;
  final GearType type;
  final String? brandModel;
  final bool isServiceDue;
  final int? daysUntilService;
  final VoidCallback? onTap;

  const GearListTile({
    super.key,
    required this.name,
    required this.type,
    this.brandModel,
    this.isServiceDue = false,
    this.daysUntilService,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isServiceDue
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.tertiaryContainer,
          child: Icon(
            _getIconForType(type),
            color: isServiceDue
                ? Theme.of(context).colorScheme.onErrorContainer
                : Theme.of(context).colorScheme.onTertiaryContainer,
          ),
        ),
        title: Text(name),
        subtitle: brandModel != null ? Text(brandModel!) : Text(type.displayName),
        trailing: isServiceDue
            ? Chip(
                label: const Text('Service Due'),
                backgroundColor: Theme.of(context).colorScheme.errorContainer,
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 12,
                ),
              )
            : daysUntilService != null
                ? Text(
                    '$daysUntilService days',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : null,
      ),
    );
  }

  IconData _getIconForType(GearType type) {
    switch (type) {
      case GearType.regulator:
        return Icons.air;
      case GearType.bcd:
        return Icons.accessibility_new;
      case GearType.wetsuit:
      case GearType.drysuit:
        return Icons.checkroom;
      case GearType.fins:
        return Icons.directions_walk;
      case GearType.mask:
        return Icons.visibility;
      case GearType.computer:
        return Icons.watch;
      case GearType.tank:
        return Icons.propane_tank;
      case GearType.weights:
        return Icons.fitness_center;
      case GearType.light:
        return Icons.flashlight_on;
      case GearType.camera:
        return Icons.camera_alt;
      default:
        return Icons.inventory_2;
    }
  }
}
