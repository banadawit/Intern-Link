import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/datasources/local_app_flags_data_source.dart';
import '../../data/datasources/session_secure_storage.dart';
import '../../domain/entities/app_start_decision.dart';
import '../../domain/services/app_initialization_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final localAppFlagsDataSourceProvider =
    Provider<LocalAppFlagsDataSource>((ref) => LocalAppFlagsDataSource());

final sessionSecureStorageProvider =
    Provider<SessionSecureStorage>((ref) => SessionSecureStorage());

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final appInitializationServiceProvider = Provider<AppInitializationService>(
  (ref) => AppInitializationService(
    localAppFlagsDataSource: ref.watch(localAppFlagsDataSourceProvider),
    sessionSecureStorage: ref.watch(sessionSecureStorageProvider),
    authRemoteDataSource: ref.watch(authRemoteDataSourceProvider),
  ),
);

final appStartDecisionProvider = FutureProvider<AppStartDecision>(
  (ref) => ref.watch(appInitializationServiceProvider).resolveStartDestination(),
);
