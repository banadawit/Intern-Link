import 'package:flutter/material.dart';

class StudentDashboardScreen extends StatelessWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardScaffold(
      title: 'Student Dashboard',
      roleLabel: 'STUDENT',
    );
  }
}

class SupervisorDashboardScreen extends StatelessWidget {
  const SupervisorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardScaffold(
      title: 'Supervisor Dashboard',
      roleLabel: 'SUPERVISOR',
    );
  }
}

class CoordinatorDashboardScreen extends StatelessWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardScaffold(
      title: 'Coordinator Dashboard',
      roleLabel: 'COORDINATOR',
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _DashboardScaffold(
      title: 'Admin Dashboard',
      roleLabel: 'ADMIN',
    );
  }
}

class _DashboardScaffold extends StatelessWidget {
  const _DashboardScaffold({required this.title, required this.roleLabel});

  final String title;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$roleLabel home screen',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
