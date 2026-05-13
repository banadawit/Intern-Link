import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class FinalEvaluation {
  final double technicalSkills;
  final double problemSolving;
  final double communication;
  final double teamCollaboration;
  final double timeManagement;
  final double adaptability;
  final double professionalism;
  final double initiativeCreativity;
  final double attendancePunctuality;
  final double taskCompletionQuality;
  final String comments;
  final DateTime evaluatedAt;
  final String supervisorName;
  final String companyName;

  const FinalEvaluation({
    required this.technicalSkills,
    required this.problemSolving,
    required this.communication,
    required this.teamCollaboration,
    required this.timeManagement,
    required this.adaptability,
    required this.professionalism,
    required this.initiativeCreativity,
    required this.attendancePunctuality,
    required this.taskCompletionQuality,
    required this.comments,
    required this.evaluatedAt,
    required this.supervisorName,
    required this.companyName,
  });

  double get overallScore => (technicalSkills + problemSolving + communication +
      teamCollaboration + timeManagement + adaptability + professionalism +
      initiativeCreativity + attendancePunctuality + taskCompletionQuality) / 10;

  factory FinalEvaluation.fromJson(Map<String, dynamic> json) {
    double sd(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return FinalEvaluation(
      technicalSkills: sd(json['technical_skills']),
      problemSolving: sd(json['problem_solving']),
      communication: sd(json['communication']),
      teamCollaboration: sd(json['team_collaboration']),
      timeManagement: sd(json['time_management']),
      adaptability: sd(json['adaptability']),
      professionalism: sd(json['professionalism']),
      initiativeCreativity: sd(json['initiative_creativity']),
      attendancePunctuality: sd(json['attendance_punctuality']),
      taskCompletionQuality: sd(json['task_completion_quality']),
      comments: json['comments']?.toString() ?? '',
      evaluatedAt: json['evaluatedAt'] != null
          ? DateTime.tryParse(json['evaluatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      supervisorName: json['supervisorName']?.toString() ?? 'Supervisor',
      companyName: json['companyName']?.toString() ?? 'Company',
    );
  }
}

// ── Repository ────────────────────────────────────────────────────────────────

class EvaluationRepository {
  EvaluationRepository(this._apiClient);
  final ApiClient _apiClient;

  /// Returns null if no evaluation has been submitted yet.
  Future<FinalEvaluation?> getMyEvaluation() async {
    final response = await _apiClient.dio.get('/reports/my-evaluation');
    final raw = response.data;
    // After interceptor unwrap: raw = { evaluation: {...} } or { evaluation: null }
    // The interceptor unwraps success.data → so raw IS the data object
    final evalData = raw is Map ? raw['evaluation'] : null;
    if (evalData == null) return null;
    return FinalEvaluation.fromJson(Map<String, dynamic>.from(evalData as Map));
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────

final evaluationRepositoryProvider = Provider<EvaluationRepository>((ref) {
  return EvaluationRepository(ref.watch(apiClientProvider));
});

final myEvaluationProvider = FutureProvider.autoDispose<FinalEvaluation?>((ref) {
  return ref.watch(evaluationRepositoryProvider).getMyEvaluation();
});
