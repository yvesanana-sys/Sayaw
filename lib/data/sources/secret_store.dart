import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where tokens live: the OS keychain, never the database.
///
/// `source_accounts` holds a `keychain_ref` and nothing else, so a copy of the
/// SQLite file — a backup, a support bundle, a synced folder — carries no
/// credentials with it.
abstract class SecretStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain on Apple platforms, Keystore on Android, DPAPI on Windows.
class SecureSecretStore implements SecretStore {
  const SecureSecretStore([this.storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage storage;

  @override
  Future<String?> read(String key) => storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => storage.delete(key: key);
}
