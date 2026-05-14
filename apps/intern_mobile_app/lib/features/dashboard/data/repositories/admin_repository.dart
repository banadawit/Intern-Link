import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';

dynamic _deepConvert(dynamic v) {
  if (v is Map) return Map<String, dynamic>.fromEntries(
    v.entries.map((e) => MapEntry(e.key.toString(), _deepConvert(e.value))),
  );
  if (v is List) return v.map(_deepConvert).toList();
  return v;
}

List<dynamic> _deepList(dynamic data) {
  final raw = data is Map ? (data['data'] ?? data) : data;
  if (raw is List) return raw.map(_deepConvert).toList();
  return [];
}

class AdminStats {
  final int totalUsers;
  final int totalUniversities;
   final int totalCompanies;
  final int pendingApprovals;
  final int pendingCoordinators;
  final int pendingSupervisors;
  final int pendingHods;
  final int pendingOrganizationRequests;
  final int totalEvaluations;
  final int totalReports;

  AdminStats({
    required this.totalUsers,
    required this.totalUniversities,
    required this.totalCompanies,
    required this.pendingApprovals,
    required this.pendingCoordinators,
    required this.pendingSupervisors,
    required this.pendingHods,
    required this.pendingOrganizationRequests,
    required this.totalEvaluations,
    required this.totalReports,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AdminStats(
      totalUsers: toInt(json['totalUsers']),
      totalUniversities: toInt(json['totalUniversities']),
      totalCompanies: toInt(json['totalCompanies']),
      pendingApprovals: toInt(json['pendingApprovals']),
      pendingCoordinators: toInt(json['pendingCoordinators']),
      pendingSupervisors: toInt(json['pendingSupervisors']),
      pendingHods: toInt(json['pendingHods']),
      pendingOrganizationRequests: toInt(json['pendingOrganizationRequests']),
      totalEvaluations: toInt(json['totalEvaluations']),
      totalReports: toInt(json['totalReports']),
    );
  }
}

class AdminRepository {
  AdminRepository({required this.apiClient});
  final ApiClient apiClient;

  Future<AdminStats> getStats() async {
    final response = await apiClient.dio.get('/admin/stats');
    final data = response.data;
    if (data != null && data is Map) {
      int si(dynamic v) {
        if (v == null) return 0;
        if (v is int) return v;
        if (v is double) return v.toInt();
        if (v is String) return int.tryParse(v) ?? 0;
        return 0;
      }
      return AdminStats(
        totalUsers: si(data['totalUsers']),
        totalUniversities: si(data['approvedUniversities']) + si(data['pendingUniversities']),
        totalCompanies: si(data['approvedCompanies']) + si(data['pendingCompanies']),
        pendingApprovals: si(data['pendingUniversities']) +
            si(data['pendingCompanies']) +
            si(data['pendingCoordinators']) +
            si(data['pendingSupervisors']) +
            si(data['pendingHods']) +
            si(data['pendingOrganizationRequests']),
        pendingCoordinators: si(data['pendingCoordinators']),
        pendingSupervisors: si(data['pendingSupervisors']),
        pendingHods: si(data['pendingHods']),
        pendingOrganizationRequests: si(data['pendingOrganizationRequests']),
        totalEvaluations: si(data['totalEvaluations']),
        totalReports: si(data['totalReports']),
      );
    }
    throw Exception('Failed to fetch admin stats');
  }

  Future<List<dynamic>> getPendingUniversities() async {
    final response = await apiClient.dio.get('/admin/pending-universities');
    return _deepList(response.data);
  }

  Future<List<dynamic>> getPendingCompanies() async {
    final response = await apiClient.dio.get('/admin/pending-companies');
    return _deepList(response.data);
  }

  Future<List<dynamic>> getPendingCoordinators() async {
    final response = await apiClient.dio.get('/admin/pending-coordinators');
    return _deepList(response.data);
  }

  Future<List<dynamic>> getPendingSupervisors() async {
    final response = await apiClient.dio.get('/admin/pending-supervisors');
    return _deepList(response.data);
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await apiClient.dio.get('/admin/users');
    return _deepList(response.data);
  }

  Future<List<dynamic>> getAuditLogs() async {
    final response = await apiClient.dio.get('/admin/audit-logs');
    return _deepList(response.data);
  }

