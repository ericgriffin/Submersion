import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/dive.dart';
import '../providers/dive_providers.dart';

class DiveDetailPage extends ConsumerWidget {
  final String diveId;

  const DiveDetailPage({
    super.key,
    required this.diveId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diveAsync = ref.watch(diveProvider(diveId));

    return diveAsync.when(
      data: (dive) {
        if (dive == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Dive Details')),
            body: const Center(child: Text('Dive not found')),
          );
        }
        return _buildContent(context, ref, dive);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Dive Details')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Dive Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading dive', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(error.toString()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, Dive dive) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dive Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.go('/dives/$diveId/edit'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'export':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Export coming soon')),
                  );
                  break;
                case 'delete':
                  _showDeleteConfirmation(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download),
                  title: Text('Export'),
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
            _buildHeaderSection(context, dive),
            const SizedBox(height: 24),
            if (dive.profile.isNotEmpty) ...[
              _buildProfileSection(context, dive),
              const SizedBox(height: 24),
            ],
            _buildDetailsSection(context, dive),
            const SizedBox(height: 24),
            if (dive.tanks.isNotEmpty) ...[
              _buildTanksSection(context, dive),
              const SizedBox(height: 24),
            ],
            _buildNotesSection(context, dive),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, Dive dive) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    '#${dive.diveNumber ?? '-'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dive.site?.name ?? 'Unknown Site',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        DateFormat('EEEE, MMM d, y • h:mm a').format(dive.dateTime),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (dive.rating != null)
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${dive.rating}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  Icons.arrow_downward,
                  dive.maxDepth != null ? '${dive.maxDepth!.toStringAsFixed(1)}m' : '--',
                  'Max Depth',
                ),
                _buildStatItem(
                  context,
                  Icons.timer,
                  dive.duration != null ? '${dive.duration!.inMinutes} min' : '--',
                  'Duration',
                ),
                _buildStatItem(
                  context,
                  Icons.thermostat,
                  dive.waterTemp != null ? '${dive.waterTemp!.toStringAsFixed(0)}°C' : '--',
                  'Temp',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(BuildContext context, Dive dive) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Dive Profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${dive.profile.length} data points',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, Dive dive) {
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
            _buildDetailRow(context, 'Dive Type', dive.diveType.displayName),
            if (dive.visibility != null)
              _buildDetailRow(context, 'Visibility', dive.visibility!.displayName),
            if (dive.avgDepth != null)
              _buildDetailRow(context, 'Avg Depth', '${dive.avgDepth!.toStringAsFixed(1)}m'),
            if (dive.airTemp != null)
              _buildDetailRow(context, 'Air Temp', '${dive.airTemp!.toStringAsFixed(0)}°C'),
            if (dive.buddy != null && dive.buddy!.isNotEmpty)
              _buildDetailRow(context, 'Buddy', dive.buddy!),
            if (dive.diveMaster != null && dive.diveMaster!.isNotEmpty)
              _buildDetailRow(context, 'Dive Master', dive.diveMaster!),
            if (dive.sac != null)
              _buildDetailRow(context, 'SAC Rate', '${dive.sac!.toStringAsFixed(1)} bar/min'),
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

  Widget _buildTanksSection(BuildContext context, Dive dive) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            ...dive.tanks.map((tank) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.propane_tank),
                  title: Text(tank.gasMix.name),
                  subtitle: Text(
                    '${tank.startPressure ?? '--'} bar → ${tank.endPressure ?? '--'} bar'
                    '${tank.pressureUsed != null ? ' (${tank.pressureUsed} bar used)' : ''}',
                  ),
                  trailing: tank.volume != null ? Text('${tank.volume!.toStringAsFixed(0)} L') : null,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(BuildContext context, Dive dive) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Text(
              dive.notes.isNotEmpty ? dive.notes : 'No notes for this dive.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: dive.notes.isEmpty
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : null,
                    fontStyle: dive.notes.isEmpty ? FontStyle.italic : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Dive?'),
        content: const Text(
          'This action cannot be undone. Are you sure you want to delete this dive?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(diveListNotifierProvider.notifier).deleteDive(diveId);
              if (context.mounted) {
                context.go('/dives');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
