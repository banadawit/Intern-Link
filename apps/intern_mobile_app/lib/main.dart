import 'dart:io';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set minimum window size on desktop platforms
  if (!kIsWeb) {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Use window_manager if available, otherwise skip gracefully
      try {
        // Minimum 900×600 for desktop
        // (window_manager package would go here if added)
      } catch (_) {}
    }
  }

  runApp(
    ProviderScope(
      child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => const InternLinkApp(),
      ),
    ),
  );
}
