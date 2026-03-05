import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_stability_controller.dart';
import 'roi_models.dart';

class LiveScanState {
  const LiveScanState({
    required this.stableFrames,
    required this.isLocked,
    this.preview,
  });

  final int stableFrames;
  final bool isLocked;
  final ExtractedMarks? preview;
}

class LiveOcrCameraController {
  LiveOcrCameraController({
    required this.camera,
    required this.tableRoi,
    required this.layout,
    OcrStabilityController? stabilityController,
  }) : _stabilityController = stabilityController ?? OcrStabilityController();

  final CameraController camera;
  final Rect tableRoi;
  final MarksRoiLayout layout;
  final OcrStabilityController _stabilityController;

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _scanStateController = StreamController<LiveScanState>.broadcast();

  Stream<LiveScanState> get states => _scanStateController.stream;

  bool _isBusy = false;

  Future<void> start() async {
    await camera.startImageStream(_onImageFrame);
  }

  Future<void> stop() async {
    if (camera.value.isStreamingImages) {
      await camera.stopImageStream();
    }
    await _textRecognizer.close();
    await _scanStateController.close();
  }

  Future<void> _onImageFrame(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;
    try {
      final inputImage = _toInputImage(image, camera.description.sensorOrientation);
      final recognized = await _textRecognizer.processImage(inputImage);
      final extracted = _extractMarks(recognized);
      if (extracted == null) {
        _scanStateController.add(const LiveScanState(stableFrames: 0, isLocked: false));
        return;
      }

      final result = _stabilityController.consume(extracted);
      _scanStateController.add(
        LiveScanState(
          stableFrames: result.consecutiveStableFrames,
          isLocked: result.isLocked,
          preview: extracted,
        ),
      );

      if (result.isLocked && result.lockedMarks != null) {
        HapticFeedback.mediumImpact();
        // TODO: Persist with repository and clear for next paper.
        _stabilityController.clearAfterSave();
      }
    } finally {
      _isBusy = false;
    }
  }

  ExtractedMarks? _extractMarks(RecognizedText recognized) {
    final allElements = <TextElement>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        allElements.addAll(line.elements);
      }
    }

    final enrollment = _readNumericFromCell(layout.enrollmentRect, allElements, allowLong: true);
    if (enrollment == null) return null;

    final questions = <int>[];
    for (final cellRect in layout.questionRects) {
      final value = _readNumericFromCell(cellRect, allElements);
      if (value == null) return null;
      questions.add(value);
    }

    final total = _readNumericFromCell(layout.totalRect, allElements);
    if (total == null) return null;

    final confidences = allElements
        .where((e) => _intersectsTable(e.boundingBox))
        .map((e) => e.confidence)
        .whereType<double>()
        .toList();

    final averageConfidence =
        confidences.isEmpty ? 0.0 : confidences.reduce((a, b) => a + b) / confidences.length;

    return ExtractedMarks(
      enrollmentNo: enrollment.toString(),
      questions: questions,
      total: total,
      confidence: averageConfidence,
    );
  }

  int? _readNumericFromCell(Rect normalizedRect, List<TextElement> elements, {bool allowLong = false}) {
    final absolute = layout.toAbsoluteRect(tableRect: tableRoi, normalizedRect: normalizedRect);
    final tokens = elements
        .where((element) => absolute.overlaps(element.boundingBox))
        .toList()
      ..sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

    if (tokens.isEmpty) return null;
    final merged = tokens.map((e) => e.text).join();
    final numeric = merged.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeric.isEmpty) return null;

    if (!allowLong && numeric.length > 2) return null;
    return int.tryParse(numeric);
  }

  bool _intersectsTable(Rect boundingBox) => tableRoi.overlaps(boundingBox);

  InputImage _toInputImage(CameraImage image, int sensorRotation) {
    final allBytes = WriteBuffer();
    for (final plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final inputImageFormat = Platform.isAndroid
        ? InputImageFormat.nv21
        : InputImageFormat.bgra8888;

    final rotation = InputImageRotationValue.fromRawValue(sensorRotation) ??
        InputImageRotation.rotation0deg;

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: inputImageFormat,
      bytesPerRow: image.planes.first.bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  static Rect centeredTableRoi(Size previewSize) {
    final width = previewSize.width * 0.92;
    final height = previewSize.height * 0.45;
    return Rect.fromLTWH(
      (previewSize.width - width) / 2,
      math.max(16, (previewSize.height - height) / 2),
      width,
      height,
    );
  }
}
