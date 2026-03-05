import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path/path.dart' as p;

import '../vision/roi_models.dart';

class ScanSessionMeta {
  const ScanSessionMeta({
    required this.courseName,
    required this.date,
    required this.section,
  });

  final String courseName;
  final DateTime date;
  final String section;
}

class RecordRepository {
  final List<Map<String, dynamic>> _inMemory = [];

  Future<void> saveRecord({
    required ScanSessionMeta meta,
    required ExtractedMarks marks,
  }) async {
    _inMemory.add({
      'course_name': meta.courseName,
      'date': meta.date.toIso8601String(),
      'section': meta.section,
      'enrollment_no': marks.enrollmentNo,
      ...{for (var i = 0; i < marks.questions.length; i++) 'q${i + 1}': marks.questions[i]},
      'total': marks.total,
    });
  }

  Future<File> exportCsv(String outputDirectoryPath) async {
    final rows = <List<dynamic>>[
      [
        'course_name',
        'date',
        'section',
        'enrollment_no',
        'q1',
        'q2',
        'q3',
        'q4',
        'q5',
        'q6',
        'q7',
        'q8',
        'total',
      ],
      ..._inMemory.map(
        (row) => [
          row['course_name'],
          row['date'],
          row['section'],
          row['enrollment_no'],
          row['q1'],
          row['q2'],
          row['q3'],
          row['q4'],
          row['q5'],
          row['q6'],
          row['q7'],
          row['q8'],
          row['total'],
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final target = File(p.join(outputDirectoryPath, 'scorewell_export.csv'));
    return target.writeAsString(csv);
  }
}
