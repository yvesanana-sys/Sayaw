import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/sources/plex/plex_api_client.dart';
import '../../data/sources/plex/plex_auth.dart';
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
              ListTile(
                leading: const Icon(Icons.dns_outlined),
                title: Text(account.displayName),
                subtitle: Text(account.provider.name),
                trailing: _DisconnectButton(
                  label: 'Disconnect ${account.displayName}',
                  onPressed: () => sources.disconnect(account.id),
                ),
              ),
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

class _DisconnectButton extends StatelessWidget {
  const _DisconnectButton({required this.label, required this.onPressed});

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
        child: IconButton(
          icon: const Icon(Icons.link_off),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
