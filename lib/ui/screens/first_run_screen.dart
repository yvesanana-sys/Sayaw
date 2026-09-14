import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/first_run.dart';
import '../state/playback_ui_state.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';
import 'sources_screen.dart';

/// The first thing a new operator sees, and the screen that decides whether
/// they get to a second one.
///
/// What used to greet them was four empty panes — no decks loaded, an empty
/// set, an empty library and a "search your library" hint over a library with
/// nothing in it. Four dead ends, in no order, none of them saying which to do
/// first. Someone who has run a night before can work it out. The dance teacher
/// who installed this an hour before doors closes it.
///
/// So: one ordered path with exactly one thing to press. The later steps are
/// visible but plainly not yet, because the shape of the evening is worth
/// learning before anything is asked of you.
class FirstRunScreen extends ConsumerStatefulWidget {
  const FirstRunScreen({super.key});

  @override
  ConsumerState<FirstRunScreen> createState() => _FirstRunScreenState();
}

class _FirstRunScreenState extends ConsumerState<FirstRunScreen> {
  bool _scanning = false;

  /// Only the desktop platforms can open a folder picker; on a tablet the
  /// music arrives through a source instead.
  bool get _canChooseFolder =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<void> _chooseFolder() async {
    final library = ref.read(libraryAccessProvider);
    if (library == null) return;

    final path = await getDirectoryPath();
    if (path == null || !mounted) return;

    setState(() => _scanning = true);
    try {
      final report = await library.scanFolders([Directory(path)]);
      if (!mounted) return;

      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text('${report.added} songs added.')),
      );
      // The count is what decides this screen is finished with. Asking again
      // is what takes the operator through to the app.
      ref.invalidate(libraryCountProvider);
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SayawColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Heading(),
                  const SizedBox(height: 28),
                  _Step(
                    number: 1,
                    title: 'Point Sayaw at your music',
                    detail: 'A folder on this machine or a drive. '
                        'Nothing is copied or uploaded.',
                    // The one enabled thing on the screen.
                    action: _scanning ? 'Reading your music…' : 'Choose a folder',
                    onPressed:
                        _canChooseFolder && !_scanning ? _chooseFolder : null,
                    state: _StepState.now,
                  ),
                  const SizedBox(height: 12),
                  const _Step(
                    number: 2,
                    title: "Build tonight's set list",
                    detail: 'Or let Sayaw shape one: five songs per dance, '
                        'in the order you pick.',
                    action: 'After step 1',
                    onPressed: null,
                    state: _StepState.later,
                  ),
                  const SizedBox(height: 12),
                  const _Step(
                    number: 3,
                    title: 'Decide what the room hears between dances',
                    detail: 'A spoken “Next dance: Bachata”, your own '
                        'recording, or nothing at all.',
                    action: 'Optional',
                    onPressed: null,
                    state: _StepState.optional,
                  ),
                  const SizedBox(height: 28),
                  const Divider(height: 1, color: SayawColors.outlineVariant),
                  const SizedBox(height: 20),
                  const _PlexFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Sayaw',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: SayawColors.onSurface,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'first time here',
              style: TextStyle(
                fontSize: 13,
                color: SayawColors.onSurfaceVariant.withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        const Text(
          "Let's get tonight ready.",
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            color: SayawColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Three steps, about five minutes. You can run a whole night '
          'with just the first two.',
          style: TextStyle(
            fontSize: 16,
            height: 1.4,
            color: SayawColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

enum _StepState { now, later, optional }

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.detail,
    required this.action,
    required this.onPressed,
    required this.state,
  });

  final int number;
  final String title;
  final String detail;
  final String action;
  final VoidCallback? onPressed;
  final _StepState state;

  bool get _isNow => state == _StepState.now;

  @override
  Widget build(BuildContext context) {
    final accent = _isNow ? SayawColors.primary : SayawColors.onSurfaceVariant;

    return Semantics(
      container: true,
      label: _isNow
          ? 'Step $number, do this now. $title. $detail'
          : 'Step $number, ${state == _StepState.optional ? 'optional' : 'not yet'}. '
              '$title. $detail',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _isNow
                ? SayawColors.surfaceContainer
                : SayawColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isNow ? SayawColors.primary : SayawColors.outlineVariant,
              width: _isNow ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _isNow
                      ? SayawColors.primary
                      : SayawColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _isNow
                        ? SayawColors.onPrimary
                        : SayawColors.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: _isNow
                            ? SayawColors.onSurface
                            : SayawColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: SayawColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Disabled steps still carry a full-size, fully labelled button.
              // "After step 1" is the answer to "why can't I press this", and
              // a greyed shape with no words is not.
              _StepButton(
                label: action,
                onPressed: onPressed,
                filled: _isNow,
                accent: accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.onPressed,
    required this.filled,
    required this.accent,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: label,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTouchTarget),
        child: Material(
          color: filled
              ? SayawColors.primary
              : SayawColors.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kMinTouchTarget / 2),
            side: BorderSide(
              color: filled ? Colors.transparent : SayawColors.outline,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: filled
                        ? SayawColors.onPrimary
                        : SayawColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Plex, demoted to a footer.
///
/// It was an unlabelled server-rack icon in the app bar, which is an odd first
/// thing to meet. The reassurance is the point: local files need none of this.
class _PlexFooter extends StatelessWidget {
  const _PlexFooter();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your music lives on a Plex server?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: SayawColors.onSurface,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Local files work without any of this — a server is for the '
                'rest of your library.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: SayawColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Builder(
          builder: (context) => _StepButton(
            label: 'Connect a Plex server',
            filled: false,
            accent: SayawColors.onSurfaceVariant,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SourcesScreen()),
            ),
          ),
        ),
      ],
    );
  }
}
