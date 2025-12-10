import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database.dart';
import '../../../../core/services/database_service.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/entities/gear_item.dart';

class GearRepository {
  final AppDatabase _db = DatabaseService.instance.database;
  final _uuid = const Uuid();

  /// Get all active gear
  Future<List<GearItem>> getActiveGear() async {
    final query = _db.select(_db.gear)
      ..where((t) => t.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm.asc(t.type), (t) => OrderingTerm.asc(t.name)]);

    final rows = await query.get();
    return rows.map(_mapRowToGear).toList();
  }

  /// Get all retired gear
  Future<List<GearItem>> getRetiredGear() async {
    final query = _db.select(_db.gear)
      ..where((t) => t.isActive.equals(false))
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);

    final rows = await query.get();
    return rows.map(_mapRowToGear).toList();
  }

  /// Get all gear
  Future<List<GearItem>> getAllGear() async {
    final query = _db.select(_db.gear)
      ..orderBy([(t) => OrderingTerm.asc(t.type), (t) => OrderingTerm.asc(t.name)]);

    final rows = await query.get();
    return rows.map(_mapRowToGear).toList();
  }

  /// Get gear by ID
  Future<GearItem?> getGearById(String id) async {
    final query = _db.select(_db.gear)
      ..where((t) => t.id.equals(id));

    final row = await query.getSingleOrNull();
    return row != null ? _mapRowToGear(row) : null;
  }

  /// Create new gear
  Future<GearItem> createGear(GearItem gear) async {
    final id = gear.id.isEmpty ? _uuid.v4() : gear.id;
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.into(_db.gear).insert(GearCompanion(
      id: Value(id),
      name: Value(gear.name),
      type: Value(gear.type.name),
      brand: Value(gear.brand),
      model: Value(gear.model),
      serialNumber: Value(gear.serialNumber),
      purchaseDate: Value(gear.purchaseDate?.millisecondsSinceEpoch),
      lastServiceDate: Value(gear.lastServiceDate?.millisecondsSinceEpoch),
      serviceIntervalDays: Value(gear.serviceIntervalDays),
      notes: Value(gear.notes),
      isActive: Value(gear.isActive),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    return gear.copyWith(id: id);
  }

  /// Update gear
  Future<void> updateGear(GearItem gear) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await (_db.update(_db.gear)..where((t) => t.id.equals(gear.id))).write(
      GearCompanion(
        name: Value(gear.name),
        type: Value(gear.type.name),
        brand: Value(gear.brand),
        model: Value(gear.model),
        serialNumber: Value(gear.serialNumber),
        purchaseDate: Value(gear.purchaseDate?.millisecondsSinceEpoch),
        lastServiceDate: Value(gear.lastServiceDate?.millisecondsSinceEpoch),
        serviceIntervalDays: Value(gear.serviceIntervalDays),
        notes: Value(gear.notes),
        isActive: Value(gear.isActive),
        updatedAt: Value(now),
      ),
    );
  }

  /// Delete gear
  Future<void> deleteGear(String id) async {
    await (_db.delete(_db.gear)..where((t) => t.id.equals(id))).go();
  }

  /// Mark gear as serviced
  Future<void> markAsServiced(String id) async {
    final now = DateTime.now();
    await (_db.update(_db.gear)..where((t) => t.id.equals(id))).write(
      GearCompanion(
        lastServiceDate: Value(now.millisecondsSinceEpoch),
        updatedAt: Value(now.millisecondsSinceEpoch),
      ),
    );
  }

  /// Retire gear
  Future<void> retireGear(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.gear)..where((t) => t.id.equals(id))).write(
      GearCompanion(
        isActive: const Value(false),
        updatedAt: Value(now),
      ),
    );
  }

  /// Reactivate gear
  Future<void> reactivateGear(String id) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await (_db.update(_db.gear)..where((t) => t.id.equals(id))).write(
      GearCompanion(
        isActive: const Value(true),
        updatedAt: Value(now),
      ),
    );
  }

  /// Get gear with service due
  Future<List<GearItem>> getGearWithServiceDue() async {
    final allGear = await getActiveGear();
    return allGear.where((g) => g.isServiceDue).toList();
  }

  /// Search gear by name, brand, model, or serial number
  Future<List<GearItem>> searchGear(String query) async {
    final searchTerm = '%${query.toLowerCase()}%';

    final results = await _db.customSelect('''
      SELECT * FROM gear
      WHERE LOWER(name) LIKE ?
         OR LOWER(brand) LIKE ?
         OR LOWER(model) LIKE ?
         OR LOWER(serial_number) LIKE ?
      ORDER BY is_active DESC, type ASC, name ASC
    ''', variables: [
      Variable.withString(searchTerm),
      Variable.withString(searchTerm),
      Variable.withString(searchTerm),
      Variable.withString(searchTerm),
    ]).get();

    return results.map((row) {
      return GearItem(
        id: row.data['id'] as String,
        name: row.data['name'] as String,
        type: GearType.values.firstWhere(
          (t) => t.name == row.data['type'],
          orElse: () => GearType.other,
        ),
        brand: row.data['brand'] as String?,
        model: row.data['model'] as String?,
        serialNumber: row.data['serial_number'] as String?,
        purchaseDate: row.data['purchase_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row.data['purchase_date'] as int)
            : null,
        lastServiceDate: row.data['last_service_date'] != null
            ? DateTime.fromMillisecondsSinceEpoch(row.data['last_service_date'] as int)
            : null,
        serviceIntervalDays: row.data['service_interval_days'] as int?,
        notes: (row.data['notes'] as String?) ?? '',
        isActive: row.data['is_active'] == 1,
      );
    }).toList();
  }

  /// Get dive count for gear item
  Future<int> getDiveCountForGear(String gearId) async {
    final result = await _db.customSelect('''
      SELECT COUNT(*) as count
      FROM dive_gear
      WHERE gear_id = ?
    ''', variables: [Variable.withString(gearId)]).getSingle();

    return result.data['count'] as int? ?? 0;
  }

  GearItem _mapRowToGear(GearData row) {
    return GearItem(
      id: row.id,
      name: row.name,
      type: GearType.values.firstWhere(
        (t) => t.name == row.type,
        orElse: () => GearType.other,
      ),
      brand: row.brand,
      model: row.model,
      serialNumber: row.serialNumber,
      purchaseDate: row.purchaseDate != null
          ? DateTime.fromMillisecondsSinceEpoch(row.purchaseDate!)
          : null,
      lastServiceDate: row.lastServiceDate != null
          ? DateTime.fromMillisecondsSinceEpoch(row.lastServiceDate!)
          : null,
      serviceIntervalDays: row.serviceIntervalDays,
      notes: row.notes,
      isActive: row.isActive,
    );
  }
}
