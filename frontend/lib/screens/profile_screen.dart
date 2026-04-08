import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/app_state.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final notifier = ref.read(appStateProvider.notifier);
    final completedTasks = state.progress.completedTasks;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        GlassCard(
          child: Column(
            children: [
              const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 34)),
              const SizedBox(height: 10),
              Text(
                state.userName,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('Student • Smart Planner User'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Productivity Stats',
                style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text('Completed tasks: $completedTasks'),
              const SizedBox(height: 4),
              Text('Pending tasks: ${state.progress.totalTasks - completedTasks}'),
              const SizedBox(height: 4),
              Text('Study hours: ${state.progress.studyHours.toStringAsFixed(1)}h'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 6),
          title: const Text('Dark mode'),
          subtitle: const Text('Toggle app theme'),
          value: state.isDarkMode,
          onChanged: (_) => notifier.toggleTheme(),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async => notifier.logout(),
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }
}
