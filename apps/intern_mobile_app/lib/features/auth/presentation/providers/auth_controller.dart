import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/app_entry/presentation/providers/app_entry_providers.dart';
import '../../../app_entry/domain/entities/app_start_decision.dart';
import '../../data/datasources/auth_remote_service.dart';
import '../../data/models/auth_models.dart';

enum AuthMode { login, register }

class AuthUiState {
  const AuthUiState({
    this.mode = AuthMode.login,
    this.isLoading = false,
    this.errorMessage,
    this.infoMessage,
  });

  final AuthMode mode;
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;

  AuthUiState copyWith({
    AuthMode? mode,
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return AuthUiState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}

final authDioProvider = Provider<Dio>((ref) {
  final fromEnv = const String.fromEnvironment('API_BASE_URL').trim();
  final raw = fromEnv.isEmpty ? 'http://10.0.2.2:5000' : fromEnv;
  final normalized = raw.replaceAll(RegExp(r'/+$'), '');
  final baseUrl = normalized.endsWith('/api') ? normalized : '$normalized/api';

  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
});

final authRemoteServiceProvider = Provider<AuthRemoteService>(
  (ref) => AuthRemoteService(dio: ref.watch(authDioProvider)),
);

final authControllerProvider = NotifierProvider<AuthController, AuthUiState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthUiState> {
  @override
  AuthUiState build() => const AuthUiState();

  void setMode(AuthMode mode) {
    state = state.copyWith(mode: mode, clearError: true, clearInfo: true);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearInfo: true);
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);

    try {
      final result = await ref
          .read(authRemoteServiceProvider)
          .login(email: email.trim(), password: password);

      await ref.read(appSessionServiceProvider).saveToken(result.token);
      ref.invalidate(appStartDecisionProvider);

      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Login successful. Preparing your workspace...',
      );
      return true;
    } on AuthApiException catch (error) {
      final fallback = error.statusCode == 401
          ? 'Invalid email or password. Please try again.'
          : error.message;
      state = state.copyWith(isLoading: false, errorMessage: fallback);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> register(RegisterPayload payload) async {
    state = state.copyWith(isLoading: true, clearError: true, clearInfo: true);

    try {
      await ref.read(authRemoteServiceProvider).register(payload);
      state = state.copyWith(
        isLoading: false,
        infoMessage:
            'Registration submitted. Check your email for verification steps.',
      );
      return true;
    } on AuthApiException catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error occurred. Please try again.',
      );
      return false;
    }
  }
}
