enum TaskPriority { high, medium, low }

enum TaskFilter { today, upcoming, completed }

class StudentTask {
  StudentTask({
    required this.id,
    required this.title,
    required this.subject,
    required this.deadline,
    required this.priority,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String subject;
  final DateTime deadline;
  final TaskPriority priority;
  final bool isCompleted;

  StudentTask copyWith({
    String? id,
    String? title,
    String? subject,
    DateTime? deadline,
    TaskPriority? priority,
    bool? isCompleted,
  }) {
    return StudentTask(
      id: id ?? this.id,
      title: title ?? this.title,
      subject: subject ?? this.subject,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
