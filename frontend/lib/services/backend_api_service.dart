import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../data/models/progress_summary.dart';
import '../data/models/subject_item.dart';
import '../models/app_alert.dart';
import '../models/student_task.dart';
import '../models/study_block.dart';

class BackendApiService {
  BackendApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<String> login({required String email, required String password}) async {
    final data = await _client.post('/auth/login', body: {
      'email': email,
      'password': password,
    });
    return data['access_token'] as String;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await _client.post('/auth/register', body: {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<String> fetchUserName(String token) async {
    final data = await _client.get('/auth/me', token: token);
    return (data['name'] as String?) ?? 'Student';
  }

  Future<List<SubjectItem>> getSubjects(String token) async {
    final data = await _client.get('/subjects', token: token);
    final list = (data['data'] as List<dynamic>? ?? const <dynamic>[]);
    return list
        .map((item) => SubjectItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SubjectItem> createSubject(String token, String name) async {
    final data = await _client.post('/subjects', token: token, body: {'name': name});
    return SubjectItem.fromJson(data);
  }

  Future<List<StudentTask>> getTasks(
    String token,
    List<SubjectItem> subjects,
  ) async {
    final data = await _client.get('/tasks', token: token, query: {
      'page': '1',
      'page_size': '100',
    });
    final items = (data['items'] as List<dynamic>? ?? const <dynamic>[]);
    final subjectMap = {for (final subject in subjects) subject.id: subject.name};

    return items
        .map((item) {
      final json = item as Map<String, dynamic>;
      final rawId = json['id'];
      final id = rawId == null ? '' : rawId.toString();
      final priority = switch (json['priority'] as String? ?? 'Medium') {
        'High' => TaskPriority.high,
        'Low' => TaskPriority.low,
        _ => TaskPriority.medium,
      };
      return StudentTask(
        id: id,
        title: json['title'] as String,
        subject: subjectMap[json['subject_id'] as int] ?? 'General',
        deadline: DateTime.parse(json['deadline'] as String),
        priority: priority,
        isCompleted: (json['status'] as String? ?? 'Pending') == 'Completed',
      );
    })
        .where((task) => task.id.isNotEmpty)
        .toList();
  }

  Future<void> addTask({
    required String token,
    required int subjectId,
    required String title,
    required DateTime deadline,
    required TaskPriority priority,
  }) async {
    final apiPriority = switch (priority) {
      TaskPriority.high => 'High',
      TaskPriority.low => 'Low',
      TaskPriority.medium => 'Medium',
    };

    await _client.post('/tasks', token: token, body: {
      'title': title,
      'description': '',
      'subject_id': subjectId,
      'priority': apiPriority,
      'deadline': deadline.toUtc().toIso8601String(),
    });
  }

  Future<void> completeTask(String token, String taskId) async {
    await _client.patch('/tasks/$taskId/complete', token: token);
  }

  Future<void> deleteTask(String token, String taskId) async {
    await _client.delete('/tasks/$taskId', token: token);
  }

  Future<List<StudyBlock>> getStudyPlans(
    String token,
    List<SubjectItem> subjects,
  ) async {
    final data = await _client.get('/study-plan', token: token);
    final list = (data['data'] as List<dynamic>? ?? const <dynamic>[]);
    final subjectMap = {for (final subject in subjects) subject.id: subject.name};

    return list.map((item) {
      final json = item as Map<String, dynamic>;
      final subjectName = subjectMap[json['subject_id'] as int] ?? 'General';
      final color = _subjectColor(subjectName);
      return StudyBlock(
        id: (json['id'] as int).toString(),
        subject: subjectName,
        start: DateTime.parse(json['start_time'] as String).toLocal(),
        end: DateTime.parse(json['end_time'] as String).toLocal(),
        color: color,
      );
    }).toList();
  }

  Future<void> addStudyPlan({
    required String token,
    required int subjectId,
    required DateTime start,
    required DateTime end,
  }) async {
    await _client.post('/study-plan', token: token, body: {
      'subject_id': subjectId,
      'start_time': start.toUtc().toIso8601String(),
      'end_time': end.toUtc().toIso8601String(),
      'date': start.toIso8601String().split('T').first,
    });
  }

  Future<ProgressSummary> getProgress(String token) async {
    final data = await _client.get('/progress', token: token);
    return ProgressSummary.fromJson(data);
  }

  Future<List<AppAlert>> getReminders(
    String token,
    List<SubjectItem> subjects,
  ) async {
    final data = await _client.get('/tasks/reminders', token: token);
    final dueToday = (data['due_today'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final next2Hours = (data['due_next_2_hours'] as List<dynamic>? ?? const <dynamic>[])
        .cast<Map<String, dynamic>>();
    final subjectMap = {for (final subject in subjects) subject.id: subject.name};

    final alerts = <AppAlert>[];

    for (final item in next2Hours) {
      final subjectName = subjectMap[item['subject_id'] as int] ?? 'General';
      alerts.add(
        AppAlert(
          title: 'Assignment due in 2 hours',
          subtitle: '${item['title']} · $subjectName',
          time: DateTime.parse(item['deadline'] as String).toLocal(),
          isUnread: true,
        ),
      );
    }

    for (final item in dueToday) {
      final subjectName = subjectMap[item['subject_id'] as int] ?? 'General';
      alerts.add(
        AppAlert(
          title: 'Due today reminder',
          subtitle: '${item['title']} · $subjectName',
          time: DateTime.parse(item['deadline'] as String).toLocal(),
          isUnread: false,
        ),
      );
    }

    return alerts;
  }

  Color _subjectColor(String subject) {
    return switch (subject.toLowerCase()) {
      'mathematics' => const Color(0xFF4F46E5),
      'physics' => const Color(0xFF8B5CF6),
      'computer science' => const Color(0xFF10B981),
      'chemistry' => const Color(0xFFF59E0B),
      _ => const Color(0xFF4F46E5),
    };
  }
}
