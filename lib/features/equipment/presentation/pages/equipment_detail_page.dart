import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/entities/equipment_item.dart';
import '../providers/equipment_providers.dart';

class EquipmentDetailPage extends ConsumerWidget {
  final String equipmentId;

  const EquipmentDetailPage({
    super.key,
    required this.equipmentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equipmentAsync = ref.watch(equipmentItemProvider(equipmentId));

    return equipmentAsync.when(
      data: (equipment) {
        if (equipment == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Equipment Not Found')),
            body: const Center(child: Text('This equipment item no longer exists.')),
          );
        }
        return _buildContent(context, ref, equipment);
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

  Widget _buildContent(BuildContext context, WidgetRef ref, EquipmentItem equipment) {
    return Scaffold(
      appBar: AppBar(
        title: Text(equipment.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/equipment/$equipmentId/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value, equipment),
            itemBuilder: (context) => [
              if (equipment.isActive)
                const PopupMenuItem(
                  value: 'service',
                  child: ListTile(
                    leading: Icon(Icons.build),
                    title: Text('Mark as Serviced'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem(
                value: equipment.isActive ? 'retire' : 'reactivate',
                child: ListTile(
                  leading: Icon(equipment.isActive ? Icons.archive : Icons.unarchive),
                  title: Text(equipment.isActive ? 'Retire Equipment' : 'Reactivate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(context, equipment),
            const SizedBox(height: 24),
            _buildDetailsSection(context, equipment),
            if (equipment.serviceIntervalDays != null) ...[
              const SizedBox(height: 24),
              _buildServiceSection(context, equipment),
            ],
            if (equipment.notes.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildNotesSection(context, equipment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, EquipmentItem equipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: equipment.isServiceDue
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,
                  child: Icon(
                    _getIconForType(equipment.type),
                    size: 32,
                    color: equipment.isServiceDue
                        ? Theme.of(context).colorScheme.onErrorContainer
                        : Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        equipment.type.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (!equipment.isActive)
                        Chip(
                          label: const Text('Retired'),
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          labelStyle: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (equipment.isServiceDue) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Service is overdue!',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, EquipmentItem equipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            if (equipment.brand != null)
              _buildDetailRow(context, 'Brand', equipment.brand!),
            if (equipment.model != null)
              _buildDetailRow(context, 'Model', equipment.model!),
            if (equipment.serialNumber != null)
              _buildDetailRow(context, 'Serial Number', equipment.serialNumber!),
            if (equipment.purchaseDate != null)
              _buildDetailRow(
                context,
                'Purchase Date',
                DateFormat('MMM d, yyyy').format(equipment.purchaseDate!),
              ),
            if (equipment.ownershipDuration != null)
              _buildDetailRow(
                context,
                'Owned For',
                _formatDuration(equipment.ownershipDuration!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection(BuildContext context, EquipmentItem equipment) {
    final daysUntil = equipment.daysUntilService;
    final isOverdue = daysUntil != null && daysUntil < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.build,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Service Information',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow(
              context,
              'Service Interval',
              '${equipment.serviceIntervalDays} days',
            ),
            if (equipment.lastServiceDate != null)
              _buildDetailRow(
                context,
                'Last Service',
                DateFormat('MMM d, yyyy').format(equipment.lastServiceDate!),
              ),
            if (equipment.nextServiceDue != null)
              _buildDetailRow(
                context,
                'Next Service Due',
                DateFormat('MMM d, yyyy').format(equipment.nextServiceDue!),
              ),
            if (daysUntil != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? Theme.of(context).colorScheme.errorContainer
                        : daysUntil < 30
                            ? Theme.of(context).colorScheme.tertiaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOverdue ? Icons.warning : Icons.schedule,
                        size: 16,
                        color: isOverdue
                            ? Theme.of(context).colorScheme.onErrorContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isOverdue
                            ? '${daysUntil.abs()} days overdue'
                            : '$daysUntil days until service',
                        style: TextStyle(
                          color: isOverdue
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: isOverdue ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, EquipmentItem equipment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notes,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              equipment.notes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    if (days < 30) return '$days days';
    if (days < 365) return '${(days / 30).floor()} months';
    final years = (days / 365).floor();
    final months = ((days % 365) / 30).floor();
    if (months == 0) return '$years ${years == 1 ? 'year' : 'years'}';
    return '$years ${years == 1 ? 'year' : 'years'}, $months ${months == 1 ? 'month' : 'months'}';
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    EquipmentItem equipment,
  ) async {
    final notifier = ref.read(equipmentListNotifierProvider.notifier);

    switch (action) {
      case 'service':
        await notifier.markAsServiced(equipmentId);
        ref.invalidate(equipmentItemProvider(equipmentId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as serviced')),
          );
        }
        break;

      case 'retire':
        await notifier.retireEquipment(equipmentId);
        ref.invalidate(equipmentItemProvider(equipmentId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment retired')),
          );
        }
        break;

      case 'reactivate':
        await notifier.reactivateEquipment(equipmentId);
        ref.invalidate(equipmentItemProvider(equipmentId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Equipment reactivated')),
          );
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Equipment'),
            content: const Text(
              'Are you sure you want to delete this equipment? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          await notifier.deleteEquipment(equipmentId);
          if (context.mounted) {
            context.go('/equipment');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Equipment deleted')),
            );
          }
        }
        break;
    }
  }

  IconData _getIconForType(EquipmentType type) {
    switch (type) {
      case EquipmentType.regulator:
        return Icons.air;
      case EquipmentType.bcd:
        return Icons.accessibility_new;
      case EquipmentType.wetsuit:
      case EquipmentType.drysuit:
        return Icons.checkroom;
      case EquipmentType.fins:
        return Icons.directions_walk;
      case EquipmentType.mask:
        return Icons.visibility;
      case EquipmentType.computer:
        return Icons.watch;
      case EquipmentType.tank:
        return Icons.propane_tank;
      case EquipmentType.weights:
        return Icons.fitness_center;
      case EquipmentType.light:
        return Icons.flashlight_on;
      case EquipmentType.camera:
        return Icons.camera_alt;
      default:
        return Icons.inventory_2;
    }
  }
}
