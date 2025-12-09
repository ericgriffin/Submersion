import 'package:drift/drift.dart';

part 'database.g.dart';

// ============================================================================
// Table Definitions
// ============================================================================

/// Dive log entries
class Dives extends Table {
  TextColumn get id => text()();
  IntColumn get diveNumber => integer().nullable()();
  IntColumn get dateTime => integer()(); // Unix timestamp
  IntColumn get duration => integer().nullable()(); // seconds
  RealColumn get maxDepth => real().nullable()();
  RealColumn get avgDepth => real().nullable()();
  RealColumn get waterTemp => real().nullable()();
  RealColumn get airTemp => real().nullable()();
  TextColumn get visibility => text().nullable()();
  TextColumn get diveType => text().withDefault(const Constant('recreational'))();
  TextColumn get buddy => text().nullable()();
  TextColumn get diveMaster => text().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get siteId => text().nullable().references(DiveSites, #id)();
  IntColumn get rating => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Time-series dive profile data points
class DiveProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get diveId => text().references(Dives, #id, onDelete: KeyAction.cascade)();
  IntColumn get timestamp => integer()(); // seconds from dive start
  RealColumn get depth => real()();
  RealColumn get pressure => real().nullable()(); // bar
  RealColumn get temperature => real().nullable()();
  IntColumn get heartRate => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Dive sites/locations
class DiveSites extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().withDefault(const Constant(''))();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get maxDepth => real().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get region => text().nullable()();
  RealColumn get rating => real().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tanks used during dives
class DiveTanks extends Table {
  TextColumn get id => text()();
  TextColumn get diveId => text().references(Dives, #id, onDelete: KeyAction.cascade)();
  TextColumn get gearId => text().nullable().references(Gear, #id)();
  RealColumn get volume => real().nullable()(); // liters
  IntColumn get startPressure => integer().nullable()(); // bar
  IntColumn get endPressure => integer().nullable()(); // bar
  RealColumn get o2Percent => real().withDefault(const Constant(21.0))();
  RealColumn get hePercent => real().withDefault(const Constant(0.0))();
  IntColumn get tankOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Gear/equipment catalog
class Gear extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text()(); // regulator, bcd, wetsuit, etc.
  TextColumn get brand => text().nullable()();
  TextColumn get model => text().nullable()();
  TextColumn get serialNumber => text().nullable()();
  IntColumn get purchaseDate => integer().nullable()();
  IntColumn get lastServiceDate => integer().nullable()();
  IntColumn get serviceIntervalDays => integer().nullable()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Junction table for gear used per dive
class DiveGear extends Table {
  TextColumn get diveId => text().references(Dives, #id, onDelete: KeyAction.cascade)();
  TextColumn get gearId => text().references(Gear, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {diveId, gearId};
}

/// Marine life species catalog
class Species extends Table {
  TextColumn get id => text()();
  TextColumn get commonName => text()();
  TextColumn get scientificName => text().nullable()();
  TextColumn get category => text()(); // fish, coral, mammal, etc.
  TextColumn get description => text().nullable()();
  TextColumn get photoPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Marine life sightings per dive
class Sightings extends Table {
  TextColumn get id => text()();
  TextColumn get diveId => text().references(Dives, #id, onDelete: KeyAction.cascade)();
  TextColumn get speciesId => text().references(Species, #id)();
  IntColumn get count => integer().withDefault(const Constant(1))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Photos and media files
class Media extends Table {
  TextColumn get id => text()();
  TextColumn get diveId => text().nullable().references(Dives, #id, onDelete: KeyAction.setNull)();
  TextColumn get siteId => text().nullable().references(DiveSites, #id, onDelete: KeyAction.setNull)();
  TextColumn get filePath => text()();
  TextColumn get fileType => text().withDefault(const Constant('photo'))();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  IntColumn get takenAt => integer().nullable()();
  TextColumn get caption => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Application settings key-value store
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {key};
}

// ============================================================================
// Database Class
// ============================================================================

@DriftDatabase(
  tables: [
    Dives,
    DiveProfiles,
    DiveSites,
    DiveTanks,
    Gear,
    DiveGear,
    Species,
    Sightings,
    Media,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Handle migrations here as schema evolves
        // See MIGRATION_STRATEGY.md for details
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}