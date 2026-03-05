import 'roi_models.dart';

class StabilityResult {
  const StabilityResult({
    required this.isLocked,
    required this.consecutiveStableFrames,
    this.lockedMarks,
  });

  final bool isLocked;
  final int consecutiveStableFrames;
  final ExtractedMarks? lockedMarks;
}

/// Applies temporal integration and voting-like reset behavior.
class OcrStabilityController {
  OcrStabilityController({this.requiredStableFrames = 5, this.minConfidence = 0.85});

  final int requiredStableFrames;
  final double minConfidence;

  ExtractedMarks? _lastAccepted;
  int _stableCount = 0;

  StabilityResult consume(ExtractedMarks candidate) {
    final passesConfidence = candidate.confidence >= minConfidence;
    final passesMath = candidate.isMathematicallyValid;

    if (!passesConfidence || !passesMath) {
      _reset();
      return const StabilityResult(isLocked: false, consecutiveStableFrames: 0);
    }

    if (_lastAccepted == null) {
      _lastAccepted = candidate;
      _stableCount = 1;
      return StabilityResult(
        isLocked: false,
        consecutiveStableFrames: _stableCount,
      );
    }

    if (_areEquivalent(_lastAccepted!, candidate)) {
      _stableCount += 1;
    } else {
      // Voting reset: any change between frames resets streak.
      _lastAccepted = candidate;
      _stableCount = 1;
    }

    final locked = _stableCount >= requiredStableFrames;
    return StabilityResult(
      isLocked: locked,
      consecutiveStableFrames: _stableCount,
      lockedMarks: locked ? _lastAccepted : null,
    );
  }

  void clearAfterSave() => _reset();

  void _reset() {
    _stableCount = 0;
    _lastAccepted = null;
  }

  bool _areEquivalent(ExtractedMarks a, ExtractedMarks b) {
    if (a.enrollmentNo != b.enrollmentNo) return false;
    if (a.total != b.total) return false;
    if (a.questions.length != b.questions.length) return false;
    for (var i = 0; i < a.questions.length; i++) {
      if (a.questions[i] != b.questions[i]) return false;
    }
    return true;
  }
}
