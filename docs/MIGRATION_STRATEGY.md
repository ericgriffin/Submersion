# Database Migration Strategy

This document outlines the database migration strategy for Submersion, ensuring safe and reliable schema evolution as the application grows.

## Overview

Submersion uses **Drift** (formerly Moor) as the SQLite ORM for Flutter. Drift provides built-in migration support that we leverage for schema versioning.

## Migration Philosophy

1. **Never lose user data** - All migrations must preserve existing data
2. **Forward-only migrations** - We don't support downgrading
3. **Atomic migrations** - Each migration runs in a transaction
4. **Tested migrations** - All migrations have integration tests
5. **Incremental versions** - Schema version increments by 1 for each migration

## Schema Versioning

### Version Format

```
schemaVersion = N
```

Where N is an integer starting from 1 and incrementing with each migration.

### Current Schema

```dart
@override
int get schemaVersion => 1;  // Initial release
```

### Version History

| Version | Date | Description |
|---------|------|-------------|
| 1 | Initial | Initial schema with core tables |
| 2 | TBD | (Future) Add species catalog |
| 3 | TBD | (Future) Add certification tracking |

## Migration Implementation

### Location

Migrations are defined in:
```
lib/core/database/migrations/
├── migration_v1_to_v2.dart
├── migration_v2_to_v3.dart
└── ...
```

### Migration Structure

```dart
// lib/core/database/migrations/migration_v1_to_v2.dart

import 'package:drift/drift.dart';

Future<void> migrateV1ToV2(Migrator m, Schema2 schema) async {
  // Add new tables
  await m.createTable(schema.newTable);

  // Add new columns with defaults
  await m.addColumn(schema.existingTable, schema.existingTable.newColumn);

  // Migrate data if needed
  await m.database.customStatement('''
    UPDATE existing_table
    SET new_column = 'default_value'
    WHERE new_column IS NULL
  ''');
}
```

### Database Configuration

```dart
// lib/core/database/database.dart

@DriftDatabase(tables: [...])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;  // Current version

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        // Create all tables for fresh installs
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Run migrations sequentially
        for (var version = from; version < to; version++) {
          await _runMigration(m, version, version + 1);
        }
      },
      beforeOpen: (details) async {
        // Enable foreign keys
        await customStatement('PRAGMA foreign_keys = ON');

        // Verify database integrity after migration
        if (details.wasCreated || details.hadUpgrade) {
          await _verifyIntegrity();
        }
      },
    );
  }

  Future<void> _runMigration(Migrator m, int from, int to) async {
    switch (from) {
      case 1:
        await migrateV1ToV2(m, Schema2());
        break;
      case 2:
        await migrateV2ToV3(m, Schema3());
        break;
      // Add more cases as needed
    }
  }

  Future<void> _verifyIntegrity() async {
    final result = await customSelect('PRAGMA integrity_check').get();
    if (result.first.data['integrity_check'] != 'ok') {
      throw Exception('Database integrity check failed');
    }
  }
}
```

## Common Migration Patterns

### 1. Adding a New Table

```dart
Future<void> migrateV1ToV2(Migrator m, Schema2 schema) async {
  await m.createTable(schema.certifications);
}
```

### 2. Adding a Column with Default Value

```dart
Future<void> migrateV2ToV3(Migrator m, Schema3 schema) async {
  // Add nullable column first
  await m.addColumn(schema.dives, schema.dives.surfaceInterval);

  // Then populate with calculated values
  await m.database.customStatement('''
    UPDATE dives AS d1
    SET surface_interval = (
      SELECT (d1.date_time - d2.date_time - d2.duration)
      FROM dives AS d2
      WHERE d2.date_time < d1.date_time
      ORDER BY d2.date_time DESC
      LIMIT 1
    )
  ''');
}
```

### 3. Renaming a Column

SQLite doesn't support direct column renaming. Strategy:

```dart
Future<void> migrateV3ToV4(Migrator m, Schema4 schema) async {
  // 1. Create new table with correct schema
  await m.createTable(schema.divesNew);

  // 2. Copy data
  await m.database.customStatement('''
    INSERT INTO dives_new (id, old_name_as_new, ...)
    SELECT id, old_column_name, ...
    FROM dives
  ''');

  // 3. Drop old table
  await m.database.customStatement('DROP TABLE dives');

  // 4. Rename new table
  await m.database.customStatement('ALTER TABLE dives_new RENAME TO dives');

  // 5. Recreate indexes
  await m.database.customStatement(
    'CREATE INDEX idx_dives_date ON dives(date_time)'
  );
}
```

### 4. Changing Column Type

Similar to renaming - recreate the table:

