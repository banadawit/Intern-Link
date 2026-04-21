import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/plans_repository.dart';
import 'plans_providers.dart';

final checkinsControllerProvider =
    StateNotifierProvider.family.autoDispose<CheckinsController, AsyncValue<void>, int>(
  (ref, planId) => CheckinsController(ref, planId),
);

class CheckinsController extends StateNotifier<AsyncValue<void>> {
  CheckinsController(this._ref, this.planId) : super(const AsyncData(null));

  final Ref _ref;
  final int planId;

  Future<void> markPresent({
    required String workDateIso,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(plansRepositoryProvider);
      await repo.submitCheckin(planId: planId, workDateIso: workDateIso, notes: notes);
      await _ref.read(plansProvider.notifier).refresh();
    });
  }

  Future<void> delete({
    required String workDateIso,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = _ref.read(plansRepositoryProvider);
      await repo.deleteCheckin(planId: planId, workDateIso: workDateIso);
      await _ref.read(plansProvider.notifier).refresh();
    });
  }
}

