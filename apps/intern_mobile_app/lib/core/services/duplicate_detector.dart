import 'dart:math';

/// Simple duplicate detector using Levenshtein distance.
class DuplicateDetector {
  /// Maximum Levenshtein distance to consider two strings duplicates.
  final int threshold;

  DuplicateDetector({this.threshold = 2});

  /// Returns true if [candidate] is considered a duplicate of any entry in [existing].
  bool isDuplicate(String candidate, List<String> existing) {
    final normalizedCandidate = candidate.toLowerCase().trim();
    for (final entry in existing) {
      final normalizedEntry = entry.toLowerCase().trim();
      final distance = _levenshtein(normalizedCandidate, normalizedEntry);
      if (distance <= threshold) return true;
    }
    return false;
  }

  /// Computes the Levenshtein distance between two strings.
  int _levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    final List<int> v0 = List<int>.filled(t.length + 1, 0);
    final List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i <= t.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final cost = s[i] == t[j] ? 0 : 1;
        v1[j + 1] = min(
          v1[j] + 1,
          min(v0[j + 1] + 1, v0[j] + cost),
        );
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }
}
