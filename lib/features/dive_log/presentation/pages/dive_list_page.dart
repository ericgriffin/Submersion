import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DiveListPage extends StatelessWidget {
  const DiveListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dive Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filter
            },
          ),
        ],
      ),
      body: _buildEmptyState(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/dives/new'),
        icon: const Icon(Icons.add),
        label: const Text('Log Dive'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.waves,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No dives logged yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to log your first dive',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/dives/new'),
            icon: const Icon(Icons.add),
            label: const Text('Log Your First Dive'),
          ),
        ],
      ),
    );
  }
}

/// List item widget for displaying a dive summary
class DiveListTile extends StatelessWidget {
  final int diveNumber;
  final DateTime dateTime;
  final String? siteName;
  final double? maxDepth;
  final Duration? duration;
  final VoidCallback? onTap;

  const DiveListTile({
    super.key,
    required this.diveNumber,
    required this.dateTime,
    this.siteName,
    this.maxDepth,
    this.duration,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '#$diveNumber',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(siteName ?? 'Unknown Site'),
        subtitle: Text(_formatDate(dateTime)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (maxDepth != null)
              Text(
                '${maxDepth!.toStringAsFixed(1)}m',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            if (duration != null)
              Text(
                _formatDuration(duration!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    return '$minutes min';
  }
}
