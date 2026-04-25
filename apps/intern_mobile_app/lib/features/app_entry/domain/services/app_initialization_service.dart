import '../../../../core/services/session_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../entities/app_role.dart';
import '../entities/app_start_decision.dart';
import '../entities/app_start_destination.dart';

class AppInitializationService {
  AppInitializationService({
    required AppSessionService appSessionService,
    required AuthRemoteDataSource authRemoteDataSource,
  }) : _appSessionService = appSessionService,
       _authRemoteDataSource = authRemoteDataSource;

  final AppSessionService _appSessionService;
  final AuthRemoteDataSource _authRemoteDataSource;

  Future<AppStartDecision> resolveStartDestination() async {
    final isFirstLaunch = await _appSessionService.isFirstLaunch();
    if (isFirstLaunch) {
      return const AppStartDecision(destination: AppStartDestination.onboarding);
    }

    final authToken = await _appSessionService.getToken();
    if (authToken == null || authToken.isEmpty) {
      return const AppStartDecision(destination: AppStartDestination.auth);
    }

    try {
      final user = await _authRemoteDataSource.fetchCurrentUser(authToken);
      return AppStartDecision(destination: _destinationFromRole(user.role));
    } on SessionInvalidException {
      // Token was rejected by the server (HTTP 401) — it's genuinely expired.
      await _safeClearSession();
      return const AppStartDecision(destination: AppStartDestination.auth);
    } on SessionValidationException {
      // Network error / server unreachable / CORS issue during startup.
      // DO NOT clear the session — keep the token and send the user to their
      // dashboard anyway. The dashboard will show an appropriate error if the
      // API is still unreachable.
      final role = await _roleFromStoredSession();
      if (role != null) {
        return AppStartDecision(destination: _destinationFromRole(role));
      }
      // We have a token but no cached role — go to login so the user can
      // re-authenticate once the network is back.
      return const AppStartDecision(destination: AppStartDestination.auth);
    }
  }

  /// Reads the cached role from storage so we can route offline users
  /// to the correct dashboard without hitting the API.
  Future<AppRole?> _roleFromStoredSession() async {
    try {
      final roleStr = await _appSessionService.getRole();
      if (roleStr == null) return null;
      return _roleFromString(roleStr);
    } catch (_) {
      return null;
    }
  }

  Future<void> _safeClearSession() async {
    try {
      await _appSessionService.clearSession();
    } catch (_) {
      // Avoid masking startup routing fallback with a storage exception.
    }
  }

  AppStartDestination _destinationFromRole(AppRole role) {
    switch (role) {
      case AppRole.student:
        return AppStartDestination.studentDashboard;
      case AppRole.supervisor:
        return AppStartDestination.supervisorDashboard;
      case AppRole.coordinator:
        return AppStartDestination.coordinatorDashboard;
      case AppRole.admin:
        return AppStartDestination.adminDashboard;
      case AppRole.hod:
        return AppStartDestination.hodDashboard;
    }
  }

  AppRole? _roleFromString(String role) {
    switch (role.toUpperCase()) {
      case 'STUDENT':
        return AppRole.student;
      case 'SUPERVISOR':
        return AppRole.supervisor;
      case 'COORDINATOR':
        return AppRole.coordinator;
      case 'ADMIN':
        return AppRole.admin;
      case 'HOD':
        return AppRole.hod;
      default:
        return null;
    }
  }
}
