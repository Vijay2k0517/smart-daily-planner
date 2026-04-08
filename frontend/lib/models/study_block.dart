import 'package:flutter/material.dart';

class StudyBlock {
  StudyBlock({
    required this.id,
    required this.subject,
    required this.start,
    required this.end,
    required this.color,
  });

  final String id;
  final String subject;
  final DateTime start;
  final DateTime end;
  final Color color;

  Duration get duration => end.difference(start);

  StudyBlock copyWith({
    String? id,
    String? subject,
    DateTime? start,
    DateTime? end,
    Color? color,
  }) {
    return StudyBlock(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      start: start ?? this.start,
      end: end ?? this.end,
      color: color ?? this.color,
    );
  }
}
