import 'dart:ui';

/// Relative (0..1) ROI map anchored to the marks table area.
class MarksRoiLayout {
  const MarksRoiLayout({
    required this.enrollmentRect,
    required this.questionRects,
    required this.totalRect,
  });

  final Rect enrollmentRect;
  final List<Rect> questionRects;
  final Rect totalRect;

  /// Default layout inferred from a standard marks sheet.
  ///
  /// The coordinate system is normalized to the detected table rectangle.
  factory MarksRoiLayout.defaultLayout() {
    return MarksRoiLayout(
      enrollmentRect: const Rect.fromLTWH(0.70, 0.08, 0.26, 0.16),
      questionRects: List<Rect>.generate(
        8,
        (index) => Rect.fromLTWH(0.06 + (index * 0.10), 0.62, 0.08, 0.18),
      ),
      totalRect: const Rect.fromLTWH(0.87, 0.62, 0.10, 0.18),
    );
  }

  Rect toAbsoluteRect({required Rect tableRect, required Rect normalizedRect}) {
    return Rect.fromLTWH(
      tableRect.left + (tableRect.width * normalizedRect.left),
      tableRect.top + (tableRect.height * normalizedRect.top),
      tableRect.width * normalizedRect.width,
      tableRect.height * normalizedRect.height,
    );
  }
}

class ExtractedMarks {
  const ExtractedMarks({
    required this.enrollmentNo,
    required this.questions,
    required this.total,
    required this.confidence,
  });

  final String enrollmentNo;
  final List<int> questions;
  final int total;
  final double confidence;

  bool get isMathematicallyValid =>
      questions.fold<int>(0, (sum, value) => sum + value) == total;

  @override
  String toString() {
    return 'ExtractedMarks(enrollmentNo: $enrollmentNo, questions: $questions, total: $total, confidence: $confidence)';
  }
}
