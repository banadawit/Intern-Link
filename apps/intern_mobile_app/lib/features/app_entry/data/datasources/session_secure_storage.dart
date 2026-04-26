import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/constants/storage_keys.dart';

class SessionSecureStorage {
  SessionSecureStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  Future<String?> readAuthToken() {
    return _secureStorage.read(key: StorageKeys.authToken);
  }

  Future<void> clearSession() {
    return _secureStorage.delete(key: StorageKeys.authToken);
  }
}
