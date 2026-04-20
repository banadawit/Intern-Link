import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/session_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../domain/entities/app_start_decision.dart';
import '../../domain/entities/app_start_destination.dart';
import '../../domain/services/app_initialization_service.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(apiClient: ref.watch(apiClientProvider)),
);

final appInitializationServiceProvider = Provider<AppInitializationService>(
  (ref) => AppInitializationService(
    appSessionService: ref.watch(appSessionServiceProvider),
    authRemoteDataSource: ref.watch(authRemoteDataSourceProvider),
  ),
);

final appStartDecisionProvider = FutureProvider<AppStartDecision>(
  (ref) => const AppStartDecision(destination: AppStartDestination.studentDashboard),
);
