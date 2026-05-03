import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/repositories/evaluation_repository.dart';
import '../../../../features/dashboard/data/repositories/progress_repository.dart';
import 'dashboards.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final plansAsync = ref.watch(myWeeklyPlansProvider);
    final evalAsync = ref.watch(myEvaluationProvider);

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
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myWeeklyPlansProvider);
            ref.invalidate(myEvaluationProvider);
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ModernSliverAppBar(
                title: 'Reports',
                subtitle: 'Performance tracking',
                profileName: 'Student',
                gradient: const [Color(0xFF6366F1), Color(0xFFA855F7)],
                backgroundIcon: Icons.analytics_rounded,
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Final Report Status ──────────────────────────────────
                    _buildSectionHeader(theme, 'Final Report Status'),
                    const SizedBox(height: 16),
                    evalAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => _buildReportStatusCard(
                        context, isDark,
                        title: 'Internship Completion Report',
                        subtitle: 'Could not load report status',
                        status: 'UNAVAILABLE',
                        color: Colors.grey,
                        pdfUrl: null,
                      ),
                      data: (eval) => _buildReportStatusCard(
                        context, isDark,
                        title: 'Internship Completion Report',
                        subtitle: eval != null
                            ? 'Evaluated by ${eval.supervisorName}'
                            : 'Awaiting supervisor evaluation',
                        status: eval != null ? 'EVALUATION COMPLETE' : 'PENDING EVALUATION',
                        color: eval != null ? Colors.green : Colors.orange,
                        pdfUrl: null, // PDF URL would come from a separate report endpoint
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Weekly Progress Logs ─────────────────────────────────
                    _buildSectionHeader(theme, 'Weekly Progress Logs'),
                    const SizedBox(height: 16),
                    plansAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text('Failed to load plans: $e', style: const TextStyle(color: Colors.red)),
                      ),
                      data: (plans) {
                        if (plans.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Center(
                              child: Column(children: [
                                Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No weekly plans submitted yet.', style: TextStyle(color: Colors.grey)),
                              ]),
                            ),
                          );
                        }
                        // Sort by week number descending
                        final sorted = [...plans]..sort((a, b) => b.weekNumber.compareTo(a.weekNumber));
                        return Column(
                          children: sorted.map((plan) {
                            final statusColor = plan.status.name == 'approved'
                                ? Colors.green
                                : plan.status.name == 'rejected'
                                    ? Colors.red
                                    : Colors.orange;
                            final statusLabel = plan.status.name.toUpperCase();
                            final desc = plan.title.isNotEmpty ? plan.title : plan.objectives;
                            return _buildWeeklyReportItem(
                              context, isDark,
                              title: 'Week ${plan.weekNumber}: ${desc.length > 40 ? '${desc.substring(0, 40)}…' : desc}',
                              submittedAt: plan.createdAt,
                              status: statusLabel,
                              color: statusColor,
                              feedback: plan.status.name == 'rejected' ? plan.feedback : null,
                              checkinCount: plan.checkins.length,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
    );
  }

  Widget _buildReportStatusCard(
    BuildContext context,
    bool isDark, {
    required String title,
    required String subtitle,
    required String status,
    required Color color,
    String? pdfUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.verified_user_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
          child: Center(child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2))),
        ),
        if (pdfUrl != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final uri = Uri.tryParse(pdfUrl);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.file_download_rounded),
              label: const Text('Download PDF'),
              style: FilledButton.styleFrom(backgroundColor: color),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildWeeklyReportItem(
    BuildContext context,
    bool isDark, {
    required String title,
    required DateTime submittedAt,
    required String status,
    required Color color,
    String? feedback,
    int checkinCount = 0,
  }) {
    final dateStr = '${submittedAt.day.toString().padLeft(2, '0')}/${submittedAt.month.toString().padLeft(2, '0')}/${submittedAt.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Row(children: [
              Text('Submitted $dateStr', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              if (checkinCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('$checkinCount check-ins', style: const TextStyle(color: Colors.teal, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ]),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]),
        if (feedback != null && feedback.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.1)),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(feedback, style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic))),
            ]),
          ),
        ],
      ]),
    );
  }
}
