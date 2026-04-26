import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/plans_repository.dart';
import 'plans_providers.dart';

final checkinsControllerProvider = NotifierProvider<CheckinsController, AsyncValue<void>>(
  CheckinsController.new,
);

class CheckinsController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> markPresent({
    required int planId,
    required String workDateIso,
    String? notes,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(plansRepositoryProvider);
      await repo.submitCheckin(planId: planId, workDateIso: workDateIso, notes: notes);
      await ref.read(plansProvider.notifier).refresh();
    });
  }

  Future<void> delete({
    required int planId,
    required String workDateIso,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(plansRepositoryProvider);
      await repo.deleteCheckin(planId: planId, workDateIso: workDateIso);
      await ref.read(plansProvider.notifier).refresh();
    });
  }
}

