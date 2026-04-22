import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboards.dart';

class EvaluationsScreen extends ConsumerWidget {
  const EvaluationsScreen({super.key});

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
              title: 'Evaluations',
              subtitle: 'Final grading & feedback',
              profileName: 'User',
              gradient: [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
              backgroundIcon: Icons.star_rounded,
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildOverallGradeCard(context, 4.8),
                  const SizedBox(height: 32),
                  _buildSectionHeader(theme, 'Skill Breakdown'),
                  const SizedBox(height: 16),
                  _buildSkillProgress(context, 'Technical Competence', 0.95, Colors.blue),
                  _buildSkillProgress(context, 'Soft Skills & Teamwork', 0.88, Colors.orange),
                  _buildSkillProgress(context, 'Punctuality & Reliability', 1.0, Colors.green),
                  _buildSkillProgress(context, 'Problem Solving', 0.82, Colors.purple),
                  const SizedBox(height: 32),
                  _buildSectionHeader(theme, 'Supervisor Remarks'),
                  const SizedBox(height: 16),
                  _buildRemarksCard(
                    context, 
                    'Abebe Kebede', 
                    'Senior Developer',
                    'Outstanding performance throughout the internship. Demonstrated strong initiative in the backend refactoring project and successfully integrated three new API services. Highly recommended for future full-stack roles.',
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

  Widget _buildOverallGradeCard(BuildContext context, double score) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          const Text('OVERALL RATING', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                score.toStringAsFixed(1),
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900, height: 1),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 12, left: 4),
                child: Text('/ 5.0', style: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < score.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                color: const Color(0xFFF59E0B),
                size: 32,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillProgress(BuildContext context, String label, double progress, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${(progress * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 8,
                width: MediaQuery.of(context).size.width * 0.8 * progress, // Simplified
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [color, color.withOpacity(0.6)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRemarksCard(BuildContext context, String name, String role, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: Colors.blue.withOpacity(0.1), child: Text(name[0], style: const TextStyle(color: Colors.blue))),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(role, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Opacity(opacity: 0.1, child: Icon(Icons.format_quote_rounded, size: 40, color: isDark ? Colors.white : Colors.black)),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 12),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
