import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class FinalEvaluation {
  final double technicalScore;
  final double softSkillScore;
  final String comments;
  final DateTime evaluatedAt;
  final String supervisorName;
  final String companyName;

  const FinalEvaluation({
    required this.technicalScore,
    required this.softSkillScore,
    required this.comments,
    required this.evaluatedAt,
    required this.supervisorName,
    required this.companyName,
  });

  double get overallScore => (technicalScore + softSkillScore) / 2;

  factory FinalEvaluation.fromJson(Map<String, dynamic> json) {
    double sd(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return FinalEvaluation(
      technicalScore: sd(json['technicalScore']),
      softSkillScore: sd(json['softSkillScore']),
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
    final evalData = raw is Map ? (raw['evaluation'] ?? raw['data']?['evaluation']) : null;
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
