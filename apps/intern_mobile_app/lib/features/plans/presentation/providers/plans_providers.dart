import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/plans_repository.dart';
import '../../domain/entities/weekly_plan.dart';

final plansProvider = AsyncNotifierProvider<PlansNotifier, List<WeeklyPlan>>(PlansNotifier.new);

class PlansNotifier extends AsyncNotifier<List<WeeklyPlan>> {
  @override
  Future<List<WeeklyPlan>> build() async {
    final repo = ref.watch(plansRepositoryProvider);
    return repo.getPlans();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(plansRepositoryProvider);
      return repo.getPlans();
    });
  }
}

final planDetailProvider = Provider.family<WeeklyPlan?, int>((ref, planId) {
  final plans = ref.watch(plansProvider).valueOrNull;
  if (plans == null) return null;
  try {
    return plans.firstWhere((p) => p.id == planId);
  } catch (_) {
    return null;
  }
});

