# Submersion - Dive Log Application Architecture

## Executive Summary

Submersion is an open-source dive logging application designed to run natively on macOS, Windows, Android, and iOS with local data storage. It aims to combine the best features of Subsurface and MacDive while providing a modern, cross-platform experience.

## Core Features

### Essential Features (from Subsurface & MacDive)

#### Dive Logging & Management
- Digital dive log with comprehensive dive data entry
- Support for single and multi-tank dives
- Air, Nitrox, Trimix, and multiple gas support
- Dive profile visualization (depth, time, temperature)
- Tank pressure tracking and air consumption analysis
- Surface interval tracking
- Dive statistics and analytics

#### Dive Computer Integration
- Import from 50+ dive computer models (Shearwater, Suunto, Mares, Oceanic, Scubapro, etc.)
- Bluetooth, Bluetooth LE, and USB serial support
- Automatic dive data import
- Support for newest models (Shearwater Petrel 3, Perdix 2, etc.)

#### Dive Planning
- Decompression planning (Buhlmann and VPM-B algorithms)
- Multi-gas planning
- Gas consumption calculations
- No-decompression limit (NDL) calculations

#### Location & Mapping
- GPS tracking and dive site management
- Integration with maps for dive site visualization
- EXIF data extraction from photos for automatic GPS tagging
- Dive site database with conditions, notes, ratings

#### Gear Management
- Equipment catalog (regulators, BCDs, wetsuits, computers, etc.)
- Service reminders and maintenance tracking
- Usage statistics per gear item
- Tank management with pressure and gas mix tracking

#### Marine Life Logging
- Species identification and cataloging
- Encounter logging per dive
- Wishlist management
- Photo integration with species

#### Data Visualization
- Dive profile graphs (depth, pressure, temperature)
- Velocity and air consumption overlays
- Statistics dashboards
- Dive trends and analytics

#### Import/Export
- Import from other dive log applications
- Export to common formats (CSV, PDF, UDDF, XML)
- Backup and restore functionality
- Cross-platform data portability

## Technology Stack Recommendation

### Cross-Platform Framework: Flutter

**Rationale:**
- Single codebase for all platforms (macOS, Windows, iOS, Android)
- 42% developer adoption globally (highest among cross-platform frameworks)
- Excellent performance with native compilation
- Rich UI components with Material Design and Cupertino widgets
- Strong community and ecosystem
- Built-in support for platform-specific features
- Excellent for data visualization (charts, graphs)

**Alternative Consideration:** React Native
- If team has strong JavaScript/TypeScript expertise
- 35% developer adoption
- Larger third-party library ecosystem
- Better for teams coming from web development

### Local Data Storage

#### Primary Storage Options

**Option 1: SQLite (Recommended)**
- **Advantages:**
  - Industry standard, battle-tested
  - Efficient querying and indexing
  - ACID compliance for data integrity
  - Cross-platform consistency
  - Full-text search capabilities
  - Support for complex queries
  - Excellent performance for large datasets (1000+ dives)
  - Native support on all platforms

- **Implementation:**
  - Use **Drift** (formerly Moor) for Flutter
    - Type-safe SQL queries
    - Compile-time validation
    - Migration support
    - Reactive streams
  - Or **sqflite** for simpler implementation
  - Database encryption via **SQLCipher** for sensitive data

**Option 2: XML Files**
- **Advantages:**
  - Human-readable
  - Easy to diff/version control
  - Standard format (UDDF - Universal Dive Data Format)
  - Compatible with other dive log software
  - Simple backup/restore

- **Disadvantages:**
  - Slower for large datasets
  - Limited querying capabilities
  - Must load entire file for queries
  - More complex indexing

- **Use Case:**
  - Import/export format
  - Data exchange with other applications
  - Archive format

**Recommended Approach: Hybrid**
- **SQLite** as primary storage for performance
- **XML export** capability for compatibility and backups
- Support **UDDF format** for interoperability with Subsurface and other apps

#### Data Storage Structure

```
Submersion/
├── Data/
│   ├── dives.db              # SQLite database (primary)
│   ├── backups/
│   │   ├── backup_YYYYMMDD.uddf
│   │   └── backup_YYYYMMDD.db
│   └── exports/
│       └── export_YYYYMMDD.xml
├── Media/
│   ├── photos/
│   │   ├── dive_123_1.jpg
│   │   └── dive_123_2.jpg
│   └── dive_computer_files/
│       └── import_YYYYMMDD_raw.bin
└── Settings/
    └── preferences.json
```

