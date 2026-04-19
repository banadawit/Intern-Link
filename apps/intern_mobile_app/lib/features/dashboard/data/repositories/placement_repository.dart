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
  final String? proposalLetter;
  final DateTime requestedAt;
  final String companyName;

  PlacementProposal({
    required this.id,
    required this.studentId,
    required this.companyId,
    required this.status,
    this.proposalLetter,
    required this.requestedAt,
    required this.companyName,
  });

  factory PlacementProposal.fromJson(Map<String, dynamic> json) {
    return PlacementProposal(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      companyId: json['companyId'] ?? 0,
      status: json['status'] ?? 'PENDING',
      proposalLetter: json['proposal_letter'],
      requestedAt: DateTime.parse(json['requested_at'] ?? DateTime.now().toIso8601String()),
      companyName: json['company']?['name'] ?? 'Unknown Company',
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
      final data = response.data as List;
      return data.map((e) => PlacementProposal.fromJson(e)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load proposals');
    } catch (e) {
      throw Exception('An unexpected error occurred');
    }
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
