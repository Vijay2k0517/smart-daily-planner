import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../data/models/progress_summary.dart';
import '../data/models/subject_item.dart';
import '../models/app_alert.dart';
import '../models/student_task.dart';
import '../models/study_block.dart';
import '../services/backend_api_service.dart';
import '../services/session_service.dart';

const _unset = Object();

class AppStateData {
  const AppStateData({
    required this.isDarkMode,
    required this.isLoading,
    required this.isAuthenticated,
    required this.selectedTab,
    required this.userName,
    required this.errorMessage,
    required this.subjects,
    required this.tasks,
    required this.studyBlocks,
    required this.alerts,
    required this.progress,
    required this.token,
  });

  final bool isDarkMode;
  final bool isLoading;
  final bool isAuthenticated;
  final int selectedTab;
  final String userName;
  final String? errorMessage;
  final List<SubjectItem> subjects;
  final List<StudentTask> tasks;
  final List<StudyBlock> studyBlocks;
  final List<AppAlert> alerts;
  final ProgressSummary progress;
  final String? token;

  AppStateData copyWith({
    bool? isDarkMode,
    bool? isLoading,
    bool? isAuthenticated,
    int? selectedTab,
    String? userName,
    String? errorMessage,
    List<SubjectItem>? subjects,
    List<StudentTask>? tasks,
    List<StudyBlock>? studyBlocks,
    List<AppAlert>? alerts,
    ProgressSummary? progress,
    Object? token = _unset,
    bool clearError = false,
  }) {
    return AppStateData(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      selectedTab: selectedTab ?? this.selectedTab,
      userName: userName ?? this.userName,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      subjects: subjects ?? this.subjects,
      tasks: tasks ?? this.tasks,
      studyBlocks: studyBlocks ?? this.studyBlocks,
      alerts: alerts ?? this.alerts,
      progress: progress ?? this.progress,
      token: identical(token, _unset) ? this.token : token as String?,
    );
  }

  double get dailyProductivity {
    if (tasks.isEmpty) {
      return 0;
    }
    final completed = tasks.where((task) => task.isCompleted).length;
    return completed / tasks.length;
  }

  int get tasksDueToday {
    final now = DateTime.now();
    return tasks.where((task) {
      return task.deadline.year == now.year &&
          task.deadline.month == now.month &&
          task.deadline.day == now.day &&
          !task.isCompleted;
    }).length;
  }

