import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';

class PendingReviewScreen extends StatelessWidget {
  const PendingReviewScreen({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = (message?.trim().isNotEmpty ?? false)
        ? message!.trim()
        : 'Your account is pending institutional approval. You will receive an email update once reviewed.';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 46,
                    color: Color(0xFFB54708),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Verification Pending',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.auth),
                  child: const Text('Back To Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
