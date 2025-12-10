import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/entities/gear_item.dart';
import '../providers/gear_providers.dart';

class GearListPage extends ConsumerWidget {
  const GearListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                showSearch(
                  context: context,
                  delegate: GearSearchDelegate(ref),
                );
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _ActiveGearTab(),
            _RetiredGearTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            _showAddGearDialog(context, ref);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Gear'),
        ),
      ),
    );
  }

  void _showAddGearDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddGearSheet(ref: ref),
    );
  }
}

class _ActiveGearTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gearAsync = ref.watch(gearListNotifierProvider);

    return gearAsync.when(
      data: (gear) => gear.isEmpty
          ? _buildEmptyState(context, ref)
          : _buildGearList(context, ref, gear),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading gear: $error'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref.read(gearListNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGearList(BuildContext context, WidgetRef ref, List<GearItem> gear) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(gearListNotifierProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: gear.length,
        itemBuilder: (context, index) {
          final item = gear[index];
          return GearListTile(
            name: item.name,
            type: item.type,
            brandModel: item.fullName != item.name ? item.fullName : null,
            isServiceDue: item.isServiceDue,
            daysUntilService: item.daysUntilService,
            onTap: () => context.push('/gear/${item.id}'),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
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
            'No gear added yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add your diving equipment to track usage and service',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => AddGearSheet(ref: ref),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Gear'),
          ),
        ],
      ),
    );
  }
}

class _RetiredGearTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final retiredAsync = ref.watch(retiredGearProvider);

    return retiredAsync.when(
      data: (gear) => gear.isEmpty
          ? _buildEmptyState(context)
          : _buildGearList(context, ref, gear),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
    );
  }

  Widget _buildGearList(BuildContext context, WidgetRef ref, List<GearItem> gear) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: gear.length,
      itemBuilder: (context, index) {
        final item = gear[index];
        return GearListTile(
          name: item.name,
          type: item.type,
          brandModel: item.fullName != item.name ? item.fullName : null,
          isServiceDue: false,
          onTap: () => context.push('/gear/${item.id}'),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
            'No retired gear',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Retired gear will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class AddGearSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const AddGearSheet({super.key, required this.ref});

  @override
  ConsumerState<AddGearSheet> createState() => _AddGearSheetState();
}

class _AddGearSheetState extends ConsumerState<AddGearSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();

  GearType _selectedType = GearType.regulator;
  bool _isSaving = false;

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
                  onPressed: _isSaving ? null : _saveGear,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Gear'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveGear() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final gear = GearItem(
        id: '',
        name: _nameController.text.trim(),
        type: _selectedType,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        model: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        serialNumber: _serialController.text.trim().isEmpty ? null : _serialController.text.trim(),
        isActive: true,
      );

      await widget.ref.read(gearListNotifierProvider.notifier).addGear(gear);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gear added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding gear: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isSaving = false);
      }
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

/// Search delegate for gear
class GearSearchDelegate extends SearchDelegate<GearItem?> {
  final WidgetRef ref;

  GearSearchDelegate(this.ref);

  @override
  String get searchFieldLabel => 'Search gear...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Search by name, brand, model, or serial number',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final searchAsync = ref.watch(gearSearchProvider(query));

    return searchAsync.when(
      data: (gear) {
        if (gear.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No gear found for "$query"',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: gear.length,
          itemBuilder: (context, index) {
            final item = gear[index];
            return GearListTile(
              name: item.name,
              type: item.type,
              brandModel: item.fullName != item.name ? item.fullName : null,
              isServiceDue: item.isServiceDue,
              daysUntilService: item.daysUntilService,
              onTap: () {
                close(context, item);
                context.push('/gear/${item.id}');
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}
