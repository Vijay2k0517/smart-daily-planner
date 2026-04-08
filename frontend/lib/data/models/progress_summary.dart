class ProgressSummary {
  const ProgressSummary({
    required this.completedTasks,
    required this.totalTasks,
    required this.completionPercentage,
    required this.studyHours,
  });

  final int completedTasks;
  final int totalTasks;
  final double completionPercentage;
  final double studyHours;

  factory ProgressSummary.fromJson(Map<String, dynamic> json) {
    return ProgressSummary(
      completedTasks: (json['completed_tasks'] as num?)?.toInt() ?? 0,
      totalTasks: (json['total_tasks'] as num?)?.toInt() ?? 0,
      completionPercentage: (json['completion_percentage'] as num?)?.toDouble() ?? 0,
      studyHours: (json['study_hours'] as num?)?.toDouble() ?? 0,
    );
  }
}
