import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sayaw/ui/state/playback_ui_state.dart';
import 'package:sayaw/ui/wakelock/playback_wakelock.dart';

import 'harness.dart';

/// A tablet dimming and sleeping mid-event is a show-stopper. Windows suspends
/// the display on its own idle timer regardless of audio output, because
/// nothing about our playback counts as user activity.
void main() {
  testWidgets('no lock is held while both decks are stopped', (tester) async {
    final wakelock = RecordingWakelockBackend();

    await pumpSayaw(
      tester,
      const PlaybackWakelock(child: SizedBox.shrink()),
      wakelock: wakelock,
    );

    expect(wakelock.isEnabled, isFalse);
  });

  testWidgets('the lock is taken when a deck starts', (tester) async {
    final wakelock = RecordingWakelockBackend();

    final container = await pumpSayaw(
      tester,
      const PlaybackWakelock(child: SizedBox.shrink()),
      queue: testQueue(),
      wakelock: wakelock,
    );

    final controller = container.read(playbackProvider.notifier);
    controller.loadToDeck(DeckSlot.a, testQueue().first);
    controller.togglePlay(DeckSlot.a);
    await tester.pumpAndSettle();

    expect(wakelock.isEnabled, isTrue);
  });

  testWidgets('the lock is released only when both decks stop', (tester) async {
    final wakelock = RecordingWakelockBackend();

    final container = await pumpSayaw(
      tester,
      const PlaybackWakelock(child: SizedBox.shrink()),
      queue: testQueue(),
      wakelock: wakelock,
    );

    final controller = container.read(playbackProvider.notifier);
    final items = testQueue();

    controller.loadToDeck(DeckSlot.a, items[0]);
    controller.loadToDeck(DeckSlot.b, items[1]);
    controller.togglePlay(DeckSlot.a);
    controller.togglePlay(DeckSlot.b);
    await tester.pumpAndSettle();
    expect(wakelock.isEnabled, isTrue);

    // Deck A stops mid-crossfade; deck B is still carrying the room.
    controller.togglePlay(DeckSlot.a);
    await tester.pumpAndSettle();
    expect(
      wakelock.isEnabled,
      isTrue,
      reason: 'the screen must stay awake while either deck is audible',
    );

    controller.togglePlay(DeckSlot.b);
    await tester.pumpAndSettle();
    expect(wakelock.isEnabled, isFalse);
  });

  testWidgets('redundant state changes do not re-issue platform calls',
      (tester) async {
    final wakelock = RecordingWakelockBackend();

    final container = await pumpSayaw(
      tester,
      const PlaybackWakelock(child: SizedBox.shrink()),
      queue: testQueue(),
      wakelock: wakelock,
    );

    final controller = container.read(playbackProvider.notifier);
    controller.loadToDeck(DeckSlot.a, testQueue().first);
    controller.togglePlay(DeckSlot.a);
    await tester.pumpAndSettle();

    // Position updates arrive at 50 Hz. Re-issuing a platform call on each one
    // would burn battery for nothing.
    for (var i = 0; i < 20; i++) {
      controller.setCrossfader(i / 20);
      await tester.pump();
    }

    expect(wakelock.calls, [true]);
  });

  testWidgets('the lock is released when the widget is disposed',
      (tester) async {
    final wakelock = RecordingWakelockBackend();

    final container = await pumpSayaw(
      tester,
      const PlaybackWakelock(child: SizedBox.shrink()),
      queue: testQueue(),
      wakelock: wakelock,
    );

    final controller = container.read(playbackProvider.notifier);
    controller.loadToDeck(DeckSlot.a, testQueue().first);
    controller.togglePlay(DeckSlot.a);
    await tester.pumpAndSettle();
    expect(wakelock.isEnabled, isTrue);

    // A hot restart in development otherwise leaves the lock held with nothing
    // left alive to release it.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();

    expect(wakelock.isEnabled, isFalse);
  });

  testWidgets('a wakelock that cannot be taken does not take the app down',
      (tester) async {
    // Found by running it: on Linux `wakelock_plus` goes over DBus, and a
    // machine with no session bus threw the moment playback started. `listen`
    // gives that nowhere to return an error to, so it was unhandled.
    final container = await pumpSayaw(
      tester,
      const PlaybackWakelock(child: SizedBox.shrink()),
      queue: testQueue(),
      wakelock: _ThrowingWakelock(),
    );

    final controller = container.read(playbackProvider.notifier);
    controller.loadToDeck(DeckSlot.a, testQueue().first);
    controller.togglePlay(DeckSlot.a);
    await tester.pumpAndSettle();

    // Nothing thrown, and the app is still standing.
    expect(tester.takeException(), isNull);
    expect(find.byType(PlaybackWakelock), findsOneWidget);
  });

}

/// A platform that cannot take a wakelock at all.
class _ThrowingWakelock implements WakelockBackend {
  @override
  Future<void> enable() async => throw const SocketException('no session bus');

  @override
  Future<void> disable() async => throw const SocketException('no session bus');
}
