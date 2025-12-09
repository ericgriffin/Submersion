import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/enums.dart';
import '../../../../core/database/database.dart';
import '../../../../core/services/database_service.dart';
import '../../domain/entities/dive.dart' as domain;
import '../../../dive_sites/domain/entities/dive_site.dart' as domain;

class DiveRepository {
  final AppDatabase _db = DatabaseService.instance.database;
  final _uuid = const Uuid();

  // ============================================================================
  // CRUD Operations
  // ============================================================================

  /// Get all dives, ordered by date (newest first)
  Future<List<domain.Dive>> getAllDives() async {
    final query = _db.select(_db.dives)
      ..orderBy([(t) => OrderingTerm.desc(t.diveDateTime)]);

    final rows = await query.get();
    return Future.wait(rows.map(_mapRowToDive));
  }

  /// Get a single dive by ID
  Future<domain.Dive?> getDiveById(String id) async {
    final query = _db.select(_db.dives)
      ..where((t) => t.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return _mapRowToDive(row);
  }

  /// Create a new dive
  Future<domain.Dive> createDive(domain.Dive dive) async {
    final id = dive.id.isEmpty ? _uuid.v4() : dive.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.dives).insert(DivesCompanion(
      id: Value(id),
      diveNumber: Value(dive.diveNumber),
      diveDateTime: Value(dive.dateTime.millisecondsSinceEpoch),
      duration: Value(dive.duration?.inSeconds),
      maxDepth: Value(dive.maxDepth),
      avgDepth: Value(dive.avgDepth),
      waterTemp: Value(dive.waterTemp),
      airTemp: Value(dive.airTemp),
      visibility: Value(dive.visibility?.name),
      diveType: Value(dive.diveType.name),
      buddy: Value(dive.buddy),
      diveMaster: Value(dive.diveMaster),
      notes: Value(dive.notes),
      siteId: Value(dive.site?.id),
      rating: Value(dive.rating),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    // Insert tanks
    for (final tank in dive.tanks) {
      await _db.into(_db.diveTanks).insert(DiveTanksCompanion(
        id: Value(_uuid.v4()),
        diveId: Value(id),
        volume: Value(tank.volume),
        startPressure: Value(tank.startPressure),
        endPressure: Value(tank.endPressure),
        o2Percent: Value(tank.gasMix.o2),
        hePercent: Value(tank.gasMix.he),
        tankOrder: Value(tank.order),
      ));
    }

    // Insert profile points
    for (final point in dive.profile) {
      await _db.into(_db.diveProfiles).insert(DiveProfilesCompanion(
        id: Value(_uuid.v4()),
        diveId: Value(id),
        timestamp: Value(point.timestamp),
        depth: Value(point.depth),
        pressure: Value(point.pressure),
        temperature: Value(point.temperature),
        heartRate: Value(point.heartRate),
      ));
    }

    return dive.copyWith(id: id);
  }

  /// Update an existing dive
  Future<void> updateDive(domain.Dive dive) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.dives)..where((t) => t.id.equals(dive.id))).write(
      DivesCompanion(
        diveNumber: Value(dive.diveNumber),
        diveDateTime: Value(dive.dateTime.millisecondsSinceEpoch),
        duration: Value(dive.duration?.inSeconds),
        maxDepth: Value(dive.maxDepth),
        avgDepth: Value(dive.avgDepth),
        waterTemp: Value(dive.waterTemp),
        airTemp: Value(dive.airTemp),
        visibility: Value(dive.visibility?.name),
        diveType: Value(dive.diveType.name),
        buddy: Value(dive.buddy),
        diveMaster: Value(dive.diveMaster),
        notes: Value(dive.notes),
        siteId: Value(dive.site?.id),
        rating: Value(dive.rating),
        updatedAt: Value(now),
      ),
    );

