# Immediate Development Tasks

## Completed
- [x] Fix Navigator lock error on import/export (caused by showing dialog before file picker)
- [x] Enhanced UDDF import to create dive sites and link to dives
- [x] Parse buddies from UDDF diver section (supports multiple buddies per dive)
- [x] Parse tank data with volume and gas mix from UDDF
- [x] Parse equipment used (weight/lead) from UDDF
- [x] Connect SiteListPage to providers
- [x] Create SiteEditPage for adding/editing sites
- [x] Connect SiteDetailPage to providers
- [x] Connect GearListPage to providers
- [x] Wire up AddGearSheet to save gear via notifier
- [x] Add site picker to DiveEditPage
- [x] Create GearDetailPage with service tracking
- [x] Create GearEditPage for editing gear
- [x] Add routes for gear detail/edit
- [x] Implement dive list search
- [x] Fix statistics page overflow
- [x] Implement site search (SiteSearchDelegate)
- [x] Implement gear search (GearSearchDelegate)
- [x] Implement dive list filters (date range, dive type, site, depth range)
- [x] Dive profile visualization (DiveProfileChart with fl_chart)
- [x] Settings persistence (shared_preferences, theme, units)
- [x] Map view for dive sites (flutter_map with OpenStreetMap)

---

## Task 1: Marine Life Sightings - COMPLETED

**Completed Implementation:**
- [x] Created marine_life feature with domain entities (Species, Sighting)
- [x] Created SpeciesRepository with full CRUD, search, and seed data (40+ common species)
- [x] Created species providers (allSpeciesProvider, speciesSearchProvider, speciesByCategoryProvider, diveSightingsProvider, SightingsNotifier)
- [x] Added marine life logging section to dive edit page with species search/picker
- [x] Added sightings display on dive detail page
- [x] Auto-seed species database on app startup

---

## Task 2: Data Import/Export - COMPLETED

**Completed:**
- [x] Created ExportService with CSV and PDF export capabilities
- [x] CSV export for dives, sites, and gear
- [x] PDF dive logbook generation with cover page, summary, and dive entries
- [x] Export providers and UI in settings page
- [x] Share sheet integration for exporting files
- [x] UDDF export (Universal Dive Data Format v3.2.0)
- [x] CSV import functionality with flexible column parsing
- [x] UDDF import with full dive profile, gas mix, and site data parsing

---

## Task 3: Backup & Restore - COMPLETED

**Completed:**
- [x] Database backup with timestamped filename (submersion_backup_YYYY-MM-DD_HHmmss.db)
- [x] Share sheet integration for backup file distribution
- [x] Restore from backup with file picker (.db files)
- [x] Restore confirmation dialog with data replacement warning
- [x] Provider invalidation after restore to refresh all data
- [x] Connected backup/restore to settings UI

---

## Task 4: Single Dive Export - COMPLETED

**Completed:**
- [x] Export menu on dive detail page (replaces "coming soon" placeholder)
- [x] Single dive export to PDF (printable logbook entry)
- [x] Single dive export to CSV
- [x] Single dive export to UDDF
- [x] Loading dialog during export with success/error feedback

---

## Task 5: Statistics Charts - COMPLETED

**Completed:**
- [x] Expanded DiveStatistics class with chart data (divesByMonth, depthDistribution, topSites)
- [x] SQL queries for monthly dive counts (last 12 months)
- [x] SQL queries for depth range distribution (0-10m, 10-20m, 20-30m, 30-40m, 40m+)
- [x] SQL queries for top 5 dive sites by dive count
- [x] Interactive bar chart for "Dives by Month" using fl_chart
- [x] Pie chart for depth distribution with color-coded legend
- [x] Ranked top sites list with medal-style badges (gold/silver/bronze)
- [x] Avg depth and avg temperature mini-stats display

---

## Code Patterns Reference

### SearchDelegate Pattern (implemented in dive/site/gear lists)
```dart
class MySearchDelegate extends SearchDelegate<MyItem?> {
  final WidgetRef ref;
  MySearchDelegate(this.ref);

  @override
  Widget buildResults(BuildContext context) {
    final results = ref.watch(mySearchProvider(query));
    // return ListView of results
  }
}
```

### Filter State Pattern (implemented in dive list)
```dart
class DiveFilterState {
  final DateTime? startDate;
  final DateTime? endDate;
  final DiveType? diveType;
  final String? siteId;
  final double? minDepth;
  final double? maxDepth;
  // ...

  List<Dive> apply(List<Dive> dives) {
    return dives.where((dive) {
      // Apply filters
    }).toList();
  }
}

final diveFilterProvider = StateProvider<DiveFilterState>((ref) => const DiveFilterState());
final filteredDivesProvider = Provider<AsyncValue<List<Dive>>>((ref) {
  final divesAsync = ref.watch(diveListNotifierProvider);
  final filter = ref.watch(diveFilterProvider);
  return divesAsync.whenData((dives) => filter.apply(dives));
});
```
