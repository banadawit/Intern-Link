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
    final firstLaunchFuture = _appSessionService.isFirstLaunch();
    final authTokenFuture = _appSessionService.getToken();

    final isFirstLaunch = await firstLaunchFuture;
    final authToken = await authTokenFuture;

    if (isFirstLaunch) {
      return const AppStartDecision(
        destination: AppStartDestination.onboarding,
      );
    }

    if (authToken == null || authToken.isEmpty) {
      return const AppStartDecision(destination: AppStartDestination.auth);
    }

    try {
      final user = await _authRemoteDataSource.fetchCurrentUser(authToken);
      return AppStartDecision(destination: _destinationFromRole(user.role));
    } on SessionInvalidException {
      await _safeClearSession();
      return const AppStartDecision(destination: AppStartDestination.auth);
    } catch (_) {
      await _safeClearSession();
      return const AppStartDecision(destination: AppStartDestination.auth);
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
    }
  }
}
