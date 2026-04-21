import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/plans_repository.dart';
import 'plans_providers.dart';

class PlanEditorState {
  final int? draftId;
  final int? submittedPlanId;
  final int weekNumber;
  final String title;
  final String objectives;
  final List<String> tasks;
  final bool isSavingDraft;
  final bool isSubmitting;
  final String? error;

  const PlanEditorState({
    this.draftId,
    this.submittedPlanId,
    required this.weekNumber,
    required this.title,
    required this.objectives,
    required this.tasks,
    this.isSavingDraft = false,
    this.isSubmitting = false,
    this.error,
  });

  bool get isEditingDraft => draftId != null && submittedPlanId == null;
}

final planEditorProvider = AutoDisposeNotifierProviderFamily<PlanEditorNotifier, PlanEditorState, PlanEditorArgs>(
  PlanEditorNotifier.new,
);

class PlanEditorArgs {
  final int? draftId;
  final int? submittedPlanId;
  final int initialWeekNumber;
  final String initialTitle;
  final String initialObjectives;
  final List<String> initialTasks;

  const PlanEditorArgs({
    this.draftId,
    this.submittedPlanId,
    required this.initialWeekNumber,
    required this.initialTitle,
    required this.initialObjectives,
    required this.initialTasks,
  });
}

class PlanEditorNotifier extends AutoDisposeNotifier<PlanEditorState> {
  @override
  PlanEditorState build(PlanEditorArgs arg) {
    return PlanEditorState(
      draftId: arg.draftId,
      submittedPlanId: arg.submittedPlanId,
      weekNumber: arg.initialWeekNumber,
      title: arg.initialTitle,
      objectives: arg.initialObjectives,
      tasks: arg.initialTasks,
    );
  }

  void setWeekNumber(int v) => state = PlanEditorState(
        draftId: state.draftId,
        submittedPlanId: state.submittedPlanId,
        weekNumber: v,
        title: state.title,
        objectives: state.objectives,
        tasks: state.tasks,
        isSavingDraft: state.isSavingDraft,
        isSubmitting: state.isSubmitting,
        error: null,
      );

  void setTitle(String v) => state = PlanEditorState(
        draftId: state.draftId,
        submittedPlanId: state.submittedPlanId,
        weekNumber: state.weekNumber,
        title: v,
        objectives: state.objectives,
        tasks: state.tasks,
        isSavingDraft: state.isSavingDraft,
        isSubmitting: state.isSubmitting,
        error: null,
      );

  void setObjectives(String v) => state = PlanEditorState(
        draftId: state.draftId,
        submittedPlanId: state.submittedPlanId,
        weekNumber: state.weekNumber,
        title: state.title,
        objectives: v,
        tasks: state.tasks,
        isSavingDraft: state.isSavingDraft,
        isSubmitting: state.isSubmitting,
        error: null,
      );

  void setTask(int index, String v) {
    final next = [...state.tasks];
    next[index] = v;
    state = PlanEditorState(
      draftId: state.draftId,
      submittedPlanId: state.submittedPlanId,
      weekNumber: state.weekNumber,
      title: state.title,
      objectives: state.objectives,
      tasks: next,
      isSavingDraft: state.isSavingDraft,
      isSubmitting: state.isSubmitting,
      error: null,
    );
  }

  void addTask() {
    state = PlanEditorState(
      draftId: state.draftId,
      submittedPlanId: state.submittedPlanId,
      weekNumber: state.weekNumber,
      title: state.title,
      objectives: state.objectives,
      tasks: [...state.tasks, ''],
      isSavingDraft: state.isSavingDraft,
      isSubmitting: state.isSubmitting,
      error: null,
    );
  }

  void removeTask(int index) {
    if (state.tasks.length <= 1) return;
    final next = [...state.tasks]..removeAt(index);
    state = PlanEditorState(
      draftId: state.draftId,
      submittedPlanId: state.submittedPlanId,
      weekNumber: state.weekNumber,
      title: state.title,
      objectives: state.objectives,
      tasks: next,
      isSavingDraft: state.isSavingDraft,
      isSubmitting: state.isSubmitting,
      error: null,
    );
  }

  String? validate() {
    if (state.weekNumber <= 0) return 'Week number is required';
    if (state.title.trim().isEmpty) return 'Title is required';
    if (state.objectives.trim().isEmpty) return 'Objectives are required';
    final nonEmptyTasks = state.tasks.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    if (nonEmptyTasks.length < 2) return 'Please enter at least 2 tasks';
    return null;
  }

  Future<void> saveDraft() async {
    final error = validate();
    if (error != null) {
      state = PlanEditorState(
        draftId: state.draftId,
        submittedPlanId: state.submittedPlanId,
        weekNumber: state.weekNumber,
        title: state.title,
        objectives: state.objectives,
        tasks: state.tasks,
        isSavingDraft: false,
        isSubmitting: state.isSubmitting,
        error: error,
      );
      return;
    }

    state = PlanEditorState(
      draftId: state.draftId,
      submittedPlanId: state.submittedPlanId,
      weekNumber: state.weekNumber,
      title: state.title,
      objectives: state.objectives,
      tasks: state.tasks,
      isSavingDraft: true,
      isSubmitting: state.isSubmitting,
      error: null,
    );

    final repo = ref.read(plansRepositoryProvider);
    final draft = await repo.upsertDraft(
      draftId: state.draftId,
      weekNumber: state.weekNumber,
      title: state.title,
      objectives: state.objectives,
      tasks: state.tasks,
    );

    ref.invalidate(plansProvider);
    state = PlanEditorState(
      draftId: draft.id,
      submittedPlanId: null,
      weekNumber: draft.weekNumber,
      title: draft.title,
      objectives: draft.objectives,
      tasks: draft.tasks,
      isSavingDraft: false,
      isSubmitting: state.isSubmitting,
      error: null,
    );
  }

  Future<void> submit({String? presentationFilePath}) async {
    final error = validate();
    if (error != null) {
      state = PlanEditorState(
        draftId: state.draftId,
        submittedPlanId: state.submittedPlanId,
        weekNumber: state.weekNumber,
        title: state.title,
        objectives: state.objectives,
        tasks: state.tasks,
        isSavingDraft: state.isSavingDraft,
        isSubmitting: false,
        error: error,
      );
      return;
    }

    state = PlanEditorState(
      draftId: state.draftId,
      submittedPlanId: state.submittedPlanId,
      weekNumber: state.weekNumber,
      title: state.title,
      objectives: state.objectives,
      tasks: state.tasks,
      isSavingDraft: state.isSavingDraft,
      isSubmitting: true,
      error: null,
    );

    final repo = ref.read(plansRepositoryProvider);
    await repo.submitPlan(
      weekNumber: state.weekNumber,
      title: state.title,
      objectives: state.objectives,
      tasks: state.tasks,
      presentationFilePath: presentationFilePath,
      deleteDraftIdAfterSubmit: state.draftId,
    );

    ref.read(plansProvider.notifier).refresh();
    state = PlanEditorState(
      draftId: null,
      submittedPlanId: null,
      weekNumber: state.weekNumber,
      title: state.title,
      objectives: state.objectives,
      tasks: state.tasks,
      isSavingDraft: false,
      isSubmitting: false,
      error: null,
    );
  }
}


