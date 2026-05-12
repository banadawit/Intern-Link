import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/session_service.dart';
import '../../features/app_entry/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/force_change_password_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/pending_review_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/auth/presentation/screens/verify_email_screen.dart';
import '../../features/dashboard/presentation/screens/dashboards.dart';
import '../../features/dashboard/presentation/screens/reports_screen.dart';
import '../../features/dashboard/presentation/screens/evaluations_screen.dart';
import '../../features/feed/presentation/common_feed_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/settings/presentation/screens/account_settings_screen.dart';
import '../../features/support/presentation/screens/support_screen.dart';
import '../../features/universal/presentation/screens/universal_screens.dart' hide CommonFeedScreen;
import '../../core/utils/keys.dart';
import 'app_routes.dart';

const Set<String> _protectedRoutes = {
  AppRoutes.studentDashboard,
  AppRoutes.supervisorDashboard,
  AppRoutes.coordinatorDashboard,
  AppRoutes.hodDashboard,
  AppRoutes.adminDashboard,
  AppRoutes.commonFeed,
  AppRoutes.notifications,
  AppRoutes.chat,
  AppRoutes.aiAssistant,
  AppRoutes.helpSupport,
  AppRoutes.accountSettings,
  AppRoutes.reports,
  AppRoutes.evaluations,
};

// Centralized Role-Route Access Map (Security Fix: Broken Access Control)
const Map<String, String> _routePrefixToRole = {
  AppRoutes.adminDashboard: 'ADMIN',
  AppRoutes.hodDashboard: 'HEAD_OF_DEPARTMENT',
  AppRoutes.coordinatorDashboard: 'COORDINATOR',
  AppRoutes.supervisorDashboard: 'SUPERVISOR',
  AppRoutes.studentDashboard: 'STUDENT',
};

String _getDashboardForRole(String role) {
  switch (role.toUpperCase()) {
    case 'ADMIN':
      return AppRoutes.adminDashboard;
    case 'HEAD_OF_DEPARTMENT':
    case 'HEAD OF DEPARTMENT':
    case 'HOD':
      return AppRoutes.hodDashboard;
    case 'COORDINATOR':
      return AppRoutes.coordinatorDashboard;
    case 'SUPERVISOR':
      return AppRoutes.supervisorDashboard;
    case 'STUDENT':
      return AppRoutes.studentDashboard;
    default:
      return AppRoutes.auth;
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  redirect: (context, state) async {
    final location = state.uri.path;
    if (!_protectedRoutes.contains(location)) {
      return null;
    }

    try {
      final session = AppSessionService();
      final token = await session.getToken();
      if (token == null || token.isEmpty) {
        return AppRoutes.auth;
      }

      final role = await session.getRole();

      // Handle Invalid State: Token exists but role is missing or unknown
      if (role == null || role.isEmpty) {
        await session.clearSession();
        return AppRoutes.auth;
      }

      final normalizedRole = role.toUpperCase() == 'HOD' ? 'HEAD_OF_DEPARTMENT' : role.toUpperCase();

      // Enforce Access Control: Validate requested route against user role
      String? targetRole;
      for (final prefix in _routePrefixToRole.keys) {
        if (location.startsWith(prefix)) {
          targetRole = _routePrefixToRole[prefix];
          break;
        }
      }

      if (targetRole != null && targetRole != normalizedRole) {
        // Access Denied: Cross-role navigation attempt detected
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to access this page.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Redirect safely to the user's correct dashboard
        return _getDashboardForRole(normalizedRole);
      }

      return null;
    } catch (_) {
      return AppRoutes.auth;
    }
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.auth,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          final slide =
              Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const RegisterScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final slide =
              Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const ForgotPasswordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final fade = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          );
          return FadeTransition(opacity: fade, child: child);
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.verifyEmail,
      pageBuilder: (context, state) {
        final email = state.uri.queryParameters['email'];
        final role = state.uri.queryParameters['role'];
        final token = state.uri.queryParameters['token'];
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: VerifyEmailScreen(
            email: email,
            role: role,
            initialToken: token,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(opacity: fade, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.verifyEmail}/:token',
      pageBuilder: (context, state) {
        final email = state.uri.queryParameters['email'];
        final role = state.uri.queryParameters['role'];
        final token = state.pathParameters['token'];
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: VerifyEmailScreen(
            email: email,
            role: role,
            initialToken: token,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(opacity: fade, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      pageBuilder: (context, state) {
        final token = state.uri.queryParameters['token'];
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: ResetPasswordScreen(initialToken: token),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(opacity: fade, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: '${AppRoutes.resetPassword}/:token',
      pageBuilder: (context, state) {
        final token = state.pathParameters['token'];
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: ResetPasswordScreen(initialToken: token),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(opacity: fade, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.pendingReview,
      pageBuilder: (context, state) {
        final message = state.uri.queryParameters['message'];
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: PendingReviewScreen(message: message),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(animation);
            final fade = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            );
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.studentDashboard,
      builder: (context, state) => const StudentDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.forceChangePassword,
      builder: (context, state) {
        final nextRoute = state.uri.queryParameters['next'] ?? AppRoutes.hodDashboard;
        return ForceChangePasswordScreen(nextRoute: nextRoute);
      },
    ),
    GoRoute(
      path: AppRoutes.supervisorDashboard,
      builder: (context, state) => const SupervisorDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.coordinatorDashboard,
      builder: (context, state) => const CoordinatorDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.adminDashboard,
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.hodDashboard,
      builder: (context, state) => const HodDashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.commonFeed,
      builder: (context, state) => const CommonFeedScreen(),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      builder: (context, state) => const ChatScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiAssistant,
      builder: (context, state) => const AiAssistantScreen(),
    ),
    GoRoute(
      path: AppRoutes.helpSupport,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const HelpSupportScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.accountSettings,
      pageBuilder: (context, state) {
        final section = state.uri.queryParameters['section'] ?? 'profile';
        return CustomTransitionPage<void>(
          key: state.pageKey,
          child: AccountSettingsScreen(initialSection: section),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      },
    ),
    GoRoute(
      path: AppRoutes.reports,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const ReportsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.evaluations,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        child: const EvaluationsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
  ],
);
