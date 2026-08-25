import 'package:drift/drift.dart';

import 'db/database.dart';

/// The dances a new install starts with.
///
/// Seeded rather than hardcoded: an operator renames them, adds their own,
/// changes the announcement wording and picks their own colours, and all of
/// that has to survive an update. Re-running this only fills in what is
/// missing, so a renamed Waltz stays renamed.
///
/// BPM ranges are the music's tempo in beats per minute, wide enough to be
/// useful for sorting a library and too wide to be worth arguing about.
Future<int> seedDanceTypes(SayawDatabase db) async {
  final existing = {
    for (final row in await db.select(db.danceTypes).get()) row.slug,
  };

  final missing = [
    for (var i = 0; i < kDefaultDanceTypes.length; i++)
      if (!existing.contains(kDefaultDanceTypes[i].slug))
        kDefaultDanceTypes[i].toCompanion(i),
  ];

  if (missing.isEmpty) return 0;
  await db.batch((b) => b.insertAll(db.danceTypes, missing));
  return missing.length;
}

class DanceTypeSeed {
  const DanceTypeSeed(
    this.name,
    this.slug, {
    this.bpmMin,
    this.bpmMax,
    this.timeSignature = '4/4',
    this.colorHex,
  });

  final String name;
  final String slug;
  final double? bpmMin;
  final double? bpmMax;
  final String timeSignature;
  final String? colorHex;

  DanceTypesCompanion toCompanion(int sortIndex) => DanceTypesCompanion.insert(
        // The slug is the id: stable across a rename, and readable in a
        // database someone is debugging at a venue.
        id: slug,
        name: name,
        slug: slug,
        bpmMin: Value(bpmMin),
        bpmMax: Value(bpmMax),
        timeSignature: Value(timeSignature),
        colorHex: Value(colorHex),
        sortIndex: Value(sortIndex),
      );
}

/// Ballroom first, then Latin, then the social dances — the order a
/// competition programme runs in, which is the order operators read.
const List<DanceTypeSeed> kDefaultDanceTypes = [
  // International Standard
  DanceTypeSeed('Waltz', 'waltz',
      bpmMin: 84, bpmMax: 90, timeSignature: '3/4', colorHex: '#7C6CF0'),
  DanceTypeSeed('Tango', 'tango',
      bpmMin: 120, bpmMax: 132, colorHex: '#D5405E'),
  DanceTypeSeed('Viennese Waltz', 'viennese-waltz',
      bpmMin: 174, bpmMax: 180, timeSignature: '3/4', colorHex: '#8E7BFF'),
  DanceTypeSeed('Foxtrot', 'foxtrot', bpmMin: 112, bpmMax: 120, colorHex: '#3F8FD6'),
  DanceTypeSeed('Quickstep', 'quickstep',
      bpmMin: 200, bpmMax: 208, colorHex: '#39B5A8'),

  // International Latin
  DanceTypeSeed('Cha-Cha', 'cha-cha', bpmMin: 120, bpmMax: 128, colorHex: '#F2A73B'),
  DanceTypeSeed('Samba', 'samba',
      bpmMin: 96, bpmMax: 104, timeSignature: '2/4', colorHex: '#4FBF62'),
  DanceTypeSeed('Rumba', 'rumba', bpmMin: 100, bpmMax: 108, colorHex: '#E0625E'),
  DanceTypeSeed('Paso Doble', 'paso-doble',
      bpmMin: 120, bpmMax: 124, timeSignature: '2/4', colorHex: '#C2452F'),
  DanceTypeSeed('Jive', 'jive', bpmMin: 168, bpmMax: 184, colorHex: '#F0C13B'),

  // Social
  DanceTypeSeed('Salsa', 'salsa', bpmMin: 150, bpmMax: 250, colorHex: '#FF7A45'),
  DanceTypeSeed('Bachata', 'bachata', bpmMin: 108, bpmMax: 152, colorHex: '#C46BD1'),
  DanceTypeSeed('Merengue', 'merengue',
      bpmMin: 120, bpmMax: 160, timeSignature: '2/4', colorHex: '#5FBF8F'),
  DanceTypeSeed('Argentine Tango', 'argentine-tango',
      bpmMin: 110, bpmMax: 130, colorHex: '#A83955'),
  DanceTypeSeed('Kizomba', 'kizomba', bpmMin: 80, bpmMax: 100, colorHex: '#6B7FD1'),
  DanceTypeSeed('West Coast Swing', 'west-coast-swing',
      bpmMin: 88, bpmMax: 120, colorHex: '#4DA3C7'),
  DanceTypeSeed('Lindy Hop', 'lindy-hop', bpmMin: 120, bpmMax: 180, colorHex: '#E8963C'),
];
