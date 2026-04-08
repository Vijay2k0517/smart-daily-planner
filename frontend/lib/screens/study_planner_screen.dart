import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../state/app_state.dart';
import '../widgets/glass_card.dart';

class StudyPlannerScreen extends ConsumerStatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  ConsumerState<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends ConsumerState<StudyPlannerScreen> {
  bool weeklyView = true;
  DateTime focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final subjects = state.subjects;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Study Planner',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              selected: {weeklyView},
              onSelectionChanged: (selection) {
                setState(() => weeklyView = selection.first);
              },
              segments: const [
                ButtonSegment(value: true, label: Text('Weekly')),
                ButtonSegment(value: false, label: Text('Monthly')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        GlassCard(
          child: TableCalendar(
            focusedDay: focusedDay,
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            calendarFormat: weeklyView ? CalendarFormat.week : CalendarFormat.month,
            selectedDayPredicate: (day) => isSameDay(day, focusedDay),
            onDaySelected: (selected, focused) {
              setState(() => focusedDay = selected);
            },
            headerVisible: !weeklyView,
            eventLoader: (day) {
              return state.studyBlocks.where((block) => isSameDay(block.start, day)).toList();
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(color: Color(0xFF4F46E5), shape: BoxShape.circle),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Drag & Drop Study Blocks',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (subjects.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(
              'No subjects yet. Add one from the dashboard or home tab.',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < subjects.length; i++)
                _DraggableSubject(subject: subjects[i].name, color: _generateSubjectColor(subjects[i].id)),
            ],
          ),
        const SizedBox(height: 14),
        ...[8, 10, 12, 14, 16, 18].map(
          (hour) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                final start = DateTime(
                  focusedDay.year,
                  focusedDay.month,
                  focusedDay.day,
                  hour,
                );
                ref.read(appStateProvider.notifier).addStudyBlock(
                      subject: details.data,
                      start: start,
                      end: start.add(const Duration(hours: 1)),
                    );
              },
              builder: (context, _, __) {
                final slotBlocks = state.studyBlocks.where((block) {
                  return isSameDay(block.start, focusedDay) && block.start.hour == hour;
                }).toList();

                return GlassCard(
                  child: Row(
                    children: [
                      SizedBox(
                        width: 68,
                        child: Text('${hour.toString().padLeft(2, '0')}:00'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: slotBlocks.isEmpty
                            ? Text(
                                'Drop subject here',
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: slotBlocks
                                    .map(
                                      (block) => Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(12),
                                          color: block.color.withValues(alpha: 0.18),
                                        ),
                                        child: Text(
                                          '${block.subject} · ${DateFormat('h:mm a').format(block.start)}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

Color _generateSubjectColor(int id) {
  const palette = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF8B5CF6), // Purple
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
    Color(0xFF06B6D4), // Cyan
    Color(0xFFEC4899), // Pink
    Color(0xFF8B5CF6), // Fuchsia
    Color(0xFF14B8A6), // Teal
  ];
  return palette[(id.hashCode.toUnsigned(32) % palette.length)];
}

class _DraggableSubject extends StatelessWidget {
  const _DraggableSubject({
    required this.subject,
    required this.color,
  });

  final String subject;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final draggableChild = Chip(
      label: Text(subject),
      backgroundColor: color.withValues(alpha: 0.18),
    );

    final feedback = Material(
      color: Colors.transparent,
      child: Chip(
        label: Text(subject),
        backgroundColor: color.withValues(alpha: 0.9),
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );

    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
      return Draggable<String>(
        data: subject,
        feedback: feedback,
        childWhenDragging: Opacity(opacity: 0.45, child: draggableChild),
        child: draggableChild,
      );
    }

    return LongPressDraggable<String>(
      data: subject,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.45, child: draggableChild),
      child: draggableChild,
    );
  }
}
