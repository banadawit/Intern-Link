// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

/// Triggers a CSV file download in the browser.
/// Only works on Flutter Web — no-op on other platforms.
void downloadCsv(String csvContent, String filename) {
  if (!kIsWeb) {
    debugPrint('[downloadCsv] Not on web — skipping download.');
    return;
  }
  try {
    // Add UTF-8 BOM so Excel opens it correctly
    const bom = '\uFEFF';
    final blob = html.Blob([bom + csvContent], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  } catch (e) {
    debugPrint('[downloadCsv] Error: $e');
  }
}