### Database Schema (SQLite)

```sql
-- Dives table
CREATE TABLE dives (
    id TEXT PRIMARY KEY,
    dive_number INTEGER,
    date_time INTEGER NOT NULL,  -- Unix timestamp
    duration INTEGER,  -- seconds
    max_depth REAL,
    avg_depth REAL,
    water_temp REAL,
    air_temp REAL,
    visibility TEXT,
    dive_type TEXT,
    buddy TEXT,
    dive_master TEXT,
    notes TEXT,
    site_id TEXT,
    rating INTEGER,
    created_at INTEGER,
    updated_at INTEGER,
    FOREIGN KEY (site_id) REFERENCES dive_sites(id)
);

-- Dive profiles (time-series data)
CREATE TABLE dive_profiles (
    id TEXT PRIMARY KEY,
    dive_id TEXT NOT NULL,
    timestamp INTEGER NOT NULL,  -- seconds from dive start
    depth REAL NOT NULL,
    pressure REAL,  -- bar
    temperature REAL,
    heart_rate INTEGER,
    FOREIGN KEY (dive_id) REFERENCES dives(id) ON DELETE CASCADE
);
CREATE INDEX idx_profile_dive ON dive_profiles(dive_id, timestamp);

-- Dive sites
CREATE TABLE dive_sites (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    latitude REAL,
    longitude REAL,
    max_depth REAL,
    country TEXT,
    region TEXT,
    rating REAL,
    notes TEXT,
    created_at INTEGER,
    updated_at INTEGER
);

-- Tanks used in dives
CREATE TABLE dive_tanks (
    id TEXT PRIMARY KEY,
    dive_id TEXT NOT NULL,
    tank_id TEXT,  -- reference to gear if tracked
    volume REAL,  -- liters
    start_pressure INTEGER,  -- bar
    end_pressure INTEGER,  -- bar
    o2_percent REAL,
    he_percent REAL,
    tank_order INTEGER,  -- for multi-tank dives
    FOREIGN KEY (dive_id) REFERENCES dives(id) ON DELETE CASCADE,
    FOREIGN KEY (tank_id) REFERENCES gear(id)
);

-- Gear/Equipment
CREATE TABLE gear (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL,  -- regulator, bcd, wetsuit, tank, etc.
    brand TEXT,
    model TEXT,
    serial_number TEXT,
    purchase_date INTEGER,
    last_service_date INTEGER,
    service_interval_days INTEGER,
    notes TEXT,
    is_active BOOLEAN DEFAULT 1,
    created_at INTEGER,
    updated_at INTEGER
);

-- Gear usage tracking
CREATE TABLE dive_gear (
    dive_id TEXT NOT NULL,
    gear_id TEXT NOT NULL,
    PRIMARY KEY (dive_id, gear_id),
    FOREIGN KEY (dive_id) REFERENCES dives(id) ON DELETE CASCADE,
    FOREIGN KEY (gear_id) REFERENCES gear(id) ON DELETE CASCADE
);

-- Marine life species catalog
CREATE TABLE species (
    id TEXT PRIMARY KEY,
    common_name TEXT NOT NULL,
    scientific_name TEXT,
    category TEXT,  -- fish, coral, mammal, etc.
    description TEXT,
    photo_url TEXT
);

-- Marine life sightings per dive
CREATE TABLE sightings (
    id TEXT PRIMARY KEY,
    dive_id TEXT NOT NULL,
    species_id TEXT NOT NULL,
    count INTEGER DEFAULT 1,
    notes TEXT,
    FOREIGN KEY (dive_id) REFERENCES dives(id) ON DELETE CASCADE,
    FOREIGN KEY (species_id) REFERENCES species(id)
);

-- Photos/media
CREATE TABLE media (
    id TEXT PRIMARY KEY,
    dive_id TEXT,
    site_id TEXT,
    file_path TEXT NOT NULL,
    file_type TEXT,  -- photo, video
    latitude REAL,  -- from EXIF
    longitude REAL,
    taken_at INTEGER,
    caption TEXT,
    FOREIGN KEY (dive_id) REFERENCES dives(id) ON DELETE SET NULL,
    FOREIGN KEY (site_id) REFERENCES dive_sites(id) ON DELETE SET NULL
);

-- Settings/preferences
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at INTEGER
);
```

