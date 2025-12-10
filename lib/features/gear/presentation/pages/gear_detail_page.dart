import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/enums.dart';
import '../../domain/entities/gear_item.dart';
import '../providers/gear_providers.dart';

class GearDetailPage extends ConsumerWidget {
  final String gearId;

  const GearDetailPage({
    super.key,
    required this.gearId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gearAsync = ref.watch(gearItemProvider(gearId));

    return gearAsync.when(
      data: (gear) {
        if (gear == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Gear Not Found')),
            body: const Center(child: Text('This gear item no longer exists.')),
          );
        }
        return _buildContent(context, ref, gear);
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

  Widget _buildContent(BuildContext context, WidgetRef ref, GearItem gear) {
    return Scaffold(
      appBar: AppBar(
        title: Text(gear.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/gear/$gearId/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, ref, value, gear),
            itemBuilder: (context) => [
              if (gear.isActive)
                const PopupMenuItem(
                  value: 'service',
                  child: ListTile(
                    leading: Icon(Icons.build),
                    title: Text('Mark as Serviced'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              PopupMenuItem(
                value: gear.isActive ? 'retire' : 'reactivate',
                child: ListTile(
                  leading: Icon(gear.isActive ? Icons.archive : Icons.unarchive),
                  title: Text(gear.isActive ? 'Retire Gear' : 'Reactivate'),
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
            _buildHeaderSection(context, gear),
            const SizedBox(height: 24),
            _buildDetailsSection(context, gear),
            if (gear.serviceIntervalDays != null) ...[
              const SizedBox(height: 24),
              _buildServiceSection(context, gear),
            ],
            if (gear.notes.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildNotesSection(context, gear),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, GearItem gear) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: gear.isServiceDue
                      ? Theme.of(context).colorScheme.errorContainer
                      : Theme.of(context).colorScheme.tertiaryContainer,
                  child: Icon(
                    _getIconForType(gear.type),
                    size: 32,
                    color: gear.isServiceDue
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
                        gear.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        gear.type.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                      if (!gear.isActive)
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
            if (gear.isServiceDue) ...[
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

  Widget _buildDetailsSection(BuildContext context, GearItem gear) {
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
            if (gear.brand != null)
              _buildDetailRow(context, 'Brand', gear.brand!),
            if (gear.model != null)
              _buildDetailRow(context, 'Model', gear.model!),
            if (gear.serialNumber != null)
              _buildDetailRow(context, 'Serial Number', gear.serialNumber!),
            if (gear.purchaseDate != null)
              _buildDetailRow(
                context,
                'Purchase Date',
                DateFormat('MMM d, yyyy').format(gear.purchaseDate!),
              ),
            if (gear.ownershipDuration != null)
              _buildDetailRow(
                context,
                'Owned For',
                _formatDuration(gear.ownershipDuration!),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSection(BuildContext context, GearItem gear) {
    final daysUntil = gear.daysUntilService;
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
              '${gear.serviceIntervalDays} days',
            ),
            if (gear.lastServiceDate != null)
              _buildDetailRow(
                context,
                'Last Service',
                DateFormat('MMM d, yyyy').format(gear.lastServiceDate!),
              ),
            if (gear.nextServiceDue != null)
              _buildDetailRow(
                context,
                'Next Service Due',
                DateFormat('MMM d, yyyy').format(gear.nextServiceDue!),
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

  Widget _buildNotesSection(BuildContext context, GearItem gear) {
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
              gear.notes,
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
    GearItem gear,
  ) async {
    final notifier = ref.read(gearListNotifierProvider.notifier);

    switch (action) {
      case 'service':
        await notifier.markAsServiced(gearId);
        ref.invalidate(gearItemProvider(gearId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marked as serviced')),
          );
        }
        break;

      case 'retire':
        await notifier.retireGear(gearId);
        ref.invalidate(gearItemProvider(gearId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gear retired')),
          );
        }
        break;

      case 'reactivate':
        await notifier.reactivateGear(gearId);
        ref.invalidate(gearItemProvider(gearId));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gear reactivated')),
          );
        }
        break;

      case 'delete':
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Gear'),
            content: const Text(
              'Are you sure you want to delete this gear? This action cannot be undone.',
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
          await notifier.deleteGear(gearId);
          if (context.mounted) {
            context.go('/gear');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gear deleted')),
            );
          }
        }
        break;
    }
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
