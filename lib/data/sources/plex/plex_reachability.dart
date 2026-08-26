import '../../connectivity.dart';
import '../../db/database.dart';
import 'plex_api_client.dart';

/// Whether each connected Plex server is answering.
///
/// One name per server rather than a single "Plex is down": a DJ with a home
/// server and a friend's shared library needs to know which of the two went
/// away, because only one of them has tonight's music on it.
class PlexReachability implements ServiceProbe {
  PlexReachability({required this.accounts, required this.plex});

  final SourceAccountDao accounts;
  final PlexApiClient plex;

  @override
  Future<List<ServiceReachability>> probe() async {
    final rows = await accounts.all(provider: SourceProvider.plex);
    if (rows.isEmpty) return const [];

    final answered = await Future.wait([
      for (final row in rows) plex.isReachable(row.id),
    ]);

    return [
      for (var i = 0; i < rows.length; i++)
        ServiceReachability(name: rows[i].displayName, reachable: answered[i]),
    ];
  }
}
