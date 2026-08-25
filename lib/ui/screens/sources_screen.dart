import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/sources/plex/plex_api_client.dart';
import '../../data/sources/plex/plex_auth.dart';
import '../../data/sources/plex/plex_library.dart';
import '../../data/sources/sources_access.dart';
import '../state/sources_provider.dart';
import '../theme/sayaw_theme.dart';
import '../touch/touch_targets.dart';

/// Connected music services.
///
/// Sign-in happens here and nowhere else, which is why this is a screen rather
/// than a dialog buried in the deck: it is the one place an operator goes when
/// a server has stopped answering an hour before doors.
class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(sourcesProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: SayawColors.surfaceContainer,
        title: const Text('Music sources'),
      ),
      body: SafeArea(
        child: sources == null
            ? const _Unavailable()
            : _Accounts(sources: sources),
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Sources open with the app.',
            style: TextStyle(color: SayawColors.onSurfaceVariant),
          ),
        ),
      );
}

class _Accounts extends StatelessWidget {
  const _Accounts({required this.sources});

  final SourcesAccess sources;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SourceAccount>>(
      stream: sources.watchAccounts(),
      builder: (context, snapshot) {
        final accounts = snapshot.data ?? const <SourceAccount>[];

        return ListView(
          children: [
            if (accounts.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 8),
                child: Text(
                  'Nothing connected yet. Local files work without any of '
                  'this — a server is for the rest of your library.',
                  style: TextStyle(color: SayawColors.onSurfaceVariant),
                ),
              ),
            for (final account in accounts)
              _AccountRow(account: account, sources: sources),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FilledButton.icon(
                onPressed: () => _connectPlex(context, sources),
                icon: const Icon(Icons.add_link),
                label: const Text('Connect a Plex server'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _connectPlex(BuildContext context, SourcesAccess sources) =>
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PlexSignInDialog(sources: sources),
      );
}

/// One connected server, with what can be done to it.
class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account, required this.sources});

  final SourceAccount account;
  final SourcesAccess sources;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.dns_outlined),
      title: Text(account.displayName),
      subtitle: Text(account.isOwned ? 'Your server' : 'Shared with you'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconAction(
            icon: Icons.library_add_outlined,
            label: 'Import music from ${account.displayName}',
            onPressed: () => _import(context),
          ),
          _IconAction(
            icon: Icons.link_off,
            label: 'Disconnect ${account.displayName}',
            onPressed: () => sources.disconnect(account.id),
          ),
        ],
      ),
    );
  }

  Future<void> _import(BuildContext context) => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => PlexImportDialog(sources: sources, account: account),
      );
}

/// Picking a music library and copying it into the local mirror.
///
/// Modal and not dismissible while it runs: an import interrupted halfway
/// leaves a library that is half there, and the operator has no way to tell
/// which half.
class PlexImportDialog extends StatefulWidget {
  const PlexImportDialog({
    super.key,
    required this.sources,
    required this.account,
  });

  final SourcesAccess sources;
  final SourceAccount account;

  @override
  State<PlexImportDialog> createState() => _PlexImportDialogState();
}

