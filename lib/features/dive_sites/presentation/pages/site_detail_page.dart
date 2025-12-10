import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/dive_site.dart';
import '../providers/site_providers.dart';

class SiteDetailPage extends ConsumerWidget {
  final String siteId;

  const SiteDetailPage({
    super.key,
    required this.siteId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final siteAsync = ref.watch(siteProvider(siteId));

    return siteAsync.when(
      data: (site) {
        if (site == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Site Not Found')),
            body: const Center(child: Text('This site no longer exists.')),
          );
        }
        return _buildContent(context, ref, site);
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

  Widget _buildContent(BuildContext context, WidgetRef ref, DiveSite site) {
    return Scaffold(
      appBar: AppBar(
        title: Text(site.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push('/sites/$siteId/edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(context, site),
            const SizedBox(height: 24),
            if (site.hasCoordinates) _buildMapPlaceholder(context, site),
            if (site.hasCoordinates) const SizedBox(height: 24),
            if (site.description.isNotEmpty) ...[
              _buildDescriptionSection(context, site),
              const SizedBox(height: 24),
            ],
            _buildDetailsSection(context, site),
            if (site.notes.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildNotesSection(context, site),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, DiveSite site) {
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
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.location_on,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        site.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (site.locationString.isNotEmpty)
                        Text(
                          site.locationString,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                    ],
                  ),
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
                  site.maxDepth != null ? '${site.maxDepth!.toStringAsFixed(0)}m' : '--',
                  'Max Depth',
                ),
                _buildStatItem(
                  context,
                  Icons.star,
                  site.rating != null ? site.rating!.toStringAsFixed(1) : '--',
                  'Rating',
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

  Widget _buildMapPlaceholder(BuildContext context, DiveSite site) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.map,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Map View',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (site.location != null)
                Text(
                  site.location.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, DiveSite site) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Description',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              site.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, DiveSite site) {
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
            if (site.country != null)
              _buildDetailRow(context, 'Country', site.country!),
            if (site.region != null)
              _buildDetailRow(context, 'Region', site.region!),
            if (site.maxDepth != null)
              _buildDetailRow(context, 'Max Depth', '${site.maxDepth!.toStringAsFixed(1)} m'),
            if (site.rating != null)
              _buildDetailRow(context, 'Rating', '${site.rating!.toStringAsFixed(1)} / 5'),
            if (site.hasCoordinates)
              _buildDetailRow(context, 'Coordinates', site.location.toString()),
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

  Widget _buildNotesSection(BuildContext context, DiveSite site) {
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
              site.notes,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
