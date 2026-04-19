import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../app_entry/presentation/providers/app_entry_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late final AnimationController _bgAnimationController;

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to InternLink',
      description:
          'Track your internship journey, collaborate with supervisors, and stay aligned with your institution in one place.',
      icon: Icons.rocket_launch_rounded,
      accent: Color(0xFF00E5FF),
      gradientColors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
    ),
    _OnboardingPageData(
      title: 'Seamless Workflow',
      description:
          'Plan weekly goals, submit progress updates, and receive structured feedback effortlessly.',
      icon: Icons.auto_graph_rounded,
      accent: Color(0xFFFF4081),
      gradientColors: [Color(0xFFF12711), Color(0xFFF5AF19)],
    ),
    _OnboardingPageData(
      title: 'Unified Ecosystem',
      description:
          'Students manage tasks, supervisors guide progress, and coordinators monitor outcomes across teams.',
      icon: Icons.hub_rounded,
      accent: Color(0xFF00E676),
      gradientColors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    ),
    _OnboardingPageData(
      title: 'Ready To Get Started?',
      description:
          'Set up your session and securely sign in to experience the future of internship management.',
      icon: Icons.task_alt_rounded,
      accent: Color(0xFF7C4DFF),
      gradientColors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
    ),
  ];

  int _currentPage = 0;
  bool _isSubmitting = false;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  Future<void> _onNextPressed() async {
    if (_isLastPage) {
      await _completeOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onSkipPressed() async {
    if (_isLastPage) {
      return;
    }

    await _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _completeOnboarding() async {
    if (_isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(appSessionServiceProvider).setFirstLaunchCompleted();
      if (!mounted) return;
      context.go(AppRoutes.auth);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Unable to continue right now. Please try again.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageData = _pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // Dynamic Animated Background
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      Color.lerp(
                            pageData.gradientColors.last.withValues(alpha: isDark ? 0.2 : 0.1),
                            pageData.gradientColors.first.withValues(alpha: isDark ? 0.3 : 0.15),
                            _bgAnimationController.value,
                          ) ??
                          theme.colorScheme.surface,
                    ],
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo or Branding indicator
                      Row(
                        children: [
                          Icon(Icons.school_rounded, color: pageData.accent),
                          const SizedBox(width: 8),
                          Text(
                            'InternLink',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      AnimatedOpacity(
                        opacity: _isLastPage || _isSubmitting ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: TextButton(
                          onPressed: _isLastPage || _isSubmitting ? null : _onSkipPressed,
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          child: const Text('Skip', style: TextStyle(fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (value) => setState(() => _currentPage = value),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _OnboardingCard(
                        data: _pages[index],
                        isActive: index == _currentPage,
                        isDark: isDark,
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DotsIndicator(count: _pages.length, currentIndex: _currentPage),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _onNextPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  _isLastPage ? 'Get Started' : 'Continue',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.data,
    required this.isActive,
    required this.isDark,
  });

  final _OnboardingPageData data;
  final bool isActive;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedScale(
      scale: isActive ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isActive ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 400),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.gradientColors.first.withValues(alpha: isDark ? 0.15 : 0.08),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white.withValues(alpha: 0.6),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: data.gradientColors,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: data.gradientColors.first.withValues(alpha: 0.4),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            )
                          ],
                        ),
                        child: Icon(data.icon, size: 72, color: Colors.white),
                      ),
                      const SizedBox(height: 48),
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DotsIndicator extends StatelessWidget {
  const _DotsIndicator({required this.count, required this.currentIndex});

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          height: 8,
          width: selected ? 32 : 8,
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.icon,
    required this.accent,
    required this.gradientColors,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final List<Color> gradientColors;
}