class _PlexImportDialogState extends State<PlexImportDialog> {
  List<PlexSection>? _sections;
  String? _error;
  String? _done;
  int _imported = 0;
  int _total = 0;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _error = null;
      _sections = null;
    });

    try {
      final sections = await widget.sources.musicSections(widget.account.id);
      if (!mounted) return;

      // One music library is the common case, and offering a list of one is a
      // step for nothing.
      if (sections.length == 1) {
        await _import(sections.single);
        return;
      }
      setState(() => _sections = sections);
    } on Object catch (e) {
      _fail(e);
    }
  }

  Future<void> _import(PlexSection section) async {
    setState(() {
      _running = true;
      _sections = null;
      _imported = 0;
      _total = 0;
    });

    try {
      final report = await widget.sources.importSection(
        widget.account.id,
        section.key,
        onProgress: (imported, total) {
          if (!mounted) return;
          setState(() {
            _imported = imported;
            _total = total;
          });
        },
      );
      if (!mounted) return;

      setState(() {
        _running = false;
        _done = '${report.added} added, ${report.updated} updated, '
            '${report.unchanged} already there.';
      });
    } on Object catch (e) {
      _fail(e);
    }
  }

  void _fail(Object error) {
    if (!mounted) return;
    setState(() {
      _running = false;
      _error = '$error';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: Text('Import from ${widget.account.displayName}'),
      content: SizedBox(width: 360, child: _content()),
      actions: [
        TextButton(
          onPressed: _running ? null : () => Navigator.of(context).pop(),
          child: Text(_done == null ? 'Cancel' : 'Done'),
        ),
      ],
    );
  }

  Widget _content() {
    if (_error case final error?) {
      return Text(error, style: const TextStyle(color: SayawColors.error));
    }

    if (_done case final done?) return Text(done);

    if (_sections case final sections?) {
      if (sections.isEmpty) {
        return const Text('This server has no music libraries on it.');
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Which library?'),
          const SizedBox(height: 8),
          for (final section in sections)
            ListTile(
              leading: const Icon(Icons.library_music_outlined),
              title: Text(section.title),
              onTap: () => _import(section),
            ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _total == 0 ? null : _imported / _total,
        ),
        const SizedBox(height: 12),
        Text(
          _total == 0 ? 'Reading the library…' : '$_imported of $_total',
          style: const TextStyle(color: SayawColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// The PIN flow, start to finish.
///
/// The code stays on screen the whole time it is being polled for: an operator
/// who mistypes it needs to be able to look again, and one who wandered off
/// needs to see that nothing has happened yet.
class PlexSignInDialog extends StatefulWidget {
  const PlexSignInDialog({
    super.key,
    required this.sources,
    this.pollInterval = const Duration(seconds: 2),
  });

  final SourcesAccess sources;
  final Duration pollInterval;

  @override
  State<PlexSignInDialog> createState() => _PlexSignInDialogState();
}

class _PlexSignInDialogState extends State<PlexSignInDialog> {
  PlexPin? _pin;
  List<PlexServer>? _servers;
  String? _error;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
      _servers = null;
    });

    try {
      final pin = await widget.sources.requestPlexPin();
      if (!mounted) return;
      setState(() {
        _pin = pin;
        _busy = false;
      });
      _poll = Timer.periodic(widget.pollInterval, (_) => _check());
    } on Object catch (e) {
      _fail(e);
    }
  }

  Future<void> _check() async {
    final pin = _pin;
    if (pin == null || _busy) return;

    try {
      final token = await widget.sources.checkPlexPin(pin.id);
      if (token == null || !mounted) return;

      _poll?.cancel();
      setState(() => _busy = true);

      final servers = await widget.sources.plexServers(token);
      if (!mounted) return;

      // One server is the common case, and making someone pick from a list of
      // one is a step for nothing.
      if (servers.length == 1) {
        await _connect(servers.single);
        return;
      }

      setState(() {
        _servers = servers;
        _busy = false;
      });
    } on Object catch (e) {
      _poll?.cancel();
      _fail(e);
    }
  }

  Future<void> _connect(PlexServer server) async {
    setState(() => _busy = true);
    try {
      await widget.sources.connectPlexServer(server);
      if (mounted) Navigator.of(context).pop();
    } on Object catch (e) {
      _fail(e);
    }
  }

  void _fail(Object error) {
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error is PlexAuthException ? error.message : '$error';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: SayawColors.surfaceContainer,
      title: const Text('Connect Plex'),
      content: SizedBox(width: 360, child: _content()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (_error != null)
          TextButton(onPressed: _busy ? null : _start, child: const Text('Try again')),
      ],
    );
  }

  Widget _content() {
    if (_error case final error?) {
      return Text(error, style: const TextStyle(color: SayawColors.error));
    }

    if (_servers case final servers?) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Which server?'),
          const SizedBox(height: 8),
          for (final server in servers)
            ListTile(
              leading: const Icon(Icons.dns_outlined),
              title: Text(server.name),
              subtitle: Text(server.owned ? 'Your server' : 'Shared with you'),
              onTap: _busy ? null : () => _connect(server),
            ),
        ],
      );
    }

    final pin = _pin;
    if (pin == null || _busy) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Go to plex.tv/link and enter this code:'),
        const SizedBox(height: 16),
        Row(
          children: [
            SelectableText(
              pin.code,
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
              ),
            ),
            const Spacer(),
            _CopyCodeButton(code: pin.code),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Waiting for approval. It can be done on a phone.',
          style: TextStyle(color: SayawColors.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _CopyCodeButton extends StatelessWidget {
  const _CopyCodeButton({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Copy the code',
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () => Clipboard.setData(ClipboardData(text: code)),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;

  /// Names the server as well as the action: a screen reader reads the whole
  /// row as one node, and "Disconnect" alone is ambiguous in a list of them.
  final String label;

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: kMinTouchTarget,
        height: kMinTouchTarget,
        child: IconButton(icon: Icon(icon), onPressed: onPressed),
      ),
    );
  }
}
