import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/student_task.dart';
import 'glass_card.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  final StudentTask task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  Color _priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return const Color(0xFFEF4444);
      case TaskPriority.medium:
        return const Color(0xFFF59E0B);
      case TaskPriority.low:
        return const Color(0xFF10B981);
    }
  }

  String _priorityLabel(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = DateFormat('EEE, h:mm a').format(task.deadline);

    return Hero(
      tag: 'task-${task.id}',
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          child: Row(
            children: [
              Container(
                width: 4,
                height: 58,
                decoration: BoxDecoration(
                  color: _priorityColor(task.priority),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  decoration:
                                      task.isCompleted ? TextDecoration.lineThrough : null,
                                ),
                          ),
                        ),
                        if (task.priority == TaskPriority.high)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            ),
                            child: const Text('🔥'),
                          ),
                        if (onComplete != null)
                          IconButton(
                            tooltip: task.isCompleted ? 'Completed' : 'Mark complete',
                            onPressed: task.isCompleted ? null : onComplete,
                            icon: Icon(
                              task.isCompleted
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              color: task.isCompleted
                                  ? const Color(0xFF10B981)
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        if (onDelete != null)
                          IconButton(
                            tooltip: 'Delete task',
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(task.subject),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(deadlineLabel),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: _priorityColor(task.priority).withValues(alpha: 0.12),
                          ),
                          child: Text(
                            _priorityLabel(task.priority),
                            style: TextStyle(
                              fontSize: 12,
                              color: _priorityColor(task.priority),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
