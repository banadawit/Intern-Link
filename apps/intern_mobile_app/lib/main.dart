import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

void main() {
  runApp(
    ProviderScope(
      child: DevicePreview(
        enabled: !kReleaseMode,
        builder: (context) => const InternLinkApp(),
      ),Implemented. I built a production-style app entry flow in Flutter with Riverpod + GoRouter, aligned to your existing backend auth conventions and role names from web.
    ),
  );
}
