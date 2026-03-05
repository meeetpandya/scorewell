import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../vision/live_ocr_camera_controller.dart';
import '../vision/roi_models.dart';
import 'widgets/roi_overlay_painter.dart';

class LiveScanScreen extends StatefulWidget {
  const LiveScanScreen({
    super.key,
    required this.cameraDescription,
  });

  final CameraDescription cameraDescription;

  @override
  State<LiveScanScreen> createState() => _LiveScanScreenState();
}

class _LiveScanScreenState extends State<LiveScanScreen> {
  late final CameraController _cameraController;
  LiveOcrCameraController? _liveOcrController;
  LiveScanState _state = const LiveScanState(stableFrames: 0, isLocked: false);

  @override
  void initState() {
    super.initState();
    _cameraController = CameraController(
      widget.cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    _setup();
  }

  Future<void> _setup() async {
    await _cameraController.initialize();
    final previewSize = _cameraController.value.previewSize!;
    final tableRect = LiveOcrCameraController.centeredTableRoi(
      Size(previewSize.height, previewSize.width),
    );

    final layout = MarksRoiLayout.defaultLayout();
    _liveOcrController = LiveOcrCameraController(
      camera: _cameraController,
      tableRoi: tableRect,
      layout: layout,
    );

    _liveOcrController!.states.listen((scanState) {
      if (!mounted) return;
      setState(() => _state = scanState);
    });

    await _liveOcrController!.start();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _liveOcrController?.stop();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final previewSize = _cameraController.value.previewSize!;
    final canvasSize = Size(previewSize.height, previewSize.width);
    final tableRect = LiveOcrCameraController.centeredTableRoi(canvasSize);
    final layout = MarksRoiLayout.defaultLayout();

    final enrollmentRect = layout.toAbsoluteRect(
      tableRect: tableRect,
      normalizedRect: layout.enrollmentRect,
    );
    final questionRects = layout.questionRects
        .map((q) => layout.toAbsoluteRect(tableRect: tableRect, normalizedRect: q))
        .toList();
    final totalRect = layout.toAbsoluteRect(
      tableRect: tableRect,
      normalizedRect: layout.totalRect,
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController),
          CustomPaint(
            painter: RoiOverlayPainter(
              tableRect: tableRect,
              enrollmentRect: enrollmentRect,
              questionRects: questionRects,
              totalRect: totalRect,
              isLocked: _state.isLocked,
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'Stable Frames: ${_state.stableFrames}/5\n'
                  'Equation check: ${_state.preview?.isMathematicallyValid == true ? 'PASS' : 'WAIT'}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
