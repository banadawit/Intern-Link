class FinalEvaluation {
  final int id;
  final int studentId;
  final int supervisorId;
  final double technicalScore;
  final double softSkillScore;
  final String? comments;
  final DateTime evaluatedAt;

  const FinalEvaluation({
    required this.id,
    required this.studentId,
    required this.supervisorId,
    required this.technicalScore,
    required this.softSkillScore,
    this.comments,
    required this.evaluatedAt,
  });

  factory FinalEvaluation.fromJson(Map<String, dynamic> json) {
    return FinalEvaluation(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      supervisorId: json['supervisorId'] ?? 0,
      technicalScore: (json['technical_score'] as num?)?.toDouble() ?? 0.0,
      softSkillScore: (json['soft_skill_score'] as num?)?.toDouble() ?? 0.0,
      comments: json['comments'],
      evaluatedAt: json['evaluated_at'] != null 
          ? DateTime.parse(json['evaluated_at']) 
          : DateTime.now(),
    );
  }
}

class InternshipReport {
  final int id;
  final int studentId;
  final String pdfUrl;
  final bool stamped;
  final DateTime generatedAt;
  final DateTime? sentAt;
  final bool locked;

  const InternshipReport({
    required this.id,
    required this.studentId,
    required this.pdfUrl,
    required this.stamped,
    required this.generatedAt,
    this.sentAt,
    required this.locked,
  });

  factory InternshipReport.fromJson(Map<String, dynamic> json) {
    return InternshipReport(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      pdfUrl: json['pdf_url'] ?? '',
      stamped: json['stamped'] ?? false,
      generatedAt: json['generated_at'] != null 
          ? DateTime.parse(json['generated_at']) 
          : DateTime.now(),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      locked: json['locked'] ?? false,
    );
  }
}
