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
  final String? comments;
  final DateTime evaluatedAt;

  const FinalEvaluation({
    required this.id,
    required this.studentId,
    required this.supervisorId,
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
    this.comments,
    required this.evaluatedAt,
  });

  double get averageScore => (technicalSkills + problemSolving + communication +
      teamCollaboration + timeManagement + adaptability + professionalism +
      initiativeCreativity + attendancePunctuality + taskCompletionQuality) / 10;

  factory FinalEvaluation.fromJson(Map<String, dynamic> json) {
    return FinalEvaluation(
      id: _si(json['id']),
      studentId: _si(json['studentId']),
      supervisorId: _si(json['supervisorId']),
      technicalSkills: _safeDouble(json['technical_skills']),
      problemSolving: _safeDouble(json['problem_solving']),
      communication: _safeDouble(json['communication']),
      teamCollaboration: _safeDouble(json['team_collaboration']),
      timeManagement: _safeDouble(json['time_management']),
      adaptability: _safeDouble(json['adaptability']),
      professionalism: _safeDouble(json['professionalism']),
      initiativeCreativity: _safeDouble(json['initiative_creativity']),
      attendancePunctuality: _safeDouble(json['attendance_punctuality']),
      taskCompletionQuality: _safeDouble(json['task_completion_quality']),
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
