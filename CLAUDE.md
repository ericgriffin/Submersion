# Submersion - Development Guide

## Project Overview

Submersion is a Flutter dive logging application for scuba divers. It provides dive tracking, site management, gear tracking, and statistics visualization.

**Tech Stack:**
- Flutter 3.x with Material 3 design
- Drift ORM for SQLite database
- Riverpod for state management
- go_router for navigation
- Targets: iOS, Android, macOS, Windows, Linux

## Quick Start

```bash
# Install dependencies
flutter pub get

# Generate database code (required after schema changes)
dart run build_runner build --delete-conflicting-outputs

# Run on macOS
flutter run -d macos

# Run tests
flutter test
```

## Architecture

### Directory Structure
```
lib/
├── main.dart                 # Entry point
├── app.dart                  # Root app widget with ProviderScope
├── core/
│   ├── constants/
│   │   ├── enums.dart        # DiveType, GearType, Visibility, etc.
│   │   └── units.dart        # Measurement unit helpers
│   ├── database/
│   │   ├── database.dart     # Drift table definitions
│   │   └── database.g.dart   # Generated Drift code
│   ├── router/
│   │   └── app_router.dart   # go_router configuration
│   ├── services/
│   │   └── database_service.dart  # Singleton database accessor
│   └── theme/
│       ├── app_theme.dart    # Light/dark theme definitions
│       └── app_colors.dart   # Color palette
├── features/
│   ├── dive_log/             # Dive logging feature
│   │   ├── data/repositories/dive_repository_impl.dart
│   │   ├── domain/entities/dive.dart
│   │   └── presentation/
│   │       ├── pages/        # DiveListPage, DiveDetailPage, DiveEditPage
│   │       └── providers/dive_providers.dart
│   ├── dive_sites/           # Dive site management
│   │   ├── data/repositories/site_repository_impl.dart
│   │   ├── domain/entities/dive_site.dart
│   │   └── presentation/
│   │       ├── pages/        # SiteListPage, SiteDetailPage
│   │       └── providers/site_providers.dart
│   ├── gear/                 # Gear tracking
│   │   ├── data/repositories/gear_repository_impl.dart
│   │   ├── domain/entities/gear_item.dart
│   │   └── presentation/
│   │       ├── pages/gear_list_page.dart
│   │       └── providers/gear_providers.dart
│   ├── settings/             # App settings
│   │   └── presentation/pages/settings_page.dart
│   └── statistics/           # Dive statistics
│       └── presentation/pages/statistics_page.dart
└── shared/
    └── widgets/main_scaffold.dart  # Shell navigation scaffold
```

### Key Patterns

**Riverpod State Management:**
- `Provider` for repository singletons
- `FutureProvider` for async data fetching
- `FutureProvider.family` for parameterized queries (by ID, search query)
- `StateNotifierProvider` + `StateNotifier` for mutable state with CRUD operations

**Domain/Data Separation:**
- Domain entities in `domain/entities/` are clean Dart classes with `copyWith`
- Data layer uses Drift ORM with generated classes
- Import aliases (`as domain`) resolve naming conflicts between Drift and domain classes

**Navigation:**
- go_router with ShellRoute for persistent bottom navigation
- Routes: `/dives`, `/sites`, `/gear`, `/stats`, `/settings`
- Detail/edit pages at `/dives/:id`, `/dives/new`, etc.

## Database Schema

Tables defined in `lib/core/database/database.dart`:

| Table | Description |
|-------|-------------|
| `dives` | Core dive logs with date, depth, duration, etc. |
| `dive_profiles` | Time-series depth/temp data points per dive |
| `dive_tanks` | Tank info (volume, gas mix, pressures) per dive |
| `dive_sites` | Dive site locations with GPS, descriptions |
| `gear` | Equipment items with service tracking |
| `gear_service_records` | Service history per gear item |
| `marine_life_sightings` | Species spotted on dives |
| `species` | Marine life species reference data |

**Important:** The `dives` table uses `diveDateTime` (not `dateTime`) as the column name to avoid conflict with Drift's `Table.dateTime` method.

## Feature Status

### Completed
- [x] Database schema and Drift ORM setup
- [x] Theme system (light/dark Material 3)
- [x] Navigation shell with bottom nav
- [x] **Dive Log Feature**
  - [x] Repository with full CRUD operations
  - [x] Riverpod providers connected
  - [x] DiveListPage showing real data
  - [x] DiveDetailPage displaying dive info
  - [x] DiveEditPage for creating/editing dives
  - [x] Delete functionality
