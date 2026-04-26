class PlanDescriptionCodec {
  static const _titlePrefix = 'Title:';
  static const _objectivesPrefix = 'Objectives:';
  static const _tasksPrefix = 'Tasks:';

  static String encode({
    required String title,
    required String objectives,
    required List<String> tasks,
  }) {
    final safeTasks = tasks.map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
    final taskLines = safeTasks.map((t) => '- $t').join('\n');
    return [
      '$_titlePrefix ${title.trim()}',
      '$_objectivesPrefix',
      objectives.trim(),
      '$_tasksPrefix',
      taskLines,
    ].where((s) => s.trim().isNotEmpty).join('\n');
  }

  static ({String title, String objectives, List<String> tasks}) decode(String raw) {
    final text = raw.trim();
    if (text.isEmpty) {
      return (title: 'Weekly Plan', objectives: '', tasks: const []);
    }

    // Try structured decode first.
    final lines = text.split('\n');
    String? title;
    final objectivesLines = <String>[];
    final tasks = <String>[];

    var mode = 'none'; // none | objectives | tasks
    for (final line in lines) {
      final l = line.trim();
      if (l.startsWith(_titlePrefix)) {
        title = l.substring(_titlePrefix.length).trim();
        mode = 'none';
        continue;
      }
      if (l == _objectivesPrefix) {
        mode = 'objectives';
        continue;
      }
      if (l == _tasksPrefix) {
        mode = 'tasks';
        continue;
      }

      if (mode == 'tasks') {
        final task = l.startsWith('-') ? l.substring(1).trim() : l;
        if (task.isNotEmpty) tasks.add(task);
      } else if (mode == 'objectives') {
        objectivesLines.add(line);
      }
    }

    // Fallback: if not structured, treat first non-empty line as title and rest as objectives.
    if (title == null || title.trim().isEmpty) {
      final first = lines.firstWhere((e) => e.trim().isNotEmpty, orElse: () => 'Weekly Plan');
      title = first.trim();
      final rest = lines.skipWhile((e) => e.trim().isEmpty).skip(1).join('\n').trim();
      return (title: title, objectives: rest, tasks: const []);
    }

    return (
      title: title,
      objectives: objectivesLines.join('\n').trim(),
      tasks: tasks,
    );
  }
}

