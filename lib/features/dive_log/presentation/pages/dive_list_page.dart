import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/dive.dart';
import '../providers/dive_providers.dart';

class DiveListPage extends ConsumerWidget {
  const DiveListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final divesAsync = ref.watch(diveListNotifierProvider);

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
      body: divesAsync.when(
        data: (dives) => dives.isEmpty
            ? _buildEmptyState(context)
            : _buildDiveList(context, ref, dives),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading dives',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      ref.read(diveListNotifierProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/dives/new'),
        icon: const Icon(Icons.add),
        label: const Text('Log Dive'),
      ),
    );
  }

  Widget _buildDiveList(BuildContext context, WidgetRef ref, List<Dive> dives) {
    return RefreshIndicator(
      onRefresh: () => ref.read(diveListNotifierProvider.notifier).refresh(),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: dives.length,
        itemBuilder: (context, index) {
          final dive = dives[index];
          return DiveListTile(
            diveNumber: dive.diveNumber ?? index + 1,
            dateTime: dive.dateTime,
            siteName: dive.site?.name,
            maxDepth: dive.maxDepth,
            duration: dive.duration,
            rating: dive.rating,
            onTap: () => context.go('/dives/${dive.id}'),
          );
        },
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
  final int? rating;
  final VoidCallback? onTap;

  const DiveListTile({
    super.key,
    required this.diveNumber,
    required this.dateTime,
    this.siteName,
    this.maxDepth,
    this.duration,
    this.rating,
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
        subtitle: Row(
          children: [
            Text(_formatDate(dateTime)),
            if (rating != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.star,
                size: 14,
                color: Colors.amber.shade600,
              ),
              Text(
                ' $rating',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
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
    return DateFormat('MMM d, y').format(date);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    return '$minutes min';
  }
}