### Communication Protocols

#### Dive Computer Communication
- **Flutter Blue Plus** - Bluetooth/BLE communication
- **libdivecomputer** (C library) - Via FFI (Foreign Function Interface)
  - Used by Subsurface (open-source)
  - Supports 100+ dive computer models
  - Wrap in Flutter using dart:ffi
  - Cross-platform compatibility

#### Data Formats
- **UDDF (Universal Dive Data Format)** - XML-based standard
  - Import from Subsurface, MacDive, etc.
  - Export for backup and sharing
- **Custom SQLite** - Fast local queries
- **CSV** - Simple export for spreadsheets
- **PDF** - Printable dive logs

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Applications                      │
├──────────────┬──────────────┬──────────────┬────────────────┤
│   macOS      │   Windows    │   Android    │      iOS       │
│   Desktop    │   Desktop    │    Mobile    │     Mobile     │
└──────┬───────┴──────┬───────┴──────┬───────┴────────┬───────┘
       │              │              │                │
       └──────────────┴──────────────┴────────────────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │   Presentation Layer    │
              │  (Flutter Widgets/UI)   │
              └────────────┬────────────┘
                           │
                           ▼
              ┌─────────────────────────┐
              │    Business Logic       │
              │   (BLoC/Riverpod)       │
              └────────────┬────────────┘
                           │
              ┌────────────┴────────────┐
              ▼                         ▼
     ┌────────────────┐        ┌────────────────┐
     │  Local Storage │        │  Import/Export │
     │   (SQLite)     │        │   (XML/UDDF)   │
     └────────┬───────┘        └────────────────┘
              │
              ▼
     ┌────────────────┐
     │  File System   │
     │  (Photos/Docs) │
     └────────────────┘

     ┌────────────────┐
     │ Dive Computer  │
     │   Interface    │
     │  (BLE/USB)     │
     └────────────────┘
```

### Application Architecture (Flutter)

#### Layered Architecture

```
┌──────────────────────────────────────────┐
│         Presentation Layer               │
│  - Screens/Pages                         │
│  - Widgets                               │
│  - UI Components                         │
└──────────────┬───────────────────────────┘
               │
┌──────────────▼───────────────────────────┐
│      Application/Business Logic          │
│  - BLoC/Cubit or Riverpod                │
│  - State Management                      │
│  - Use Cases/Interactors                 │
└──────────────┬───────────────────────────┘
               │
┌──────────────▼───────────────────────────┐
│          Domain Layer                    │
│  - Entities (Dive, Site, Gear, etc.)     │
│  - Repository Interfaces                 │
│  - Business Rules                        │
└──────────────┬───────────────────────────┘
               │
┌──────────────▼───────────────────────────┐
│          Data Layer                      │
│  - Repository Implementations            │
│  - Data Sources (SQLite/XML)             │
│  - DTOs and Mappers                      │
│  - Caching Strategy                      │
└──────────────┬───────────────────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌─────────────┐  ┌─────────────┐
│   SQLite    │  │   XML/UDDF  │
│   Database  │  │   Files     │
└─────────────┘  └─────────────┘
```

#### Project Folder Structure

```
submersion/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── utils/
│   │   └── theme/
│   │
│   ├── features/
│   │   ├── dive_log/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   ├── datasources/
│   │   │   │   └── repositories/
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   ├── repositories/
│   │   │   │   └── usecases/
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       ├── pages/
│   │   │       └── widgets/
│   │   │
│   │   ├── dive_sites/
│   │   ├── gear/
│   │   ├── statistics/
│   │   ├── import_export/
│   │   ├── dive_computer/
│   │   └── settings/
│   │
│   └── shared/
│       ├── widgets/
│       ├── models/
│       └── services/
│
├── test/
├── assets/
│   ├── images/
│   └── icons/
└── platform/
    ├── macos/
    ├── windows/
    ├── ios/
    └── android/