```dart
Future<void> migrateV4ToV5(Migrator m, Schema5 schema) async {
  // 1. Create temp table
  await m.database.customStatement('''
    CREATE TABLE dives_temp AS
    SELECT
      id,
      CAST(max_depth AS REAL) as max_depth,  -- Convert INTEGER to REAL
      ...
    FROM dives
  ''');

  // 2. Drop and recreate
  await m.database.customStatement('DROP TABLE dives');
  await m.createTable(schema.dives);

  // 3. Copy back
  await m.database.customStatement('''
    INSERT INTO dives SELECT * FROM dives_temp
  ''');

  // 4. Cleanup
  await m.database.customStatement('DROP TABLE dives_temp');
}
```

### 5. Adding an Index

```dart
Future<void> migrateV5ToV6(Migrator m, Schema6 schema) async {
  await m.database.customStatement(
    'CREATE INDEX IF NOT EXISTS idx_dives_site ON dives(site_id)'
  );
}
```

### 6. Removing a Table

```dart
Future<void> migrateV6ToV7(Migrator m, Schema7 schema) async {
  // Optional: backup data before removal
  await m.database.customStatement('''
    CREATE TABLE deprecated_backup AS SELECT * FROM old_table
  ''');

  await m.database.customStatement('DROP TABLE old_table');
}
```

### 7. Adding Foreign Key Constraint

SQLite doesn't support adding foreign keys to existing tables. Recreate:

```dart
Future<void> migrateV7ToV8(Migrator m, Schema8 schema) async {
  // 1. Disable foreign keys during migration
  await m.database.customStatement('PRAGMA foreign_keys = OFF');

  // 2. Recreate table with foreign key
  await m.database.customStatement('''
    CREATE TABLE dives_new (
      id TEXT PRIMARY KEY,
      site_id TEXT REFERENCES dive_sites(id) ON DELETE SET NULL,
      ...
    )
  ''');

  // 3. Copy valid data only
  await m.database.customStatement('''
    INSERT INTO dives_new
    SELECT d.* FROM dives d
    LEFT JOIN dive_sites s ON d.site_id = s.id
    WHERE d.site_id IS NULL OR s.id IS NOT NULL
  ''');

  // 4. Swap tables
  await m.database.customStatement('DROP TABLE dives');
  await m.database.customStatement('ALTER TABLE dives_new RENAME TO dives');

  // 5. Re-enable foreign keys
  await m.database.customStatement('PRAGMA foreign_keys = ON');
}
```

## Data Migration from Other Apps

### Importing from Subsurface (XML/Git)

```dart
class SubsurfaceImporter {
  Future<List<Dive>> importFromXml(String xmlContent) async {
    final document = XmlDocument.parse(xmlContent);
    final dives = <Dive>[];

    for (final diveElement in document.findAllElements('dive')) {
      dives.add(Dive(
        id: const Uuid().v4(),
        dateTime: DateTime.parse(diveElement.getAttribute('date')!),
        duration: _parseDuration(diveElement.getAttribute('duration')),
        maxDepth: double.parse(diveElement.getAttribute('maxdepth') ?? '0'),
        // ... map other fields
      ));
    }

    return dives;
  }
}
```

### Importing from UDDF

```dart
class UddfImporter {
  Future<ImportResult> importUddf(File uddfFile) async {
    final content = await uddfFile.readAsString();
    final document = XmlDocument.parse(content);

    // UDDF structure:
    // /uddf/profiledata/repetitiongroup/dive

    final dives = <Dive>[];
    final sites = <DiveSite>[];
    final gear = <GearItem>[];

    // Parse dive sites first
    for (final siteEl in document.findAllElements('site')) {
      sites.add(_parseSite(siteEl));
    }

    // Parse dives
    for (final diveEl in document.findAllElements('dive')) {
      dives.add(_parseDive(diveEl, sites));
    }

    return ImportResult(
      dives: dives,
      sites: sites,
      gear: gear,
    );
  }
}
```

## Testing Migrations

### Unit Tests

```dart
// test/database/migrations_test.dart

void main() {
  group('Database Migrations', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('migration from v1 to v2 preserves dive data', () async {
      // 1. Create v1 database with test data
      final v1Db = await _createV1Database();
      await v1Db.into(v1Db.dives).insert(DivesCompanion(
        id: const Value('test-dive-1'),
        dateTime: Value(DateTime.now().millisecondsSinceEpoch),
        maxDepth: const Value(25.5),
      ));
      await v1Db.close();

      // 2. Open with v2 schema (triggers migration)
      final v2Db = AppDatabase(NativeDatabase(dbFile));

      // 3. Verify data preserved
      final dives = await v2Db.select(v2Db.dives).get();
      expect(dives.length, 1);
      expect(dives.first.id, 'test-dive-1');
      expect(dives.first.maxDepth, 25.5);

      await v2Db.close();
    });

    test('fresh install creates latest schema', () async {
      final freshDb = AppDatabase(NativeDatabase.memory());

      // Verify all tables exist
      final tables = await freshDb.customSelect(
        "SELECT name FROM sqlite_master WHERE type='table'"
      ).get();

      expect(tables.map((r) => r.data['name']), containsAll([
        'dives',
        'dive_profiles',
        'dive_sites',
        'gear',
        // ... all expected tables
      ]));

      await freshDb.close();
    });
  });
}
```

