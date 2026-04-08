import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../widgets/ai_suggestion_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/progress_ring.dart';
import '../widgets/quick_action_card.dart';
import '../widgets/task_card.dart';
import 'add_task_sheet.dart';
import 'notifications_screen.dart';
import 'progress_tracker_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final upcoming = state.tasks.where((task) => !task.isCompleted).take(3).toList();

    return RefreshIndicator(
      onRefresh: () => ref.read(appStateProvider.notifier).refreshAll(),
      child: CustomScrollView(
        slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 130,
          title: const Text('Dashboard'),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_rounded),
                  if (state.alerts.where((alert) => alert.isUnread).isNotEmpty)
                    const Positioned(
                      right: -1,
                      top: -1,
                      child: CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
                    ),
                ],
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Good Evening, ${state.userName} 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today\'s Summary',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Text('Tasks due: ${state.tasksDueToday}'),
                        const SizedBox(height: 4),
                        Text('Study hours: ${state.studyHoursToday.toStringAsFixed(1)}h'),
                      ],
                    ),
                    ProgressRing(value: state.dailyProductivity),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  QuickActionCard(
                    title: 'Add Task',
                    icon: Icons.add_task_rounded,
                    onTap: () => showAddTaskBottomSheet(context, ref),
                  ),
                  const SizedBox(width: 10),
                  QuickActionCard(
                    title: 'Plan Study',
                    icon: Icons.calendar_month_rounded,
                    onTap: () {
                      ref.read(appStateProvider.notifier).changeTab(1);
                    },
                  ),
                  const SizedBox(width: 10),
                  QuickActionCard(
                    title: 'Insights',
                    icon: Icons.analytics_outlined,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProgressTrackerScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const AiSuggestionCard(),
              const SizedBox(height: 14),
              Text(
                'Upcoming Tasks',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              ...upcoming.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: TaskCard(
                      task: task,
                      onComplete: () async {
                        await ref.read(appStateProvider.notifier).completeTask(task.id);
                      },
                      onDelete: () async {
                        await ref.read(appStateProvider.notifier).deleteTask(task.id);
                      },
                    ),
                  )),
            ]),
          ),
        ),
        ],
      ),
    );
  }
}
