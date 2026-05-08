import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/evaluation_repository.dart';
import 'dashboards.dart';

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
          onRefresh: () async => ref.invalidate(myEvaluationProvider),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              ModernSliverAppBar(
                title: 'Evaluations',
                subtitle: 'Final grading & feedback',
                profileName: 'Student',
                gradient: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                backgroundIcon: Icons.star_rounded,
              ),
              evalAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      Text('Failed to load evaluation', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(e.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => ref.invalidate(myEvaluationProvider),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ]),
                  ),
                ),
                data: (evaluation) => SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      evaluation == null
                          ? [_buildPendingState(context, isDark)]
                          : [
                              _buildOverallGradeCard(context, isDark, evaluation),
                              const SizedBox(height: 32),
                              _buildSectionHeader(theme, 'Skill Breakdown'),
                              const SizedBox(height: 16),
                              _buildSkillProgress(context, 'Technical Competence',
                                  (evaluation.technicalScore / 100).clamp(0.0, 1.0), Colors.blue),
                              _buildSkillProgress(context, 'Soft Skills & Teamwork',
                                  (evaluation.softSkillScore / 100).clamp(0.0, 1.0), Colors.orange),
                              const SizedBox(height: 32),
                              _buildSectionHeader(theme, 'Supervisor Remarks'),
                              const SizedBox(height: 16),
                              _buildRemarksCard(
                                context,
                                isDark,
                                evaluation.supervisorName,
                                evaluation.companyName,
                                evaluation.comments.isNotEmpty
                                    ? evaluation.comments
                                    : 'No remarks provided.',
                              ),
                              const SizedBox(height: 16),
                              _buildEvaluatedAtChip(evaluation.evaluatedAt, isDark),
                            ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingState(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.hourglass_top_rounded, size: 64, color: Colors.amber.withOpacity(0.6)),
        const SizedBox(height: 20),
        const Text('Evaluation Pending', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Text(
          'Your supervisor has not submitted your final evaluation yet. Check back after your internship is complete.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, height: 1.5),
        ),
      ]),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.5),
    );
  }

  Widget _buildOverallGradeCard(BuildContext context, bool isDark, FinalEvaluation eval) {
    final overall = eval.overallScore;
    // Convert 0-100 scale to 0-5 stars
    final stars = (overall / 20).clamp(0.0, 5.0);
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(children: [
        const Text('OVERALL SCORE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(overall.toStringAsFixed(1), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, height: 1)),
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text('/ 100', style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) {
          return Icon(
            i < stars.floor() ? Icons.star_rounded : (i < stars ? Icons.star_half_rounded : Icons.star_outline_rounded),
            color: const Color(0xFFF59E0B),
            size: 32,
          );
        })),
        const SizedBox(height: 12),
        Text('Evaluated by ${eval.supervisorName} · ${eval.companyName}',
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }

  Widget _buildSkillProgress(BuildContext context, String label, double progress, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }

  Widget _buildRemarksCard(BuildContext context, bool isDark, String name, String company, String text) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Text(name.isNotEmpty ? name[0] : '?', style: const TextStyle(color: Colors.blue)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
            Text(company, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
        ]),
        const SizedBox(height: 20),
        Text(text, style: TextStyle(
          fontSize: 15, height: 1.6,
          color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
          fontStyle: FontStyle.italic,
        )),
      ]),
    );
  }

  Widget _buildEvaluatedAtChip(DateTime date, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Evaluated on ${date.day}/${date.month}/${date.year}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }
}