### Integration Tests

```dart
// integration_test/migration_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app handles database upgrade gracefully', (tester) async {
    // 1. Pre-populate with old schema
    // 2. Launch app (triggers migration)
    // 3. Verify UI shows migrated data
    // 4. Verify no errors
  });
}
```

## Backup Before Migration

Always encourage users to backup before major updates:

```dart
class MigrationSafetyService {
  Future<void> performSafeMigration() async {
    // 1. Create automatic backup
    final backupPath = await _createBackup();

    try {
      // 2. Run migration
      await DatabaseService.instance.initialize();

      // 3. Verify integrity
      await _verifyIntegrity();

      // 4. Clean up backup after success (or keep for N days)
      await _scheduleBackupCleanup(backupPath, days: 7);

    } catch (e) {
      // 5. Restore from backup on failure
      await _restoreBackup(backupPath);
      rethrow;
    }
  }

  Future<String> _createBackup() async {
    final dbPath = await DatabaseService.instance.databasePath;
    final backupDir = await getApplicationSupportDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = '${backupDir.path}/backup_$timestamp.db';

    await File(dbPath).copy(backupPath);
    return backupPath;
  }
}
```

## Rollback Strategy

Since we don't support downgrade migrations:

1. **Automatic Backups**: Create backup before each migration
2. **Manual Restore**: Users can restore from backup if needed
3. **Export Before Update**: Prompt users to export data before major updates
4. **Keep Multiple Backups**: Retain last N backups

```dart
class BackupManager {
  static const maxBackups = 5;

  Future<void> cleanOldBackups() async {
    final backupDir = await _getBackupDirectory();
    final backups = backupDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.db'))
        .toList()
      ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));

    // Keep only the most recent backups
    for (var i = maxBackups; i < backups.length; i++) {
      await backups[i].delete();
    }
  }
}
```

## Version Checking

Display migration status to users:

```dart
class DatabaseVersionInfo {
  final int currentVersion;
  final int targetVersion;
  final bool needsMigration;
  final List<String> migrationNotes;

  DatabaseVersionInfo({
    required this.currentVersion,
    required this.targetVersion,
  }) : needsMigration = currentVersion < targetVersion,
       migrationNotes = _getMigrationNotes(currentVersion, targetVersion);

  static List<String> _getMigrationNotes(int from, int to) {
    final notes = <String>[];
    for (var v = from + 1; v <= to; v++) {
      switch (v) {
        case 2:
          notes.add('Added species catalog for marine life tracking');
          break;
        case 3:
          notes.add('Added certification tracking');
          break;
        // Add notes for each version
      }
    }
    return notes;
  }
}
```

## Emergency Recovery

If database becomes corrupted:

```dart
class EmergencyRecovery {
  /// Attempt to recover data from corrupted database
  Future<RecoveryResult> attemptRecovery(String corruptDbPath) async {
    final result = RecoveryResult();

    try {
      // 1. Try to open and read what we can
      final corruptDb = NativeDatabase(File(corruptDbPath));

      // 2. Export each table individually
      for (final table in ['dives', 'dive_sites', 'gear']) {
        try {
          final rows = await corruptDb.customSelect('SELECT * FROM $table').get();
          result.recovered[table] = rows;
        } catch (e) {
          result.failed[table] = e.toString();
        }
      }

      await corruptDb.close();

    } catch (e) {
      result.criticalError = e.toString();
    }

    return result;
  }

  /// Create new database and import recovered data
  Future<void> rebuildFromRecovery(RecoveryResult recovery) async {
    // Create fresh database
    final freshDb = AppDatabase(NativeDatabase.memory());

    // Import recovered data
    for (final entry in recovery.recovered.entries) {
      await _importTableData(freshDb, entry.key, entry.value);
    }
  }
}
```

## Checklist for New Migrations

When adding a new migration:

- [ ] Increment `schemaVersion` in database.dart
- [ ] Create migration file in `migrations/`
- [ ] Add case to `_runMigration` switch
- [ ] Write unit tests for the migration
- [ ] Write integration tests
- [ ] Update version history table in this document
- [ ] Add migration notes for user display
- [ ] Test with real user data (anonymized)
- [ ] Test upgrade path from oldest supported version
- [ ] Document any breaking changes
- [ ] Update CHANGELOG.md