  double get studyHoursToday {
    final now = DateTime.now();
    final minutes = studyBlocks
        .where((block) =>
            block.start.year == now.year &&
            block.start.month == now.month &&
            block.start.day == now.day)
        .fold<int>(0, (sum, block) => sum + block.duration.inMinutes);
    return minutes / 60;
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppStateData>((ref) {
  return AppStateNotifier(
    AppStateData(
      isDarkMode: false,
      isLoading: false,
      isAuthenticated: false,
      selectedTab: 0,
      userName: 'Student',
      errorMessage: null,
      subjects: const [],
      tasks: const [],
      studyBlocks: const [],
      alerts: const [],
      progress: const ProgressSummary(
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        studyHours: 0,
      ),
      token: null,
    ),
  );
});

class AppStateNotifier extends StateNotifier<AppStateData> {
  AppStateNotifier(super.state) {
    _bootstrap();
  }

  final BackendApiService _api = BackendApiService();
  final SessionService _sessionService = SessionService();

  Future<void> _bootstrap() async {
    final token = await _sessionService.loadToken();
    if (token == null || token.isEmpty) {
      return;
    }

    state = state.copyWith(
      isAuthenticated: true,
      token: token,
      isLoading: true,
      clearError: true,
    );

    try {
      await refreshAll();
    } catch (_) {
      await logout();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final token = await _api.login(email: email, password: password);
      await _sessionService.saveToken(token);
      state = state.copyWith(isAuthenticated: true, token: token);
      await refreshAll();
      return true;
    } catch (e) {
      await _handleApiError(e, isLoading: false);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _api.register(name: name, email: email, password: password);
      return await login(email: email, password: password);
    } catch (e) {
      await _handleApiError(e, isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    await _sessionService.clearToken();
    state = state.copyWith(
      isAuthenticated: false,
      selectedTab: 0,
      userName: 'Student',
      subjects: const [],
      tasks: const [],
      studyBlocks: const [],
      alerts: const [],
      progress: const ProgressSummary(
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        studyHours: 0,
      ),
      token: null,
      isLoading: false,
      clearError: true,
    );
  }

  void toggleTheme() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void changeTab(int index) {
    state = state.copyWith(selectedTab: index);
  }

  Future<void> completeTask(String taskId) async {
    final token = state.token;
    if (token == null) {
      return;
    }
    try {
      await _api.completeTask(token, taskId);
      await refreshAll();
    } catch (e) {
      await _handleApiError(e);
    }
  }

  Future<void> deleteTask(String taskId) async {
    final token = state.token;
    if (token == null) {
      return;
    }
    try {
      await _api.deleteTask(token, taskId);
      await refreshAll();
    } catch (e) {
      await _handleApiError(e);
    }
  }

  Future<void> addTask({
    required String title,
    required String subject,
    required DateTime deadline,
    required TaskPriority priority,
  }) async {
    final token = state.token;
    if (token == null) {
      return;
    }

    try {
      final existing = state.subjects.where((item) => item.name == subject).toList();
      final subjectId = existing.isNotEmpty
          ? existing.first.id
          : (await _api.createSubject(token, subject)).id;

      await _api.addTask(
        token: token,
        subjectId: subjectId,
        title: title,
        deadline: deadline,
        priority: priority,
      );
      await refreshAll();
    } catch (e) {
      await _handleApiError(e);
    }
  }

  Future<void> addStudyBlock({
    required String subject,
    required DateTime start,
    required DateTime end,
  }) async {
    final token = state.token;
    if (token == null) {
      return;
    }

    try {
      final existing = state.subjects.where((item) => item.name == subject).toList();
      final subjectId = existing.isNotEmpty
          ? existing.first.id
          : (await _api.createSubject(token, subject)).id;

      await _api.addStudyPlan(
        token: token,
        subjectId: subjectId,
        start: start,
        end: end,
      );

      final hasSimilarTask = state.tasks.any(
        (task) =>
            !task.isCompleted &&
            task.subject.toLowerCase() == subject.toLowerCase() &&
            task.deadline.difference(end).inMinutes.abs() <= 1 &&
            task.title.toLowerCase().startsWith('study:'),
      );

      if (!hasSimilarTask) {
        await _api.addTask(
          token: token,
          subjectId: subjectId,
          title: 'Study: $subject',
          deadline: end,
          priority: TaskPriority.medium,
        );
      }

      await refreshAll();
    } catch (e) {
      await _handleApiError(e);
    }
  }

  Future<void> refreshAll() async {
    final token = state.token;
    if (token == null) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      var subjects = await _api.getSubjects(token);
      final defaultSubjects = const [
        'Mathematics',
        'Physics',
        'Computer Science',
        'Chemistry',
        'Biology',
        'English',
      ];

      final existingNames = subjects.map((item) => item.name.toLowerCase()).toSet();
      final missing = defaultSubjects
          .where((subject) => !existingNames.contains(subject.toLowerCase()))
          .toList();

      if (subjects.isEmpty || missing.isNotEmpty) {
        for (final subject in missing.isEmpty ? defaultSubjects : missing) {
          try {
            await _api.createSubject(token, subject);
          } catch (_) {
            // Continue if subject creation fails
          }
        }
        subjects = await _api.getSubjects(token);
      }

      final userName = await _api.fetchUserName(token);

      List<StudentTask> tasks = const [];
      List<StudyBlock> plans = const [];
      List<AppAlert> reminders = const [];
      ProgressSummary progress = const ProgressSummary(
        completedTasks: 0,
        totalTasks: 0,
        completionPercentage: 0,
        studyHours: 0,
      );

      try {
        tasks = await _api.getTasks(token, subjects);
      } catch (_) {}

      try {
        plans = await _api.getStudyPlans(token, subjects);
      } catch (_) {}

      try {
        reminders = await _api.getReminders(token, subjects);
      } catch (_) {}

      try {
        progress = await _api.getProgress(token);
      } catch (_) {
        final completed = tasks.where((task) => task.isCompleted).length;
        final total = tasks.length;
        progress = ProgressSummary(
          completedTasks: completed,
          totalTasks: total,
          completionPercentage: total == 0 ? 0 : (completed / total) * 100,
          studyHours: 0,
        );
      }

      state = state.copyWith(
        isLoading: false,
        userName: userName,
        subjects: subjects,
        tasks: tasks,
        studyBlocks: plans,
        alerts: reminders,
        progress: progress,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> _handleApiError(Object error, {bool? isLoading}) async {
    if (error is ApiException && error.isUnauthorized) {
      await logout();
      return;
    }

    state = state.copyWith(
      isLoading: isLoading ?? state.isLoading,
      errorMessage: error.toString(),
    );
  }
}
