import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';

/// Stores draft plans locally because current backend stores plans only once submitted (PENDING/APPROVED/REJECTED).
class PlansDraftStorage {
  Future<List<Map<String, dynamic>>> loadDrafts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.studentPlanDrafts);
    if (raw == null || raw.trim().isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveDrafts(List<Map<String, dynamic>> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.studentPlanDrafts, jsonEncode(drafts));
  }
}

