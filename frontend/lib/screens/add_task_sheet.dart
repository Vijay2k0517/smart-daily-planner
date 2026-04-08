import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/student_task.dart';
import '../state/app_state.dart';
import '../widgets/custom_button.dart';

Future<void> showAddTaskBottomSheet(BuildContext context, WidgetRef ref) async {
  final state = ref.read(appStateProvider);
  final availableSubjects = state.subjects.map((item) => item.name).toList();
  final formKey = GlobalKey<FormState>();
  final titleController = TextEditingController();
  const customSubjectValue = '__custom__';
  String subject = availableSubjects.isNotEmpty ? availableSubjects.first : customSubjectValue;
  final customSubjectController = TextEditingController();
  TaskPriority priority = TaskPriority.medium;
  DateTime deadline = DateTime.now().add(const Duration(hours: 4));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 12,
              right: 12,
              top: 12,
            ),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Add Task / Study Plan',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: subject,
                        items: [
                          for (final item in availableSubjects)
                            DropdownMenuItem(value: item, child: Text(item)),
                          const DropdownMenuItem(
                            value: customSubjectValue,
                            child: Text('Add new subject...'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => subject = value);
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Subject'),
                      ),
                      if (subject == customSubjectValue) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: customSubjectController,
                          decoration: const InputDecoration(labelText: 'New Subject Name'),
                          validator: (value) {
                            if (subject == customSubjectValue &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter a subject name';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Deadline: ${deadline.toLocal()}'.split('.').first,
                        ),
                        trailing: const Icon(Icons.calendar_month_rounded),
                        onTap: () async {
                          final selectedDate = await showDatePicker(
                            context: context,
                            initialDate: deadline,
                            firstDate: DateTime.now().subtract(const Duration(days: 1)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (selectedDate == null || !context.mounted) {
                            return;
                          }
                          final selectedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(deadline),
                          );
                          if (selectedTime != null) {
                            setState(() {
                              deadline = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 6),
                      SegmentedButton<TaskPriority>(
                        showSelectedIcon: false,
                        selected: {priority},
                        onSelectionChanged: (selection) {
                          setState(() => priority = selection.first);
                        },
                        segments: const [
                          ButtonSegment(value: TaskPriority.high, label: Text('High')),
                          ButtonSegment(value: TaskPriority.medium, label: Text('Medium')),
                          ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                        ],
                      ),
                      const SizedBox(height: 18),
                      CustomButton(
                        label: 'Save Task',
                        icon: Icons.save_outlined,
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }
                          final selectedSubject = subject == customSubjectValue
                              ? customSubjectController.text.trim()
                              : subject;

                          await ref.read(appStateProvider.notifier).addTask(
                            title: titleController.text.trim(),
                            subject: selectedSubject,
                            deadline: deadline,
                            priority: priority,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task saved successfully')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
