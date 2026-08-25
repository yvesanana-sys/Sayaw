import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One request the code under test made.
class RecordedRequest {
  RecordedRequest(this.method, this.uri, this.headers);

  final String method;
  final Uri uri;
  final Map<String, dynamic> headers;

  String? header(String name) => headers[name]?.toString();

  @override
  String toString() => '$method ${uri.host}${uri.path}';
}

/// How the fake server answers one route.
class FakeResponse {
  FakeResponse(this.body, {this.status = 200, this.delay = Duration.zero});

  /// Never answers. For a connection that hangs rather than refusing, which is
  /// the failure the connection race exists to survive.
  FakeResponse.hangs()
      : body = null,
        status = 200,
        delay = const Duration(days: 1);

  /// Refuses at the socket level.
  FakeResponse.refused()
      : body = _refused,
        status = 0,
        delay = Duration.zero;

  final Object? body;
  final int status;
  final Duration delay;

  static const _refused = Object();
}

/// A Dio adapter that answers from a routing table instead of a network.
///
/// Routes are matched on `METHOD host/path`, so a test says what plex.tv and
/// each of a server's four addresses reply with, and nothing opens a socket.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter([Map<String, FakeResponse>? routes]) : routes = {...?routes};

  final Map<String, FakeResponse> routes;
  final List<RecordedRequest> requests = [];

  /// Routes hit, in order, for asserting that a cached connection meant one
  /// request rather than five.
  List<String> get calls => [for (final r in requests) r.toString()];

  void on(String route, FakeResponse response) => routes[route] = response;

  int callsTo(String route) => calls.where((c) => c == route).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    final key = '${options.method} ${uri.host}${uri.path}';
    requests.add(RecordedRequest(options.method, uri, options.headers));

    final response = routes[key];
    if (response == null) {
      return ResponseBody.fromString('{"error":"no route for $key"}', 404,
          headers: _jsonHeaders);
    }

    if (response.delay > Duration.zero) {
      final timeout = options.receiveTimeout;
      if (timeout == null || response.delay > timeout) {
        // Let the caller's own timeout be what fails, the way a real hanging
        // connection does.
        await Future<void>.delayed(timeout ?? response.delay);
        throw DioException.receiveTimeout(
            timeout: timeout ?? response.delay, requestOptions: options);
      }
      await Future<void>.delayed(response.delay);
    }

    if (identical(response.body, FakeResponse._refused)) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Connection refused',
      );
    }

    return ResponseBody.fromString(
      jsonEncode(response.body),
      response.status,
      headers: _jsonHeaders,
    );
  }

  @override
  void close({bool force = false}) {}

  static final _jsonHeaders = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };
}

/// A Dio wired to [adapter] and nothing else.
Dio fakeDio(FakeHttpAdapter adapter) => Dio()..httpClientAdapter = adapter;