- [x] **Statistics Feature**
  - [x] Real statistics from database (total dives, time, depth)

### Completed Features
- [x] **Dive Sites Feature**
  - [x] Repository implementation
  - [x] Riverpod providers
  - [x] SiteListPage connected to providers
  - [x] SiteEditPage for creating/editing sites
  - [x] SiteDetailPage showing real data
  - [x] Site picker in dive edit form
  - [x] Map view for sites (flutter_map with OpenStreetMap)

- [x] **Gear Feature**
  - [x] Repository implementation
  - [x] Riverpod providers
  - [x] GearListPage connected to providers
  - [x] AddGearSheet saves via notifier
  - [x] GearDetailPage with service tracking display
  - [x] GearEditPage for creating/editing gear

- [x] **Search & Filter**
  - [x] Dive list search (DiveSearchDelegate)
  - [x] Dive list filters (DiveFilterState with date range, dive type, site, depth range)
  - [x] Site search (SiteSearchDelegate)
  - [x] Gear search (GearSearchDelegate)

- [x] **Dive Profile Visualization**
  - [x] Chart showing depth over time (fl_chart LineChart)
  - [x] Temperature overlay toggle
  - [ ] NDL/deco info display (requires decompression algorithms)

- [x] **Settings**
  - [x] Unit preferences (metric/imperial with quick toggle)
  - [x] Default values (tank volume, start pressure, dive type)
  - [x] Theme selection (light/dark/system)
  - [x] Settings persistence (SharedPreferences)

- [x] **Data Import/Export**
  - [x] CSV export (dives, sites, gear)
  - [x] CSV import with flexible column parsing
  - [x] PDF logbook export
  - [x] UDDF export (Universal Dive Data Format v3.2.0)
  - [x] UDDF import with profile and gas mix parsing
  - [x] Database backup/restore

- [x] **Marine Life Sightings**
  - [x] Species database with 40+ common species
  - [x] Species repository with search
  - [x] Sightings logging on dive edit page
  - [x] Sightings display on dive detail page

- [x] **Statistics**
  - [x] Overview cards (total dives, time, max depth, sites visited)
  - [x] Dives by month bar chart (fl_chart)
  - [x] Depth distribution pie chart
  - [x] Top dive sites ranked list

### In Progress / TODO
- [ ] **Additional Features**
  - [ ] Photo attachments
  - [ ] Buddy/certification management
  - [ ] Dive computer Bluetooth import (requires libdivecomputer FFI)

## Known Issues / Technical Debt

1. **Import Conflicts:** Domain entities use `as domain` alias to avoid conflicts with Drift-generated classes. This is intentional.

2. **Flutter Visibility Conflict:** In `dive_edit_page.dart`, Flutter's `Visibility` widget conflicts with the app's `Visibility` enum. Fixed with `hide Visibility` on the material import.

3. **Deprecation Warning:** `withOpacity()` is deprecated. Consider migrating to `Color.withValues()` in theme files.

4. **Missing Error Handling:** Repository methods don't have comprehensive error handling/logging.

5. **N+1 Query Issue:** `_mapRowToDive` makes individual queries for tanks, profile, and site per dive. Consider optimizing with joins for list views.

## Code Conventions

- **Imports:** Group by: dart, flutter, packages, local (relative)
- **File naming:** snake_case for files, PascalCase for classes
- **Provider naming:** `<noun>Provider` for data, `<noun>NotifierProvider` for mutable state
- **Entity copyWith:** All domain entities should have `copyWith` method
- **Null safety:** Project uses sound null safety

## Useful Commands

```bash
# Watch mode for code generation
dart run build_runner watch

# Clean rebuild
flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs

# Run specific platform
flutter run -d macos
flutter run -d chrome  # Web
flutter run -d ios

# Analyze code
flutter analyze

# Format code
dart format lib/
```

## Next Steps (Priority Order)

1. **Photo Attachments** - Add photo gallery to dives with storage and thumbnails
2. **Buddy Management** - Track dive buddies and certifications
3. **Dive Computer Import** - Bluetooth connectivity with libdivecomputer FFI wrapper
4. **NDL/Deco Display** - Implement Buhlmann decompression algorithm for profile visualization
5. **Offline Maps** - Cache map tiles for offline dive site viewing
