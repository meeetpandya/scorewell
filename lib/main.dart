import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'ui/live_scan_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(ScoreWellApp(cameras: cameras));
}

class ScoreWellApp extends StatelessWidget {
  const ScoreWellApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: SessionInitScreen(cameras: cameras),
    );
  }
}

class SessionInitScreen extends StatefulWidget {
  const SessionInitScreen({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  State<SessionInitScreen> createState() => _SessionInitScreenState();
}

class _SessionInitScreenState extends State<SessionInitScreen> {
  final _courseController = TextEditingController();
  final _dateController = TextEditingController();
  final _sectionController = TextEditingController();

  @override
  void dispose() {
    _courseController.dispose();
    _dateController.dispose();
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ScoreWell Session Setup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _courseController, decoration: const InputDecoration(labelText: 'Course Name')),
            TextField(controller: _dateController, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
            TextField(controller: _sectionController, decoration: const InputDecoration(labelText: 'Section')),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LiveScanScreen(cameraDescription: widget.cameras.first),
                  ),
                );
              },
              child: const Text('Start Live OCR'),
            ),
          ],
        ),
      ),
    );
  }
}
