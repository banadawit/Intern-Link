import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

// ---------------------------------------------------------
// DATA MODELS
// ---------------------------------------------------------

class PlacementProposal {
  final int id;
  final int studentId;
  final int companyId;
  final String status;
  final String proposalType;
  final String? proposalLetter;
  final DateTime requestedAt;
  final String companyName;

  PlacementProposal({
    required this.id,
    required this.studentId,
    required this.companyId,
    required this.status,
    required this.proposalType,
    this.proposalLetter,
    required this.requestedAt,
    required this.companyName,
  });

  bool get isOpenLetter => proposalType == 'Open_Letter';

  factory PlacementProposal.fromJson(Map<String, dynamic> json) {
    int si(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }
    return PlacementProposal(
      id: si(json['id']),
      studentId: si(json['studentId']),
      companyId: si(json['companyId']),
      status: json['status']?.toString() ?? 'PENDING',
      proposalType: json['proposal_type']?.toString() ?? '',
      proposalLetter: json['expected_outcomes']?.toString(),
      requestedAt: json['submitted_at'] != null
          ? DateTime.tryParse(json['submitted_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      companyName: json['company']?['name']?.toString() ?? 'Unknown Company',
    );
  }
}

// ---------------------------------------------------------
// REPOSITORY
// ---------------------------------------------------------

class PlacementRepository {
  PlacementRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<PlacementProposal>> getMyProposals() async {
    try {
      final response = await _apiClient.dio.get('/placements/my-proposals');
      final raw = response.data;
      final list = (raw is Map ? raw['data'] : raw) as List? ?? [];
      return list.map((e) => PlacementProposal.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Failed to load proposals';
      if (data is Map && data.containsKey('message')) {
        message = data['message'];
      } else if (data is String) {
        message = data;
      }
      throw Exception(message);
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<PlacementProposal> submitOpenLetter({
    required String companyName,
    required String coverLetter,
  }) async {
    final response = await _apiClient.dio.post('/student/open-letter', data: {
      'company_name': companyName,
      'cover_letter': coverLetter,
    });
    final raw = response.data;
    final data = (raw is Map ? raw['data'] : raw) as Map<String, dynamic>;
    return PlacementProposal.fromJson(data);
  }
}

// ---------------------------------------------------------
// PROVIDERS
// ---------------------------------------------------------

final placementRepositoryProvider = Provider<PlacementRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PlacementRepository(apiClient);
});

final myProposalsProvider = FutureProvider.autoDispose<List<PlacementProposal>>((ref) async {
  final repo = ref.watch(placementRepositoryProvider);
  return await repo.getMyProposals();
});
