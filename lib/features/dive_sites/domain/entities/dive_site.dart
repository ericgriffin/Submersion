import 'package:equatable/equatable.dart';

/// Dive site/location entity
class DiveSite extends Equatable {
  final String id;
  final String name;
  final String description;
  final GeoPoint? location;
  final double? maxDepth; // meters
  final String? country;
  final String? region;
  final List<String> photoIds;
  final double? rating; // 1-5 stars
  final String notes;
  final SiteConditions? conditions;

  const DiveSite({
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
    this.conditions,
  });

  /// Full location string (region, country)
  String get locationString {
    final parts = <String>[];
    if (region != null && region!.isNotEmpty) parts.add(region!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  bool get hasCoordinates => location != null;

  DiveSite copyWith({
    String? id,
    String? name,
    String? description,
    GeoPoint? location,
    double? maxDepth,
    String? country,
    String? region,
    List<String>? photoIds,
    double? rating,
    String? notes,
    SiteConditions? conditions,
  }) {
    return DiveSite(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      maxDepth: maxDepth ?? this.maxDepth,
      country: country ?? this.country,
      region: region ?? this.region,
      photoIds: photoIds ?? this.photoIds,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
      conditions: conditions ?? this.conditions,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        location,
        maxDepth,
        country,
        region,
        photoIds,
        rating,
        notes,
        conditions,
      ];
}

/// Geographic coordinates
class GeoPoint extends Equatable {
  final double latitude;
  final double longitude;

  const GeoPoint(this.latitude, this.longitude);

  @override
  List<Object?> get props => [latitude, longitude];

  @override
  String toString() => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// Typical conditions at a dive site
class SiteConditions extends Equatable {
  final String? waterType; // salt, fresh, brackish
  final String? typicalVisibility;
  final String? typicalCurrent;
  final String? bestSeason;
  final double? minTemp; // celsius
  final double? maxTemp; // celsius
  final String? entryType; // shore, boat

  const SiteConditions({
    this.waterType,
    this.typicalVisibility,
    this.typicalCurrent,
    this.bestSeason,
    this.minTemp,
    this.maxTemp,
    this.entryType,
  });

  @override
  List<Object?> get props => [
        waterType,
        typicalVisibility,
        typicalCurrent,
        bestSeason,
        minTemp,
        maxTemp,
        entryType,
      ];
}
