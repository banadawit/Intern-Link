import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'router/app_router.dart';

/// Responsive text scale — applied after DevicePreview so it works on all devices.
/// Phone (< 600px): 1.15  — slightly larger than default
/// Small tablet (600–839px): 1.35
/// Large tablet / desktop (840px+): 1.55
double _responsiveTextScale(double screenWidth) {
  if (screenWidth >= 840) return 1.55;
  if (screenWidth >= 600) return 1.35;
  return 1.15;
}

class InternLinkApp extends StatelessWidget {
  const InternLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'InternLink',
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        // 1. Apply DevicePreview wrapper
        Widget app = DevicePreview.appBuilder(context, child) ?? const SizedBox.shrink();
        // 2. Inject responsive text scaling on top of whatever DevicePreview set
        return _ResponsiveTextWrapper(child: app);
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C8B83)),
        useMaterial3: true,
        textTheme: _buildTextTheme(false),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0C8B83),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: _buildTextTheme(true),
      ),
      routerConfig: appRouter,
    );
  }

  TextTheme _buildTextTheme(bool dark) {
    final base = dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    return base.copyWith(
      bodySmall:      base.bodySmall?.copyWith(fontSize: 13),
      bodyMedium:     base.bodyMedium?.copyWith(fontSize: 15),
      bodyLarge:      base.bodyLarge?.copyWith(fontSize: 17),
      labelSmall:     base.labelSmall?.copyWith(fontSize: 12),
      labelMedium:    base.labelMedium?.copyWith(fontSize: 13),
      labelLarge:     base.labelLarge?.copyWith(fontSize: 15),
      titleSmall:     base.titleSmall?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      titleMedium:    base.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
      titleLarge:     base.titleLarge?.copyWith(fontSize: 21, fontWeight: FontWeight.w700),
      headlineSmall:  base.headlineSmall?.copyWith(fontSize: 23, fontWeight: FontWeight.w800),
      headlineMedium: base.headlineMedium?.copyWith(fontSize: 27, fontWeight: FontWeight.w800),
      headlineLarge:  base.headlineLarge?.copyWith(fontSize: 32, fontWeight: FontWeight.w900),
      displaySmall:   base.displaySmall?.copyWith(fontSize: 36, fontWeight: FontWeight.w900),
      displayMedium:  base.displayMedium?.copyWith(fontSize: 42, fontWeight: FontWeight.w900),
      displayLarge:   base.displayLarge?.copyWith(fontSize: 50, fontWeight: FontWeight.w900),
    );
  }
}

/// Wraps the app and overrides MediaQuery.textScaler based on actual screen width.
/// Must be a StatelessWidget so it rebuilds when the window is resized.
class _ResponsiveTextWrapper extends StatelessWidget {
  const _ResponsiveTextWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final scale = _responsiveTextScale(width);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(scale),
      ),
      child: child,
    );
  }
}
