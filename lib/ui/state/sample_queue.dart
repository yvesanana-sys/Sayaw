import 'playback_ui_state.dart';

/// Placeholder set list.
///
/// The shell needs something to draw until Phase 4 wires the real library, the
/// Drift queries and the source resolvers. Nothing else imports this, and it is
/// seeded from `main()` in one clearly marked place so deleting it later is a
/// one-line change rather than an archaeology exercise.
List<QueueItemUi> sampleQueue() => const [
      QueueItemUi(
        id: 'demo-1',
        title: 'Kiss of Fire',
        artist: 'Georgia Gibbs',
        danceType: 'Tango',
        position: 1.0,
        duration: Duration(minutes: 2, seconds: 58),
      ),
      QueueItemUi(
        id: 'demo-2',
        title: 'Sway',
        artist: 'Dean Martin',
        danceType: 'Cha-Cha',
        position: 2.0,
        duration: Duration(minutes: 2, seconds: 42),
      ),
      QueueItemUi(
        id: 'demo-3',
        title: 'Obsesión',
        artist: 'Aventura',
        danceType: 'Bachata',
        position: 3.0,
        duration: Duration(minutes: 4, seconds: 8),
      ),
      QueueItemUi(
        id: 'demo-4',
        title: 'The Blue Danube',
        artist: 'Johann Strauss II',
        danceType: 'Viennese Waltz',
        position: 4.0,
        duration: Duration(minutes: 9, seconds: 12),
      ),
      QueueItemUi(
        id: 'demo-5',
        title: 'Smooth',
        artist: 'Santana ft. Rob Thomas',
        danceType: 'Rumba',
        position: 5.0,
        duration: Duration(minutes: 4, seconds: 56),
        unavailable: UnavailableReason.drmUnsupportedOnPlatform,
      ),
    ];
