import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboards.dart'; // To reuse ModernSliverAppBar and other widgets

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              isDark ? const Color(0xFF0F172A) : Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            ModernSliverAppBar(
              title: 'Reports',
              subtitle: 'Performance tracking',
              profileName: 'User',
              gradient: [const Color(0xFF6366F1), const Color(0xFFA855F7)],
              backgroundIcon: Icons.analytics_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader(theme, 'Final Report Status'),
                  const SizedBox(height: 16),
                  _buildReportStatusCard(
                    context,
                    'Internship Completion Report',
                    'Generated on Oct 12, 2023',
                    'APPROVED & STAMPED',
                    Icons.verified_user_rounded,
                    Colors.green,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionHeader(theme, 'Weekly Progress Logs'),
                  const SizedBox(height: 16),
                  _buildWeeklyReportItem(context, 'Week 12: System Integration', 'Oct 20 - Oct 25', 'Approved', Colors.blue),
                  _buildWeeklyReportItem(context, 'Week 11: Backend Refactor', 'Oct 13 - Oct 18', 'Approved', Colors.blue),
                  _buildWeeklyReportItem(context, 'Week 10: API Security', 'Oct 06 - Oct 11', 'Approved', Colors.blue),
                  _buildWeeklyReportItem(context, 'Week 9: UI Polish', 'Sep 29 - Oct 04', 'Rejected', Colors.red, feedback: 'Please add more screenshots.'),
                  const SizedBox(height: 40),
                  _buildActionCard(
                    context,
                    Icons.file_download_rounded,
                    'Download Final PDF',
                    'Save your stamped completion report',
                    Colors.indigo,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildReportStatusCard(BuildContext context, String title, String subtitle, String status, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                status,
                style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyReportItem(BuildContext context, String title, String date, String status, Color color, {String? feedback}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(date, style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (feedback != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feedback,
                      style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, String subtitle, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withBlue(255).withRed(100)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }
}