    // Update tanks: delete and re-insert
    await (_db.delete(_db.diveTanks)..where((t) => t.diveId.equals(dive.id))).go();
    for (final tank in dive.tanks) {
      await _db.into(_db.diveTanks).insert(DiveTanksCompanion(
        id: Value(_uuid.v4()),
        diveId: Value(dive.id),
        volume: Value(tank.volume),
        startPressure: Value(tank.startPressure),
        endPressure: Value(tank.endPressure),
        o2Percent: Value(tank.gasMix.o2),
        hePercent: Value(tank.gasMix.he),
        tankOrder: Value(tank.order),
      ));
    }
  }

  /// Delete a dive
  Future<void> deleteDive(String id) async {
    await (_db.delete(_db.dives)..where((t) => t.id.equals(id))).go();
  }

  // ============================================================================
  // Query Operations
  // ============================================================================

  /// Get dives for a specific site
  Future<List<domain.Dive>> getDivesForSite(String siteId) async {
    final query = _db.select(_db.dives)
      ..where((t) => t.siteId.equals(siteId))
      ..orderBy([(t) => OrderingTerm.desc(t.diveDateTime)]);

    final rows = await query.get();
    return Future.wait(rows.map(_mapRowToDive));
  }

  /// Get dives within a date range
  Future<List<domain.Dive>> getDivesInRange(DateTime start, DateTime end) async {
    final query = _db.select(_db.dives)
      ..where((t) => t.diveDateTime.isBiggerOrEqualValue(start.millisecondsSinceEpoch))
      ..where((t) => t.diveDateTime.isSmallerOrEqualValue(end.millisecondsSinceEpoch))
      ..orderBy([(t) => OrderingTerm.desc(t.diveDateTime)]);

    final rows = await query.get();
    return Future.wait(rows.map(_mapRowToDive));
  }

  /// Get the next dive number
  Future<int> getNextDiveNumber() async {
    final result = await _db.customSelect(
      'SELECT MAX(dive_number) as max_num FROM dives',
    ).getSingle();

    final maxNum = result.data['max_num'] as int?;
    return (maxNum ?? 0) + 1;
  }

  /// Search dives by notes or buddy name
  Future<List<domain.Dive>> searchDives(String query) async {
    final searchQuery = _db.select(_db.dives)
      ..where((t) =>
          t.notes.contains(query) |
          t.buddy.contains(query) |
          t.diveMaster.contains(query))
      ..orderBy([(t) => OrderingTerm.desc(t.diveDateTime)]);

    final rows = await searchQuery.get();
    return Future.wait(rows.map(_mapRowToDive));
  }

  // ============================================================================
  // Statistics
  // ============================================================================

  Future<DiveStatistics> getStatistics() async {
    final stats = await _db.customSelect('''
      SELECT
        COUNT(*) as total_dives,
        SUM(duration) as total_time,
        MAX(max_depth) as max_depth,
        AVG(max_depth) as avg_max_depth,
        AVG(water_temp) as avg_temp,
        COUNT(DISTINCT site_id) as total_sites
      FROM dives
    ''').getSingle();

    return DiveStatistics(
      totalDives: stats.data['total_dives'] as int? ?? 0,
      totalTimeSeconds: stats.data['total_time'] as int? ?? 0,
      maxDepth: stats.data['max_depth'] as double? ?? 0,
      avgMaxDepth: stats.data['avg_max_depth'] as double? ?? 0,
      avgTemperature: stats.data['avg_temp'] as double?,
      totalSites: stats.data['total_sites'] as int? ?? 0,
    );
  }

  // ============================================================================
  // Mapping Helpers
  // ============================================================================

  Future<domain.Dive> _mapRowToDive(Dive row) async {
    // Get tanks for this dive
    final tanksQuery = _db.select(_db.diveTanks)
      ..where((t) => t.diveId.equals(row.id))
      ..orderBy([(t) => OrderingTerm.asc(t.tankOrder)]);
    final tankRows = await tanksQuery.get();

    // Get profile for this dive
    final profileQuery = _db.select(_db.diveProfiles)
      ..where((t) => t.diveId.equals(row.id))
      ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]);
    final profileRows = await profileQuery.get();

    // Get site if exists
    domain.DiveSite? site;
    if (row.siteId != null) {
      final siteQuery = _db.select(_db.diveSites)
        ..where((t) => t.id.equals(row.siteId!));
      final siteRow = await siteQuery.getSingleOrNull();
      if (siteRow != null) {
        site = domain.DiveSite(
          id: siteRow.id,
          name: siteRow.name,
          description: siteRow.description,
          location: siteRow.latitude != null && siteRow.longitude != null
              ? domain.GeoPoint(siteRow.latitude!, siteRow.longitude!)
              : null,
          maxDepth: siteRow.maxDepth,
          country: siteRow.country,
          region: siteRow.region,
          rating: siteRow.rating,
          notes: siteRow.notes,
        );
      }
    }

    return domain.Dive(
      id: row.id,
      diveNumber: row.diveNumber,
      dateTime: DateTime.fromMillisecondsSinceEpoch(row.diveDateTime),
      duration: row.duration != null ? Duration(seconds: row.duration!) : null,
      maxDepth: row.maxDepth,
      avgDepth: row.avgDepth,
      waterTemp: row.waterTemp,
      airTemp: row.airTemp,
      visibility: row.visibility != null
          ? Visibility.values.firstWhere(
              (v) => v.name == row.visibility,
              orElse: () => Visibility.unknown,
            )
          : null,
      diveType: DiveType.values.firstWhere(
        (t) => t.name == row.diveType,
        orElse: () => DiveType.recreational,
      ),
      buddy: row.buddy,
      diveMaster: row.diveMaster,
      notes: row.notes,
      site: site,
      rating: row.rating,
      tanks: tankRows.map((t) => domain.DiveTank(
        id: t.id,
        volume: t.volume,
        startPressure: t.startPressure,
        endPressure: t.endPressure,
        gasMix: domain.GasMix(o2: t.o2Percent, he: t.hePercent),
        order: t.tankOrder,
      )).toList(),
      profile: profileRows.map((p) => domain.DiveProfilePoint(
        timestamp: p.timestamp,
        depth: p.depth,
        pressure: p.pressure,
        temperature: p.temperature,
        heartRate: p.heartRate,
      )).toList(),
    );
  }
}

/// Statistics summary for dives
class DiveStatistics {
  final int totalDives;
  final int totalTimeSeconds;
  final double maxDepth;
  final double avgMaxDepth;
  final double? avgTemperature;
  final int totalSites;

  DiveStatistics({
    required this.totalDives,
    required this.totalTimeSeconds,
    required this.maxDepth,
    required this.avgMaxDepth,
    this.avgTemperature,
    required this.totalSites,
  });

  Duration get totalTime => Duration(seconds: totalTimeSeconds);

  String get totalTimeFormatted {
    final hours = totalTime.inHours;
    final minutes = totalTime.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
