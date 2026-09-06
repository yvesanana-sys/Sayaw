import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/audio/soundboard.dart';
import 'package:sayaw/ui/layout/breakpoints.dart';
import 'package:sayaw/ui/screens/cue_tag_dialog.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/state/soundboard_provider.dart';
import 'package:sayaw/ui/touch/touch_targets.dart';
import 'package:sayaw/ui/widgets/queue_list.dart';

import '../fakes/fake_cue_tag.dart';
import '../fakes/fake_soundboard.dart';
import 'harness.dart';

const _partners = SoundCue(
  id: 'partners',
  label: 'Take your partners',
  filePath: '/clips/partners.wav',
  duckLevel: 0.3,
);
const _whistle =
    SoundCue(id: 'whistle', label: 'Whistle', filePath: '/fx/w.wav');

/// Two rows: one plain, one already tagged.
List<QueueItemUi> _queue() => const [
      QueueItemUi(
        id: 'q1',
        title: 'Kiss of Fire',
        artist: 'Georgia Gibbs',
        danceType: 'Tango',
        position: 1.0,
      ),
      QueueItemUi(
        id: 'q2',
        title: 'Sway',
        artist: 'Dean Martin',
        danceType: 'Cha-Cha',
        position: 2.0,
        soundCueId: 'partners',
        soundCueLabel: 'Take your partners',
      ),
    ];

Finder _buttonFor(String id) => find.descendant(
      of: find.byKey(ValueKey(id)),
      matching: find.byType(QueueCueButton),
    );

void main() {
  Future<FakeCueTag> pumpQueue(
    WidgetTester tester, {
    required List<SoundCue> cues,
    List<QueueItemUi>? queue,
    Size size = kExpandedSize,
  }) async {
    final soundboard = FakeSoundboard(cues);
    addTearDown(soundboard.close);
    final access = FakeCueTag();

    await pumpSayaw(
      tester,
      Scaffold(
        body: SayawLayout(builder: (context, _) => const QueueList()),
      ),
      size: size,
      queue: queue ?? _queue(),
      overrides: [
        soundboardProvider.overrideWithValue(soundboard),
        cueTagProvider.overrideWithValue(access),
      ],
    );
    await tester.pumpAndSettle();
    return access;
  }

  testWidgets('no sounds loaded, nothing to tag with', (tester) async {
    // A new install: the soundboard is empty, so the control that points a row
    // at one of its sounds is not drawn at all.
    await pumpQueue(tester, cues: const []);

    expect(find.byType(QueueCueButton), findsNothing);
  });

  testWidgets('one sound loaded puts the control on every row',
      (tester) async {
    await pumpQueue(tester, cues: const [_whistle]);

    expect(find.byType(QueueCueButton), findsNWidgets(2));
  });

  testWidgets('a tagged row says what announces it, at every width',
      (tester) async {
    for (final size in [kCompactSize, kMediumSize, kExpandedSize]) {
      await pumpQueue(tester, cues: const [_partners], size: size);

      // Not behind a hover, not only in the semantics tree: a tag is something
      // the operator set by hand, and an invisible one gets set twice.
      expect(find.text('Take your partners'), findsOneWidget);
    }
  });

  testWidgets('picking a sound tags that row', (tester) async {
    final access = await pumpQueue(tester, cues: const [_partners, _whistle]);

    await tester.tap(_buttonFor('q1'));
    await tester.pumpAndSettle();
    expect(find.byType(CueTagDialog), findsOneWidget);

    await tester.tap(find.text('Whistle'));
    await tester.pumpAndSettle();

    expect(access.tagged, [('q1', 'whistle')]);
    expect(find.byType(CueTagDialog), findsNothing);
  });

  testWidgets('choosing nothing clears the tag', (tester) async {
    final access = await pumpQueue(tester, cues: const [_partners]);

    await tester.tap(_buttonFor('q2'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nothing'));
    await tester.pumpAndSettle();

    expect(access.tagged, [('q2', null)]);
  });

  testWidgets('the picker opens on what the row already has', (tester) async {
    await pumpQueue(tester, cues: const [_partners, _whistle]);

    await tester.tap(_buttonFor('q2'));
    await tester.pumpAndSettle();

    // The tagged cue is the selected one, and it says so without a pointer.
    final selected = tester.widgetList<Semantics>(find.byType(Semantics)).where(
        (s) => s.properties.label == 'Take your partners, selected');
    expect(selected, isNotEmpty);
  });

  testWidgets('the control is a full touch target', (tester) async {
    await pumpQueue(tester, cues: const [_whistle]);

    for (final element in find.byType(QueueCueButton).evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget));
      expect(size.width, greaterThanOrEqualTo(kMinTouchTarget));
      expect(size.height, greaterThanOrEqualTo(kMinTouchTarget));
    }
  });
}
