import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/data/dance_type_seed.dart';
import 'package:sayaw/data/db/database.dart';

import 'db_harness.dart';

void main() {
  test('a fresh install gets the standard dances, in programme order', () async {
    final db = openTestDatabase();
    expect(await seedDanceTypes(db), kDefaultDanceTypes.length);

    final rows = await (db.select(db.danceTypes)
          ..orderBy([(d) => OrderingTerm.asc(d.sortIndex)]))
        .get();

    expect(rows.first.name, 'Waltz');
    expect([for (final row in rows) row.name], contains('Bachata'));
    expect(rows.map((r) => r.slug).toSet(), hasLength(rows.length));
  });

  test('every dance gets an announcement without anyone writing one', () async {
    final db = openTestDatabase();
    await seedDanceTypes(db);

    final waltz = await (db.select(db.danceTypes)
          ..where((d) => d.slug.equals('viennese-waltz')))
        .getSingle();

    expect(waltz.ttsTemplate, 'Next dance: {name}');
    expect(waltz.timeSignature, '3/4');
    expect(waltz.bpmMin, 174);
  });

  test('running it again adds nothing', () async {
    final db = openTestDatabase();
    await seedDanceTypes(db);

    expect(await seedDanceTypes(db), 0);
    expect(await db.select(db.danceTypes).get(),
        hasLength(kDefaultDanceTypes.length));
  });

  test('a renamed dance survives the next launch', () async {
    final db = openTestDatabase();
    await seedDanceTypes(db);

    await (db.update(db.danceTypes)..where((d) => d.slug.equals('waltz')))
        .write(const DanceTypesCompanion(
      name: Value('Slow Waltz'),
      ttsTemplate: Value('And now, the {name}'),
    ));

    await seedDanceTypes(db);

    final waltz = await (db.select(db.danceTypes)
          ..where((d) => d.slug.equals('waltz')))
        .getSingle();
    expect(waltz.name, 'Slow Waltz');
    expect(waltz.ttsTemplate, 'And now, the {name}');
  });

  test('a dance the operator deleted comes back, because the id is the slug',
      () async {
    // Worth knowing: removing a default is not currently permanent. Deleting
    // one you never use is a reasonable thing to try, and it will reappear.
    final db = openTestDatabase();
    await seedDanceTypes(db);
    await (db.delete(db.danceTypes)..where((d) => d.slug.equals('jive'))).go();

    expect(await seedDanceTypes(db), 1);
  });
}