```

### Data Model (Dart/Flutter)

```dart
// Core Dive Entity
class Dive {
  final String id;
  final int diveNumber;
  final DateTime dateTime;
  final Duration duration;
  final double maxDepth;
  final double avgDepth;
  final DiveSite? site;
  final List<DiveTank> tanks;
  final List<DiveProfilePoint> profile;
  final List<Gear> gear;
  final String notes;
  final List<String> photoIds;
  final List<Sighting> sightings;
  final double? waterTemp;
  final double? airTemp;
  final String? visibility;
  final DiveType diveType;
  final String? buddy;
  final String? diveMaster;
  final int? rating;

  Dive({
    required this.id,
    required this.diveNumber,
    required this.dateTime,
    required this.duration,
    required this.maxDepth,
    required this.avgDepth,
    this.site,
    this.tanks = const [],
    this.profile = const [],
    this.gear = const [],
    this.notes = '',
    this.photoIds = const [],
    this.sightings = const [],
    this.waterTemp,
    this.airTemp,
    this.visibility,
    this.diveType = DiveType.recreational,
    this.buddy,
    this.diveMaster,
    this.rating,
  });
}

// Dive Profile Point (time-series)
class DiveProfilePoint {
  final int timestamp;  // seconds from dive start
  final double depth;
  final double? pressure;
  final double? temperature;
  final int? heartRate;

  DiveProfilePoint({
    required this.timestamp,
    required this.depth,
    this.pressure,
    this.temperature,
    this.heartRate,
  });
}

// Dive Site
class DiveSite {
  final String id;
  final String name;
  final String description;
  final GeoPoint? location;
  final double? maxDepth;
  final String? country;
  final String? region;
  final List<String> photoIds;
  final double? rating;
  final String notes;

  DiveSite({
    required this.id,
    required this.name,
    this.description = '',
    this.location,
    this.maxDepth,
    this.country,
    this.region,
    this.photoIds = const [],
    this.rating,
    this.notes = '',
  });
}

// Geo Point
class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint(this.latitude, this.longitude);
}

// Dive Tank
class DiveTank {
  final String id;
  final double volume;  // liters
  final int startPressure;  // bar
  final int endPressure;  // bar
  final GasMix gasMix;
  final int order;  // for multi-tank

  DiveTank({
    required this.id,
    required this.volume,
    required this.startPressure,
    required this.endPressure,
    required this.gasMix,
    this.order = 0,
  });
}

// Gas Mix
class GasMix {
  final double o2;  // percentage 0-100
  final double he;  // percentage 0-100
  double get n2 => 100 - o2 - he;  // calculated

  GasMix({
    required this.o2,
    this.he = 0,
  });

  String get name {
    if (he > 0) return 'Trimix ${o2.toInt()}/${he.toInt()}';
    if (o2 > 21) return 'Nitrox ${o2.toInt()}';
    return 'Air';
  }
}

// Gear/Equipment
class Gear {
  final String id;
  final String name;
  final GearType type;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime? purchaseDate;
  final DateTime? lastServiceDate;
  final int? serviceIntervalDays;
  final String notes;
  final bool isActive;

  Gear({
    required this.id,
    required this.name,
    required this.type,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchaseDate,
    this.lastServiceDate,
    this.serviceIntervalDays,
    this.notes = '',
    this.isActive = true,
  });

  DateTime? get nextServiceDue {
    if (lastServiceDate == null || serviceIntervalDays == null) return null;
    return lastServiceDate!.add(Duration(days: serviceIntervalDays!));
  }

  bool get isServiceDue {
    final dueDate = nextServiceDue;
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate);
  }
}

enum GearType {
  regulator,
  bcd,
  wetsuit,
  drysuit,
  fins,
  mask,
  computer,
  tank,
  weights,
  other,
}

enum DiveType {
  recreational,
  technical,
  freedive,
  training,
  wreck,
  cave,
  ice,
  night,
}

// Marine Life
class Species {
  final String id;
  final String commonName;
  final String? scientificName;
  final String category;
  final String? description;

  Species({
    required this.id,
    required this.commonName,
    this.scientificName,
    required this.category,
    this.description,
  });
}

class Sighting {
  final String id;
  final Species species;
  final int count;
  final String notes;

