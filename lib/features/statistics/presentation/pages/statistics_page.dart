import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../dive_log/data/repositories/dive_repository_impl.dart';
import '../../../dive_log/presentation/providers/dive_providers.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(diveStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(diveStatisticsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading statistics'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(diveStatisticsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, DiveStatistics stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOverviewCards(context, stats),
          const SizedBox(height: 24),
          _buildDivesByMonthChart(context, stats),
          const SizedBox(height: 24),
          _buildDepthDistribution(context, stats),
          const SizedBox(height: 24),
          _buildTopSites(context, stats),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, DiveStatistics stats) {
    return GridView.count(
      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          context,
          icon: Icons.waves,
          label: 'Total Dives',
          value: '${stats.totalDives}',
          color: Theme.of(context).colorScheme.primary,
        ),
        _buildStatCard(
          context,
          icon: Icons.timer,
          label: 'Total Time',
          value: stats.totalTimeFormatted,
          color: Theme.of(context).colorScheme.secondary,
        ),
        _buildStatCard(
          context,
          icon: Icons.arrow_downward,
          label: 'Max Depth',
          value: stats.maxDepth > 0 ? '${stats.maxDepth.toStringAsFixed(1)}m' : '--',
          color: Theme.of(context).colorScheme.tertiary,
        ),
        _buildStatCard(
          context,
          icon: Icons.location_on,
          label: 'Sites Visited',
          value: '${stats.totalSites}',
          color: Theme.of(context).colorScheme.error,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivesByMonthChart(BuildContext context, DiveStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dives by Month',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              alignment: Alignment.center,
              child: stats.totalDives > 0
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chart visualization coming soon',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chart will appear when you log dives',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepthDistribution(BuildContext context, DiveStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Depth Distribution',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              alignment: Alignment.center,
              child: stats.totalDives > 0
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Avg Max Depth: ${stats.avgMaxDepth.toStringAsFixed(1)}m',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (stats.avgTemperature != null)
                          Text(
                            'Avg Water Temp: ${stats.avgTemperature!.toStringAsFixed(1)}°C',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pie_chart,
                          size: 48,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Chart will appear when you log dives',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopSites(BuildContext context, DiveStatistics stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Dive Sites',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      stats.totalSites > 0
                          ? '${stats.totalSites} sites visited'
                          : 'No dive sites yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
}
