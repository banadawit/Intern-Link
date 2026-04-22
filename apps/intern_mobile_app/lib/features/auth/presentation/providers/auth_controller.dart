import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/services/session_service.dart';
import '../../../../features/app_entry/domain/entities/app_role.dart';
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
    this.errorCode,
    this.requiresVerification = false,
    this.emailForVerification,
    this.loggedInRoute,
  });

  final AuthMode mode;
  final bool isLoading;
  final String? errorMessage;
  final String? infoMessage;
  final String? errorCode;
  final bool requiresVerification;
  final String? emailForVerification;
  /// Non-null after a successful login — the route to navigate to.
  final String? loggedInRoute;

  AuthUiState copyWith({
    AuthMode? mode,
    bool? isLoading,
    String? errorMessage,
    String? infoMessage,
    String? errorCode,
    bool? requiresVerification,
    String? emailForVerification,
    String? loggedInRoute,
    bool clearError = false,
    bool clearInfo = false,
    bool clearAuthMeta = false,
  }) {
    return AuthUiState(
      mode: mode ?? this.mode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
      errorCode: clearAuthMeta ? null : (errorCode ?? this.errorCode),
      requiresVerification: clearAuthMeta
          ? false
          : (requiresVerification ?? this.requiresVerification),
      emailForVerification: clearAuthMeta
          ? null
          : (emailForVerification ?? this.emailForVerification),
      loggedInRoute: loggedInRoute ?? this.loggedInRoute,
    );
  }
}

final authDioProvider = Provider<Dio>((ref) {
  final fromEnv = const String.fromEnvironment('API_BASE_URL').trim();
  final defaultUrl = kIsWeb ? 'http://localhost:5000' : 'http://10.0.2.2:5000';
  final raw = fromEnv.isEmpty ? defaultUrl : fromEnv;
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
    state = state.copyWith(
      mode: mode,
      clearError: true,
      clearInfo: true,
      clearAuthMeta: true,
    );
  }

  void clearMessages() {
    state = state.copyWith(
      clearError: true,
      clearInfo: true,
      clearAuthMeta: true,
    );
  }

  /// Returns the dashboard route to navigate to on success, or null on failure.
  Future<String?> login({required String email, required String password}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      clearAuthMeta: true,
    );

    try {
      final result = await ref
          .read(authRemoteServiceProvider)
          .login(email: email.trim(), password: password);

      final sessionService = ref.read(appSessionServiceProvider);
      await sessionService.saveToken(result.token);

      // Fetch the user role to determine the dashboard route.
      String dashboardRoute = AppRoutes.studentDashboard; // safe default
      try {
        final authDs = ref.read(authRemoteDataSourceProvider);
        final user = await authDs.fetchCurrentUser(result.token);
        await sessionService.saveRole(user.role.name.toUpperCase());
        dashboardRoute = _routeFromRole(user.role);
      } catch (_) {
        // If /auth/me fails, use cached role from previous login.
        final cached = await sessionService.getRole();
        if (cached != null) {
          final role = appRoleFromBackend(cached);
          if (role != null) dashboardRoute = _routeFromRole(role);
        }
      }

      ref.invalidate(appStartDecisionProvider);
      state = state.copyWith(
        isLoading: false,
        loggedInRoute: dashboardRoute,
      );
      return dashboardRoute;
    } on AuthApiException catch (error) {
      final fallback = error.statusCode == 401
          ? 'Invalid email or password. Please try again.'
          : error.message;
      state = state.copyWith(
        isLoading: false,
        errorMessage: fallback,
        errorCode: error.code,
        requiresVerification: error.requiresVerification,
        emailForVerification: error.email,
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error occurred. Please try again.',
        clearAuthMeta: true,
      );
      return null;
    }
  }

  String _routeFromRole(AppRole role) {
    switch (role) {
      case AppRole.student:
        return AppRoutes.studentDashboard;
      case AppRole.supervisor:
        return AppRoutes.supervisorDashboard;
      case AppRole.coordinator:
        return AppRoutes.coordinatorDashboard;
      case AppRole.admin:
        return AppRoutes.adminDashboard;
      case AppRole.hod:
        return AppRoutes.hodDashboard;
    }
  }

  Future<bool> register(RegisterPayload payload) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      clearAuthMeta: true,
    );

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
        clearAuthMeta: true,
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      clearAuthMeta: true,
    );

    try {
      await ref.read(authRemoteServiceProvider).forgotPassword(email.trim());
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Password reset link sent. Check your email inbox.',
      );
      return true;
    } on AuthApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      clearAuthMeta: true,
    );

    try {
      await ref.read(authRemoteServiceProvider).verifyEmail(token.trim());
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Email verified successfully. You can now login.',
      );
      return true;
    } on AuthApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> resendVerification(String email) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      clearAuthMeta: true,
    );

    try {
      await ref
          .read(authRemoteServiceProvider)
          .resendVerification(email.trim());
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Verification email resent successfully.',
      );
      return true;
    } on AuthApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearInfo: true,
      clearAuthMeta: true,
    );

    try {
      await ref
          .read(authRemoteServiceProvider)
          .resetPassword(token: token.trim(), newPassword: newPassword);
      state = state.copyWith(
        isLoading: false,
        infoMessage: 'Password reset successful. Please login.',
      );
      return true;
    } on AuthApiException catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.message,
        errorCode: error.code,
      );
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
