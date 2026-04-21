import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              isDark ? const Color(0xFF1E293B) : Colors.white,
            ],
          ),
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, isDark),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionTitle('Quick Assistance', theme),
                  const SizedBox(height: 16),
                  _buildQuickHelpGrid(context),
                  const SizedBox(height: 40),
                  _buildSectionTitle('Frequently Asked Questions', theme),
                  const SizedBox(height: 16),
                  _buildFAQList(),
                  const SizedBox(height: 40),
                  _buildSectionTitle('Still need help?', theme),
                  const SizedBox(height: 16),
                  _buildContactCard(context, isDark),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                bottom: -40,
                child: Icon(Icons.support_agent_rounded, size: 200, color: Colors.white.withOpacity(0.1)),
              ),
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    Text('Support Center', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                    Text('How can we help you today?', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
    );
  }

  Widget _buildQuickHelpGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildHelpCard(context, 'AI Assistant', 'Instant AI help', Icons.auto_awesome_rounded, Colors.purple, () => context.push(AppRoutes.aiAssistant)),
        _buildHelpCard(context, 'Guides', 'Step-by-step', Icons.menu_book_rounded, Colors.orange, () {}),
        _buildHelpCard(context, 'Technical', 'Report a bug', Icons.bug_report_rounded, Colors.red, () {}),
        _buildHelpCard(context, 'Account', 'Privacy & Security', Icons.security_rounded, Colors.blue, () {}),
      ],
    );
  }

  Widget _buildHelpCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05)),
            boxShadow: [if (!isDark) BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 20)),
              const Spacer(),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQList() {
    return Column(
      children: [
        _buildFAQItem('How do I submit my weekly plan?', 'Navigate to the Plans tab, click the "+" button, and fill in your objectives and tasks.'),
        _buildFAQItem('How are internships assigned?', 'The Coordinator reviews your university letter and pairs you with a suitable company.'),
        _buildFAQItem('Can I change my supervisor?', 'Supervisor changes must be requested through your university coordinator.'),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        children: [Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), child: Text(answer, style: const TextStyle(color: Colors.grey, fontSize: 13)))],
        shape: const RoundedRectangleBorder(side: BorderSide.none),
      ),
    );
  }

  Widget _buildContactCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [const Color(0xFF2193b0).withOpacity(0.1), const Color(0xFF6dd5ed).withOpacity(0.1)]),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF2193b0).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text('Connect with our team', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text('We usually respond within 2 hours', style: TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _contactButton(Icons.mail_outline_rounded, 'Email', () {}),
              const SizedBox(width: 16),
              _contactButton(Icons.chat_outlined, 'WhatsApp', () {}),
              const SizedBox(width: 16),
              _contactButton(Icons.phone_outlined, 'Call', () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contactButton(IconData icon, String label, VoidCallback onTap) {
    return Column(
      children: [
        IconButton.filledTonal(onPressed: onTap, icon: Icon(icon)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