  Sighting({
    required this.id,
    required this.species,
    this.count = 1,
    this.notes = '',
  });
}
```

### State Management
- **Recommended:** Riverpod or BLoC pattern
- Separates UI from business logic
- Testable and maintainable
- Reactive state updates

### Import/Export System

#### Import Capabilities
1. **UDDF (Universal Dive Data Format)**
   - XML-based standard
   - Import from Subsurface, MacDive, etc.

2. **Dive Computer Direct Import**
   - Via libdivecomputer
   - Proprietary formats from manufacturers

3. **CSV Import**
   - Simple spreadsheet format
   - Field mapping UI

#### Export Capabilities
1. **UDDF XML** - Standard format
2. **SQLite Database** - Full backup
3. **CSV** - For spreadsheet analysis
4. **PDF** - Printable logbook

### Security & Privacy

#### Data Protection
- **Local Encryption:** Optional SQLite encryption (SQLCipher)
- **Photo Privacy:** Local storage only
- **No Tracking:** No analytics or telemetry without opt-in

#### Data Ownership
- User owns all data
- Full export capability
- No vendor lock-in
- Open file formats

### Platform-Specific Considerations

#### macOS/Windows Desktop
- Native file dialogs for import/export
- USB dive computer connectivity
- Larger screen layouts (master-detail)
- Keyboard shortcuts
- Menu bar integration (macOS)
- Drag-and-drop file import
- Multi-window support

#### iOS/Android Mobile
- Touch-optimized UI
- GPS tracking during dive trips
- Bluetooth dive computer connectivity
- Camera integration for photos
- Share functionality
- Responsive layouts
- Swipe gestures

## Development Roadmap

### Phase 1: MVP - Core Logging (2-3 months)
**Goal:** Basic manual dive logging on mobile

- [ ] Project setup (Flutter, Git)
- [ ] SQLite database setup with Drift
- [ ] Core data models (Dive, Site, Tank, Gas)
- [ ] Basic UI screens:
  - [ ] Dive list view
  - [ ] Dive detail/edit form
  - [ ] Dive site picker
  - [ ] Gas mix calculator
- [ ] Manual dive entry
- [ ] Basic statistics (total dives, max depth, total time)
- [ ] SQLite database file backup/restore
- [ ] iOS and Android mobile apps

### Phase 2: Desktop & Visualization (2 months)
**Goal:** Desktop apps with better data visualization

- [ ] macOS and Windows desktop apps
- [ ] Responsive layouts (mobile vs desktop)
- [ ] Dive profile visualization (depth/time graph)
- [ ] Enhanced statistics dashboard
- [ ] Search and filtering
- [ ] Sorting capabilities
- [ ] Dive numbering system

### Phase 3: Gear & Sites (1-2 months)
**Goal:** Comprehensive gear and site management

- [ ] Gear management CRUD
- [ ] Gear service reminders
- [ ] Dive site management
- [ ] Map integration (Google Maps/OpenStreetMap)
- [ ] GPS location from photos (EXIF)
- [ ] Photo gallery per dive
- [ ] Photo storage and thumbnails

### Phase 4: Import/Export (1-2 months)
**Goal:** Interoperability with other apps

- [ ] UDDF XML import
- [ ] UDDF XML export
- [ ] CSV export
- [ ] PDF export (printable logbook)
- [ ] Import wizard UI
- [ ] Data validation

### Phase 5: Dive Computer Integration (2-3 months)
**Goal:** Automatic dive import from computers

- [ ] libdivecomputer FFI wrapper
- [ ] Bluetooth connectivity (Flutter Blue Plus)
- [ ] USB connectivity (desktop)
- [ ] Dive computer selection UI
- [ ] Import progress tracking
- [ ] Support for major brands (Shearwater, Suunto, Mares)
- [ ] Raw profile data parsing

### Phase 6: Advanced Features (2-3 months)
**Goal:** Power user features

- [ ] Marine life catalog
- [ ] Species sightings per dive
- [ ] Advanced statistics
- [ ] Dive planning calculator
- [ ] Decompression algorithms (Buhlmann)
- [ ] Gas consumption planning
- [ ] Advanced filtering

### Phase 7: Polish & Ecosystem (Ongoing)
**Goal:** Production ready

- [ ] Comprehensive testing
- [ ] Performance optimization
- [ ] Additional dive computer support
- [ ] Localization (i18n)
- [ ] Accessibility
- [ ] User documentation
- [ ] Tutorial/onboarding

## Recommended Tools & Libraries

### Flutter Packages

#### Core
- **drift** (^2.x) - Type-safe SQLite ORM
- **sqlite3_flutter_libs** - SQLite native libraries
- **path_provider** - File system paths
- **path** - Path manipulation

#### State Management
- **riverpod** (^2.x) or **flutter_bloc** (^8.x)

#### Navigation
- **go_router** (^14.x) - Declarative routing

#### Serialization
- **freezed** (^2.x) - Immutable models
- **json_serializable** (^6.x) - JSON serialization

#### UI Components
- **fl_chart** (^0.68.x) - Charts and graphs
- **flutter_map** (^7.x) - OpenStreetMap integration
- **google_maps_flutter** (^2.x) - Google Maps (alternative)
- **cached_network_image** (^3.x) - Image caching
- **photo_view** (^0.15.x) - Image viewer

#### Platform Integration
- **flutter_blue_plus** (^1.x) - Bluetooth/BLE
- **permission_handler** (^11.x) - Runtime permissions
- **file_picker** (^8.x) - File selection
- **image_picker** (^1.x) - Camera/gallery
- **share_plus** (^10.x) - Native sharing
- **url_launcher** (^6.x) - Open URLs/files

#### Storage
- **shared_preferences** (^2.x) - Simple key-value storage
- **flutter_secure_storage** (^9.x) - Encrypted storage

#### Utilities
- **intl** (^0.19.x) - Internationalization
- **uuid** (^4.x) - UUID generation
- **xml** (^6.x) - XML parsing for UDDF
- **pdf** (^3.x) - PDF generation
- **csv** (^6.x) - CSV parsing

#### Development
- **flutter_lints** (^4.x) - Linting rules
- **mockito** (^5.x) - Mocking for tests
- **build_runner** (^2.x) - Code generation

### Development Tools
- **Version Control:** Git + GitHub
- **CI/CD:** GitHub Actions
- **Testing:** flutter_test, integration_test
- **Code Quality:** flutter_lints, dart format
- **Documentation:** dartdoc
- **Design:** Figma (UI mockups)

## Open Source Considerations

### Licensing
- **Recommended:** GPL-3.0 (like Subsurface)
  - Ensures derivative works remain open source
  - Protects from proprietary forks
- **Alternative:** MIT or Apache 2.0
  - More permissive
  - Allows proprietary use

### Repository Structure
```
submersion/
├── README.md
├── ARCHITECTURE.md (this file)
├── LICENSE
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── CHANGELOG.md
├── .github/
│   ├── workflows/  # CI/CD
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
├── docs/
├── lib/
├── test/
└── assets/
```

### Community Building
- Clear contribution guidelines
- Code of conduct
- Good first issues
- Documentation
- Public roadmap
- Regular releases
- Responsive to issues/PRs

## Success Metrics

### Technical Metrics
- App load time < 2 seconds
- Smooth 60fps UI
- Crash-free rate > 99.5%
- App size < 30MB
- Database query time < 100ms for typical operations

### User Metrics
- User retention
- Number of dives logged
- Active installations
- GitHub stars and forks
- Community contributions

## Next Steps

1. **Review and validate this architecture**
2. **Set up Git repository** on GitHub
3. **Create Flutter project:**
   ```bash
   flutter create --org com.submersion --platforms=ios,android,macos,windows submersion
   ```
4. **Set up folder structure** (clean architecture)
5. **Initialize Drift database** and schema
6. **Design UI mockups** in Figma
7. **Start Phase 1 development**
8. **Set up CI/CD** (GitHub Actions)
9. **Create CONTRIBUTING.md** and CODE_OF_CONDUCT.md

## References

Based on research of:
- Subsurface: Open-source dive log application
- MacDive: Commercial dive log for macOS/iOS
- Flutter: Cross-platform framework analysis

## Future Considerations (Post-MVP)

### Cloud Sync (Optional Future Feature)
- When ready, could add:
  - User authentication
  - Cloud database (Supabase/Firebase)
  - Multi-device sync
  - Automatic backups
- Keep as optional (local-first always works)

### Community Features (Optional)
- Dive site reviews/ratings
- Photo sharing
- Buddy finding
- Dive trip planning

### Advanced Integrations
- Weather data integration
- Tide information
- Marine life identification AI
- Training certification tracking
