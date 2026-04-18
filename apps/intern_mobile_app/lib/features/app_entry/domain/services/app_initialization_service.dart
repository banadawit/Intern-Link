import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/local_app_flags_data_source.dart';
import '../../data/datasources/session_secure_storage.dart';
import '../entities/app_role.dart';
import '../entities/app_start_decision.dart';
import '../entities/app_start_destination.dart';

class AppInitializationService {
  AppInitializationService({
    required LocalAppFlagsDataSource localAppFlagsDataSource,
    required SessionSecureStorage sessionSecureStorage,
    required AuthRemoteDataSource authRemoteDataSource,
  })  : _localAppFlagsDataSource = localAppFlagsDataSource,
        _sessionSecureStorage = sessionSecureStorage,
        _authRemoteDataSource = authRemoteDataSource;

  final LocalAppFlagsDataSource _localAppFlagsDataSource;
  final SessionSecureStorage _sessionSecureStorage;
  final AuthRemoteDataSource _authRemoteDataSource;

  Future<AppStartDecision> resolveStartDestination() async {
    final firstLaunchFuture = _localAppFlagsDataSource.isFirstLaunchCompleted();
    final authTokenFuture = _sessionSecureStorage.readAuthToken();

    final firstLaunchCompleted = await firstLaunchFuture;
    final authToken = await authTokenFuture;

    if (!firstLaunchCompleted) {
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
      await _sessionSecureStorage.clearSession();
      return const AppStartDecision(destination: AppStartDestination.auth);
    } catch (_) {
      await _sessionSecureStorage.clearSession();
      return const AppStartDecision(destination: AppStartDestination.auth);
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