  Future<void> updateUniversityStatus(int id, String status, {String? reason}) async {
    await apiClient.dio.patch('/admin/university-status/$id', data: {
      'status': status,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> updateCompanyStatus(int id, String status, {String? reason}) async {
    await apiClient.dio.patch('/admin/company-status/$id', data: {
      'status': status,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> approveCoordinator(int userId, {String? universityNameOverride}) async {
    await apiClient.dio.post('/admin/coordinators/$userId/approve',
        data: universityNameOverride != null ? {'universityNameOverride': universityNameOverride} : null);
  }

  Future<void> rejectCoordinator(int userId) async {
    await apiClient.dio.post('/admin/coordinators/$userId/reject');
  }

  Future<void> approveSupervisor(int userId) async {
    await apiClient.dio.post('/admin/supervisors/$userId/approve');
  }

  Future<void> rejectSupervisor(int userId) async {
    await apiClient.dio.post('/admin/supervisors/$userId/reject');
  }
  Future<List<dynamic>> getAllUniversities({String? status}) async {
    final response = await apiClient.dio.get('/admin/universities', queryParameters: status != null ? {'status': status} : null);
    return _deepList(response.data);
  }

  Future<List<dynamic>> getAllCompanies({String? status}) async {
    final response = await apiClient.dio.get('/admin/companies', queryParameters: status != null ? {'status': status} : null);
    return _deepList(response.data);
  }

  // --- ORGANIZATION REQUESTS (NEW FLOW) ---

  Future<List<dynamic>> getOrganizationRequests() async {
    final response = await apiClient.dio.get('/admin/requests');
    return _deepList(response.data);
  }

  Future<void> markRequestAsViewed(int id) async {
    await apiClient.dio.patch('/admin/requests/$id/view');
  }

  Future<void> markUserViewed(int userId) async {
    await apiClient.dio.patch('/admin/users/$userId/mark-viewed');
  }

  Future<void> approveOrganizationRequest(int id, {String? resolution}) async {
    await apiClient.dio.post('/admin/requests/$id/approve', data: {if (resolution != null) 'resolution': resolution});
  }

  Future<void> rejectOrganizationRequest(int id, {String? reason}) async {
    await apiClient.dio.post('/admin/requests/$id/reject', data: {
      if (reason != null) 'reason': reason,
    });
  }

  // --- MERGE DUPLICATES ---

  Future<List<dynamic>> findDuplicateUniversities() async {
    final response = await apiClient.dio.get('/admin/merge/duplicates/universities');
    return _deepList(response.data);
  }

  Future<List<dynamic>> findDuplicateCompanies() async {
    final response = await apiClient.dio.get('/admin/merge/duplicates/companies');
    return _deepList(response.data);
  }

  Future<void> mergeUniversities(int sourceId, int targetId) async {
    await apiClient.dio.post('/admin/merge/universities', data: {'sourceId': sourceId, 'targetId': targetId});
  }

  Future<void> mergeCompanies(int sourceId, int targetId) async {
    await apiClient.dio.post('/admin/merge/companies', data: {'sourceId': sourceId, 'targetId': targetId});
  }

  // --- SYSTEM CONFIGURATION ---

  Future<Map<String, String>> getConfig() async {
    final response = await apiClient.dio.get('/admin/config');
    final raw = response.data;
    // After interceptor unwrap: raw = { key: value, ... } (flat map)
    // Or if not unwrapped: raw = { success: true, data: { key: value } }
    Map<dynamic, dynamic>? configMap;
    if (raw is Map) {
      // Check if it's already the flat config or still wrapped
      if (raw.containsKey('success') && raw.containsKey('data')) {
        configMap = raw['data'] as Map?;
      } else {
        configMap = raw;
      }
    }
    if (configMap == null) return {};
    return Map<String, String>.fromEntries(
      configMap.entries.map((e) => MapEntry(e.key.toString(), e.value?.toString() ?? '')),
    );
  }

  Future<Map<String, String>> updateConfig(Map<String, String> updates) async {
    final response = await apiClient.dio.patch('/admin/config', data: updates);
    final raw = response.data;
    // Return the updated config so the UI can update immediately
    Map<dynamic, dynamic>? configMap;
    if (raw is Map) {
      if (raw.containsKey('success') && raw.containsKey('data')) {
        configMap = raw['data'] as Map?;
      } else {
        configMap = raw;
      }
    }
    if (configMap == null) return updates;
    return Map<String, String>.fromEntries(
      configMap.entries.map((e) => MapEntry(e.key.toString(), e.value?.toString() ?? '')),
    );
  }

  // --- MANUAL ENTITY CREATION ---

  /// Create a university (auto-approved). Optionally creates a coordinator
  /// contact user who receives a password setup email.
  Future<Map<String, dynamic>> createUniversity({
    required String name,
    required String officialEmail,
    String? address,
    String? contactName,
    String? contactEmail,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'official_email': officialEmail,
      if (address != null && address.isNotEmpty) 'address': address,
      if (contactName != null && contactName.isNotEmpty && contactEmail != null && contactEmail.isNotEmpty)
        'contactUser': {'name': contactName, 'email': contactEmail},
    };
    final response = await apiClient.dio.post('/admin/universities', data: body);
    final raw = response.data;
    if (raw is Map) {
      if (raw.containsKey('success')) {
        if (raw['success'] == true) {
          final data = raw['data'] is Map ? raw['data'] : {};
          return Map<String, dynamic>.from(data['university'] ?? data);
        }
        throw Exception(raw['error'] ?? raw['message'] ?? 'Failed');
      } else {
        return Map<String, dynamic>.from(raw['university'] ?? raw);
      }
    }
    throw Exception('Failed');
  }

  /// Create a company (auto-approved). Optionally creates a supervisor
  /// contact user who receives a password setup email.
  Future<Map<String, dynamic>> createCompany({
    required String name,
    required String officialEmail,
    String? address,
    String? contactName,
    String? contactEmail,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'official_email': officialEmail,
      if (address != null && address.isNotEmpty) 'address': address,
      if (contactName != null && contactName.isNotEmpty && contactEmail != null && contactEmail.isNotEmpty)
        'contactUser': {'name': contactName, 'email': contactEmail},
    };
    final response = await apiClient.dio.post('/admin/companies', data: body);
    final raw = response.data;
    if (raw is Map) {
      if (raw.containsKey('success')) {
        if (raw['success'] == true) {
          final data = raw['data'] is Map ? raw['data'] : {};
          return Map<String, dynamic>.from(data['company'] ?? data);
        }
        throw Exception(raw['error'] ?? raw['message'] ?? 'Failed');
      } else {
        return Map<String, dynamic>.from(raw['company'] ?? raw);
      }
    }
    throw Exception('Failed');
  }

  /// Set per-university student registration override.
  /// [enabled] = true/false to override, null to inherit global setting.
  Future<void> setUniversityStudentReg(int universityId, bool? enabled) async {
    await apiClient.dio.patch(
      '/admin/universities/$universityId/config',
      data: {'studentRegistrationEnabled': enabled},
    );
  }

  /// Send (or resend) a password setup link to an existing user by email.
  Future<List<dynamic>> getPendingHods() async {
    final res = await apiClient.dio.get('/admin/pending-hods');
    return res.data as List<dynamic>;
  }

  Future<void> approveHod(int userId) async {
    await apiClient.dio.post('/admin/hods/$userId/approve');
  }

  Future<void> rejectHod(int userId, {String? reason}) async {
    await apiClient.dio.post('/admin/hods/$userId/reject', data: {'reason': reason});
  }

  Future<void> sendSetupLink(String email) async {
    await apiClient.dio.post('/auth/send-setup-link', data: {'email': email});
  }

  Future<bool> testSmtp() async {
    final response = await apiClient.dio.post('/admin/config/test-smtp');
    return response.data['success'] == true;
  }

  Future<void> broadcast(String title, String content) async {
    await apiClient.dio.post('/admin/config/broadcast', data: {
      'title': title,
      'content': content,
    });
  }

  Future<String> exportAuditLogsCsv() async {
    final response = await apiClient.dio.get(
      '/admin/config/export-audit-csv',
      options: Options(responseType: ResponseType.plain),
    );
    return response.data.toString();
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final response = await apiClient.dio.get('/admin/analytics');
    final raw = response.data;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(apiClient: ref.watch(apiClientProvider));
});

final adminStatsProvider = FutureProvider<AdminStats>((ref) {
  return ref.watch(adminRepositoryProvider).getStats();
});

final pendingUniversitiesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingUniversities();
});

final pendingCompaniesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingCompanies();
});

final pendingCoordinatorsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingCoordinators();
});

final pendingSupervisorsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingSupervisors();
});

final adminPendingHodsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getPendingHods();
});

final allUsersProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUsers();
});

final auditLogsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAuditLogs();
});

final allUniversitiesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUniversities();
});

final allCompaniesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllCompanies();
});

final verifiedUniversitiesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllUniversities(status: 'APPROVED');
});

final verifiedCompaniesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAllCompanies(status: 'APPROVED');
});

final organizationRequestsProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getOrganizationRequests();
});

final systemConfigProvider = FutureProvider<Map<String, String>>((ref) {
  return ref.watch(adminRepositoryProvider).getConfig();
});

final adminAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).getAnalytics();
});

final duplicateUniversitiesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).findDuplicateUniversities();
});

final duplicateCompaniesProvider = FutureProvider<List<dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).findDuplicateCompanies();
});
