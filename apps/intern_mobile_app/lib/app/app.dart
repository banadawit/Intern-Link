import 'dart:io';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/utils/keys.dart';
import 'router/app_router.dart';
import 'desktop_layout.dart';

/// Responsive text scale — applied after DevicePreview so it works on all devices.
/// Phone (< 600px): 1.15
/// Small tablet (600–839px): 1.35
/// Large tablet / desktop (840px+): 1.55
double _responsiveTextScale(double screenWidth) {
  if (screenWidth >= 1200) return 1.50; // Full Desktop
  if (screenWidth >= 900)  return 1.40; // Large Tablet
  if (screenWidth >= 600)  return 1.30; // Small Tablet
  return 1.15; // Mobile
}

class InternLinkApp extends StatelessWidget {
  const InternLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      title: 'InternLink',
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: (context, child) {
        final app = DevicePreview.appBuilder(context, child);
        return _ResponsiveTextWrapper(child: app);
      },
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routerConfig: appRouter,
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark() : ThemeData.light();

    // Platform-specific font family
    String? fontFamily;
    if (!kIsWeb) {
      if (Platform.isWindows) fontFamily = 'Segoe UI';
      if (Platform.isMacOS)   fontFamily = '.AppleSystemUIFont';
      if (Platform.isLinux)   fontFamily = 'Ubuntu';
    }

    return ThemeData(
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0C8B83),
        brightness: brightness,
      ),
      useMaterial3: true,
      fontFamily: fontFamily,
      textTheme: _buildTextTheme(base.textTheme),
      // Desktop: tighter visual density
      visualDensity: isDesktop
          ? VisualDensity.compact
          : VisualDensity.adaptivePlatformDensity,
      // Scrollbar always visible on desktop
      scrollbarTheme: isDesktop
          ? const ScrollbarThemeData(
              thumbVisibility: WidgetStatePropertyAll(true),
              thickness: WidgetStatePropertyAll(6),
            )
          : null,
      // Card theme
      cardTheme: CardThemeData(
        elevation: isDark ? 0 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
      ),
      // AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : const Color(0xFF1A1A2E),
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      // Filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }

  TextTheme _buildTextTheme(TextTheme base) {
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
