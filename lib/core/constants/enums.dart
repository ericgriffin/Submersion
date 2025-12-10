/// Types of dives
enum DiveType {
  recreational('Recreational'),
  technical('Technical'),
  freedive('Freedive'),
  training('Training'),
  wreck('Wreck'),
  cave('Cave'),
  ice('Ice'),
  night('Night'),
  drift('Drift'),
  deep('Deep'),
  altitude('Altitude'),
  shore('Shore'),
  boat('Boat'),
  liveaboard('Liveaboard');

  final String displayName;
  const DiveType(this.displayName);
}

/// Types of diving equipment
enum EquipmentType {
  regulator('Regulator'),
  bcd('BCD'),
  wetsuit('Wetsuit'),
  drysuit('Drysuit'),
  fins('Fins'),
  mask('Mask'),
  computer('Dive Computer'),
  tank('Tank'),
  weights('Weights'),
  light('Light'),
  camera('Camera'),
  smb('SMB'),
  reel('Reel'),
  knife('Knife'),
  hood('Hood'),
  gloves('Gloves'),
  boots('Boots'),
  other('Other');

  final String displayName;
  const EquipmentType(this.displayName);
}

/// Visibility conditions
enum Visibility {
  excellent('Excellent (>30m / >100ft)'),
  good('Good (15-30m / 50-100ft)'),
  moderate('Moderate (5-15m / 15-50ft)'),
  poor('Poor (<5m / <15ft)'),
  unknown('Unknown');

  final String displayName;
  const Visibility(this.displayName);
}

/// Current strength
enum CurrentStrength {
  none('None'),
  light('Light'),
  moderate('Moderate'),
  strong('Strong');

  final String displayName;
  const CurrentStrength(this.displayName);
}

/// Water type
enum WaterType {
  salt('Salt Water'),
  fresh('Fresh Water'),
  brackish('Brackish');

  final String displayName;
  const WaterType(this.displayName);
}

/// Marine life categories
enum SpeciesCategory {
  fish('Fish'),
  shark('Shark'),
  ray('Ray'),
  mammal('Mammal'),
  turtle('Turtle'),
  invertebrate('Invertebrate'),
  coral('Coral'),
  plant('Plant/Algae'),
  other('Other');

  final String displayName;
  const SpeciesCategory(this.displayName);
}