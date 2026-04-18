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

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();

  static const List<_OnboardingPageData> _pages = [
    _OnboardingPageData(
      title: 'Welcome to InternLink',
      description:
          'Track your internship journey, collaborate with supervisors, and stay aligned with your institution in one place.',
      icon: Icons.rocket_launch_rounded,
      accent: Color(0xFF0B8A83),
    ),
    _OnboardingPageData(
      title: 'How The Workflow Works',
      description:
          'Plan weekly goals, submit progress updates, and receive structured feedback from your supervisors.',
      icon: Icons.account_tree_rounded,
      accent: Color(0xFF2E8BC0),
    ),
    _OnboardingPageData(
      title: 'Built For Every Role',
      description:
          'Students manage tasks, supervisors guide progress, and coordinators monitor outcomes across teams.',
      icon: Icons.groups_rounded,
      accent: Color(0xFF4B7A47),
    ),
    _OnboardingPageData(
      title: 'Ready To Get Started?',
      description:
          'Set up your session and continue to secure sign in to start using InternLink.',
      icon: Icons.check_circle_rounded,
      accent: Color(0xFF6C63FF),
    ),
  ];

  int _currentPage = 0;
  bool _isSubmitting = false;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  Future<void> _onNextPressed() async {
    if (_isLastPage) {
      await _completeOnboarding();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onSkipPressed() async {
    if (_isLastPage) {
      return;
    }

    await _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 380),
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
      if (!mounted) {
        return;
      }
      context.go(AppRoutes.auth);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to continue right now. Please try again.'),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundGradient = isDark
        ? const [Color(0xFF0D1720), Color(0xFF152533)]
        : const [Color(0xFFF2FAFD), Color(0xFFFFFFFF)];

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundGradient,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380
                  ? 20.0
                  : 28.0;
              final topSpacing = constraints.maxHeight < 700 ? 18.0 : 26.0;

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    SizedBox(height: topSpacing),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLastPage || _isSubmitting
                            ? null
                            : _onSkipPressed,
                        child: const Text('Skip'),
                      ),
                    ),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (value) {
                          setState(() {
                            _currentPage = value;
                          });
                        },
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          final isActive = index == _currentPage;
                          return _OnboardingPage(
                            data: page,
                            isActive: isActive,
                          );
                        },
                      ),
                    ),
                    _DotsIndicator(
                      count: _pages.length,
                      currentIndex: _currentPage,
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isSubmitting ? null : _onNextPressed,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              )
                            : Text(_isLastPage ? 'Get Started' : 'Next'),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.isActive});

  final _OnboardingPageData data;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSlide(
      offset: isActive ? Offset.zero : const Offset(0.08, 0),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isActive ? 1 : 0.65,
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    data.accent.withValues(alpha: 0.22),
                    data.accent.withValues(alpha: 0.08),
                  ],
                ),
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
                  child: Icon(data.icon, size: 84, color: data.accent),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ],
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
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: selected ? 24 : 8,
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(99),
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
  });

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
}
