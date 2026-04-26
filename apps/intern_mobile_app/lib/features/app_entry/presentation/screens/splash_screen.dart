import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../domain/entities/app_start_destination.dart';
import '../providers/app_entry_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  bool _didRoute = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    unawaited(_startFlow());
  }

  Future<void> _startFlow() async {
    final decisionFuture = ref.read(appStartDecisionProvider.future);
    final animationFuture = _controller.forward();

    final decision = await decisionFuture;
    await animationFuture;

    if (!mounted || _didRoute) {
      return;
    }

    _didRoute = true;
    context.go(_toRoute(decision.destination));
  }

  String _toRoute(AppStartDestination destination) {
    switch (destination) {
      case AppStartDestination.onboarding:
        return AppRoutes.onboarding;
      case AppStartDestination.auth:
        return AppRoutes.auth;
      case AppStartDestination.studentDashboard:
        return AppRoutes.studentDashboard;
      case AppStartDestination.supervisorDashboard:
        return AppRoutes.supervisorDashboard;
      case AppStartDestination.coordinatorDashboard:
        return AppRoutes.coordinatorDashboard;
      case AppStartDestination.adminDashboard:
        return AppRoutes.adminDashboard;
      case AppStartDestination.hodDashboard:
        return AppRoutes.hodDashboard;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    final isDark = brightness == Brightness.dark;

    final startState = ref.watch(appStartDecisionProvider);
    final isValidating = startState.isLoading;

    final backgroundColors = isDark
        ? <Color>[const Color(0xFF0A1F2C), const Color(0xFF162B3A)]
        : <Color>[const Color(0xFFEAF4F9), const Color(0xFFF8FBFD)];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundColors,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        child: Icon(
                          Icons.school_rounded,
                          size: 56,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'InternLink',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedOpacity(
                opacity: isValidating ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
