import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/entities/dive_site.dart';

class SiteRepository {
  final AppDatabase _db = DatabaseService.instance.database;
  final _uuid = const Uuid();

  /// Get all sites ordered by name
  Future<List<DiveSite>> getAllSites() async {
    final query = _db.select(_db.diveSites)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);

    final rows = await query.get();
    return rows.map(_mapRowToSite).toList();
  }

  /// Get a single site by ID
  Future<DiveSite?> getSiteById(String id) async {
    final query = _db.select(_db.diveSites)
      ..where((t) => t.id.equals(id));

    final row = await query.getSingleOrNull();
    return row != null ? _mapRowToSite(row) : null;
  }

  /// Create a new site
  Future<DiveSite> createSite(DiveSite site) async {
    final id = site.id.isEmpty ? _uuid.v4() : site.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.diveSites).insert(DiveSitesCompanion(
      id: Value(id),
      name: Value(site.name),
      description: Value(site.description),
      latitude: Value(site.location?.latitude),
      longitude: Value(site.location?.longitude),
      maxDepth: Value(site.maxDepth),
      country: Value(site.country),
      region: Value(site.region),
      rating: Value(site.rating),
      notes: Value(site.notes),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return site.copyWith(id: id);
  }

  /// Update an existing site
  Future<void> updateSite(DiveSite site) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.diveSites)..where((t) => t.id.equals(site.id))).write(
      DiveSitesCompanion(
        name: Value(site.name),
        description: Value(site.description),
        latitude: Value(site.location?.latitude),
        longitude: Value(site.location?.longitude),
        maxDepth: Value(site.maxDepth),
        country: Value(site.country),
        region: Value(site.region),
        rating: Value(site.rating),
        notes: Value(site.notes),
        updatedAt: Value(now),
      ),
    );
  }

  /// Delete a site
  Future<void> deleteSite(String id) async {
    await (_db.delete(_db.diveSites)..where((t) => t.id.equals(id))).go();
  }

  /// Search sites by name or location
  Future<List<DiveSite>> searchSites(String query) async {
    final searchQuery = _db.select(_db.diveSites)
      ..where((t) =>
          t.name.contains(query) |
          t.country.contains(query) |
          t.region.contains(query))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);

    final rows = await searchQuery.get();
    return rows.map(_mapRowToSite).toList();
  }

  /// Get dive count per site
  Future<Map<String, int>> getDiveCountsBySite() async {
    final result = await _db.customSelect('''
      SELECT site_id, COUNT(*) as dive_count
      FROM dives
      WHERE site_id IS NOT NULL
      GROUP BY site_id
    ''').get();

    return {
      for (final row in result)
        row.data['site_id'] as String: row.data['dive_count'] as int,
    };
  }

  /// Get sites with dive counts
  Future<List<SiteWithDiveCount>> getSitesWithDiveCounts() async {
    final sites = await getAllSites();
    final counts = await getDiveCountsBySite();

    return sites.map((site) => SiteWithDiveCount(
      site: site,
      diveCount: counts[site.id] ?? 0,
    )).toList()
      ..sort((a, b) => b.diveCount.compareTo(a.diveCount));
  }

  DiveSite _mapRowToSite(DiveSiteData row) {
    return DiveSite(
      id: row.id,
      name: row.name,
      description: row.description,
      location: row.latitude != null && row.longitude != null
          ? GeoPoint(row.latitude!, row.longitude!)
          : null,
      maxDepth: row.maxDepth,
      country: row.country,
      region: row.region,
      rating: row.rating,
      notes: row.notes,
    );
  }
}

class SiteWithDiveCount {
  final DiveSite site;
  final int diveCount;

  SiteWithDiveCount({required this.site, required this.diveCount});
}
