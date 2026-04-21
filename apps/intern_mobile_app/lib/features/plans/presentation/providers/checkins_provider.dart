import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/plans_repository.dart';
import 'plans_providers.dart';

final checkinsControllerProvider = AutoDisposeNotifierProviderFamily<CheckinsController, void, int>(
  CheckinsController.new,
);

class CheckinsController extends AutoDisposeNotifier<void> {
  @override
  void build(int planId) {}

  Future<void> markPresent({
    required int planId,
    required String workDateIso,
    String? notes,
  }) async {
    final repo = ref.read(plansRepositoryProvider);
    await repo.submitCheckin(planId: planId, workDateIso: workDateIso, notes: notes);
    ref.read(plansProvider.notifier).refresh();
  }

  Future<void> delete({
    required int planId,
    required String workDateIso,
  }) async {
    final repo = ref.read(plansRepositoryProvider);
    await repo.deleteCheckin(planId: planId, workDateIso: workDateIso);
    ref.read(plansProvider.notifier).refresh();
  }
}

