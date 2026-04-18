import 'app_start_destination.dart';

class AppStartDecision {
  const AppStartDecision({
    required this.destination,
    this.isValidatingToken = false,
  });

  final AppStartDestination destination;
  final bool isValidatingToken;
}
