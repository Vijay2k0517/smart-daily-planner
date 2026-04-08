import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import 'add_task_sheet.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'study_planner_screen.dart';
import 'task_manager_screen.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen>
    with SingleTickerProviderStateMixin {
  bool _fabExpanded = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final screens = [
      const DashboardScreen(),
      const StudyPlannerScreen(),
      const TaskManagerScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey(state.selectedTab),
          child: screens[state.selectedTab],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _fabExpanded
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'planFab',
                          onPressed: () {
                            setState(() => _fabExpanded = false);
                            ref.read(appStateProvider.notifier).changeTab(1);
                          },
                          child: const Icon(Icons.calendar_view_day_rounded),
                        ),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'taskFab',
                          onPressed: () {
                            setState(() => _fabExpanded = false);
                            showAddTaskBottomSheet(context, ref);
                          },
                          child: const Icon(Icons.add_task_rounded),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          FloatingActionButton(
            onPressed: () => setState(() => _fabExpanded = !_fabExpanded),
            child: AnimatedRotation(
              duration: const Duration(milliseconds: 250),
              turns: _fabExpanded ? 0.125 : 0,
              child: const Icon(Icons.add_rounded),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.selectedTab,
        onDestinationSelected: (index) => ref.read(appStateProvider.notifier).changeTab(index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Planner'),
          NavigationDestination(icon: Icon(Icons.task_alt_outlined), label: 'Tasks'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
