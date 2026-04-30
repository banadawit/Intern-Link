int _si(dynamic v, [int fb = 0]) {
  if (v == null) return fb;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fb;
  return fb;
}

double _safeDouble(dynamic v, [double fb = 0.0]) {
  if (v == null) return fb;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fb;
  return fb;
}

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
      id: _si(json['id']),
      studentId: _si(json['studentId']),
      supervisorId: _si(json['supervisorId']),
      technicalScore: _safeDouble(json['technical_score']),
      softSkillScore: _safeDouble(json['soft_skill_score']),
      comments: json['comments'],
      evaluatedAt: json['evaluated_at'] != null
          ? DateTime.tryParse(json['evaluated_at'].toString()) ?? DateTime.now()
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
      id: _si(json['id']),
      studentId: _si(json['studentId']),
      pdfUrl: json['pdf_url']?.toString() ?? '',
      stamped: json['stamped'] == true,
      generatedAt: json['generated_at'] != null
          ? DateTime.tryParse(json['generated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      sentAt: json['sent_at'] != null
          ? DateTime.tryParse(json['sent_at'].toString())
          : null,
      locked: json['locked'] == true,
    );
  }
}
