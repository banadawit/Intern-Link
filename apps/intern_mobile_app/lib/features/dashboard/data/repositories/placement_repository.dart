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
      proposalLetter: json['proposal_letter']?.toString(),
      requestedAt: json['requested_at'] != null
          ? DateTime.tryParse(json['requested_at'].toString()) ?? DateTime.now()
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
      final data = response.data as List;
      return data.map((e) => PlacementProposal.fromJson(e)).toList();
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
