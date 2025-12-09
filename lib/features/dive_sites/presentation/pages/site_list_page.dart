import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SiteListPage extends StatelessWidget {
  const SiteListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dive Sites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              // TODO: Show map view
            },
          ),
        ],
      ),
      body: _buildEmptyState(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Add new site
        },
        icon: const Icon(Icons.add_location),
        label: const Text('Add Site'),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No dive sites yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Add dive sites to track your favorite locations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              // TODO: Add new site
            },
            icon: const Icon(Icons.add_location),
            label: const Text('Add Your First Site'),
          ),
        ],
      ),
    );
  }
}

/// List item widget for displaying a dive site summary
class SiteListTile extends StatelessWidget {
  final String name;
  final String? location;
  final double? maxDepth;
  final int diveCount;
  final double? rating;
  final VoidCallback? onTap;

  const SiteListTile({
    super.key,
    required this.name,
    this.location,
    this.maxDepth,
    this.diveCount = 0,
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
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          child: Icon(
            Icons.location_on,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
        title: Text(name),
        subtitle: location != null ? Text(location!) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (diveCount > 0)
              Text(
                '$diveCount dives',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (rating != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  Text(rating!.toStringAsFixed(1)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
