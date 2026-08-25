import 'package:sayaw/data/sources/secret_store.dart';

/// The keychain, in a map.
class FakeSecretStore implements SecretStore {
  final Map<String, String> secrets = {};

  /// Keys read, in order — enough to assert that a token was fetched from the
  /// keychain rather than kept somewhere it should not be.
  final List<String> reads = [];

  @override
  Future<String?> read(String key) async {
    reads.add(key);
    return secrets[key];
  }

  @override
  Future<void> write(String key, String value) async => secrets[key] = value;

  @override
  Future<void> delete(String key) async => secrets.remove(key);
}
