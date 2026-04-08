import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student_task.dart';
import '../state/app_state.dart';
import '../widgets/task_card.dart';

class TaskManagerScreen extends ConsumerStatefulWidget {
  const TaskManagerScreen({super.key});

  @override
  ConsumerState<TaskManagerScreen> createState() => _TaskManagerScreenState();
}

class _TaskManagerScreenState extends ConsumerState<TaskManagerScreen> {
  TaskFilter filter = TaskFilter.today;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 600));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  List<StudentTask> _filtered(List<StudentTask> tasks) {
    final now = DateTime.now();
    switch (filter) {
      case TaskFilter.today:
        return tasks.where((task) {
          final sameDay = task.deadline.year == now.year &&
              task.deadline.month == now.month &&
              task.deadline.day == now.day;
          return sameDay && !task.isCompleted;
        }).toList();
      case TaskFilter.upcoming:
        return tasks.where((task) => task.deadline.isAfter(now) && !task.isCompleted).toList();
      case TaskFilter.completed:
        return tasks.where((task) => task.isCompleted).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final tasks = _filtered(state.tasks);

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<TaskFilter>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: TaskFilter.today, label: Text('Today')),
                    ButtonSegment(value: TaskFilter.upcoming, label: Text('Upcoming')),
                    ButtonSegment(value: TaskFilter.completed, label: Text('Completed')),
                  ],
                  selected: {filter},
                  onSelectionChanged: (selection) {
                    setState(() => filter = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4F46E5).withValues(alpha: 0.22),
                                    const Color(0xFF8B5CF6).withValues(alpha: 0.10),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                size: 62,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks in this filter',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Dismissible(
                            key: ValueKey(task.id),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 18),
                              child: const Icon(Icons.check_circle_outline, color: Colors.green),
                            ),
                            secondaryBackground: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 18),
                              child: const Icon(Icons.delete_outline, color: Colors.red),
                            ),
                            confirmDismiss: (direction) async {
                              if (direction == DismissDirection.startToEnd) {
                                await ref.read(appStateProvider.notifier).completeTask(task.id);
                                _confettiController.play();
                                return false;
                              }
                              await ref.read(appStateProvider.notifier).deleteTask(task.id);
                              return true;
                            },
                            child: TaskCard(
                              task: task,
                              onComplete: () async {
                                await ref.read(appStateProvider.notifier).completeTask(task.id);
                                _confettiController.play();
                              },
                              onDelete: () async {
                                await ref.read(appStateProvider.notifier).deleteTask(task.id);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 20,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }
}
