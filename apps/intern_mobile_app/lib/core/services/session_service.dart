import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

class AppSessionService {
  AppSessionService({
    SharedPreferences? sharedPreferences,
    FlutterSecureStorage? secureStorage,
  }) : _sharedPreferences = sharedPreferences,
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final SharedPreferences? _sharedPreferences;
  final FlutterSecureStorage _secureStorage;

  Future<SharedPreferences> get _prefs async {
    if (_sharedPreferences != null) {
      return _sharedPreferences;
    }
    return SharedPreferences.getInstance();
  }

  Future<bool> isFirstLaunch() async {
    try {
      final prefs = await _prefs;
      final firstLaunchCompleted =
          prefs.getBool(StorageKeys.firstLaunchCompleted) ?? false;
      return !firstLaunchCompleted;
    } catch (error, stackTrace) {
      throw AppSessionException(
        operation: 'isFirstLaunch',
        message: 'Failed to read first launch state.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> setFirstLaunchCompleted() async {
    try {
      final prefs = await _prefs;
      await prefs.setBool(StorageKeys.firstLaunchCompleted, true);
    } catch (error, stackTrace) {
      throw AppSessionException(
        operation: 'setFirstLaunchCompleted',
        message: 'Failed to persist first launch state.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> getToken() async {
    try {
      final token = await _secureStorage.read(key: StorageKeys.authToken);
      final sanitized = token?.trim();
      if (sanitized == null || sanitized.isEmpty) {
        return null;
      }
      return sanitized;
    } catch (error, stackTrace) {
      throw AppSessionException(
        operation: 'getToken',
        message: 'Failed to read auth token.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> saveToken(String token) async {
    final sanitized = token.trim();
    if (sanitized.isEmpty) {
      throw const AppSessionException(
        operation: 'saveToken',
        message: 'Token cannot be empty.',
      );
    }

    try {
      await _secureStorage.write(key: StorageKeys.authToken, value: sanitized);
    } catch (error, stackTrace) {
      throw AppSessionException(
        operation: 'saveToken',
        message: 'Failed to save auth token.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> clearSession() async {
    try {
      await _secureStorage.delete(key: StorageKeys.authToken);
    } catch (error, stackTrace) {
      throw AppSessionException(
        operation: 'clearSession',
        message: 'Failed to clear session.',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }
}

class AppSessionException implements Exception {
  const AppSessionException({
    required this.operation,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final String operation;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    return 'AppSessionException(operation: $operation, message: $message, cause: $cause)';
  }
}
