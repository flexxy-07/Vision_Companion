import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../cubit/detector_cubit.dart';
import '../model/detection.dart';
import '../widgets/bounding_box_painter.dart';

class DetectorPage extends StatefulWidget {
  const DetectorPage({super.key});

  @override
  State<DetectorPage> createState() => _DetectorPageState();
}

class _DetectorPageState extends State<DetectorPage> {
  CameraController? _cameraController;
  bool _cameraReady = false;
  Timer? _announceTimer;
  String _lastAnnounced = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() => _cameraReady = true);

    // Load model then start stream
    final cubit = context.read<DetectorCubit>();
    await cubit.loadModel();

    _cameraController!.startImageStream((image) {
      cubit.runInference(image);
    });
  }

  void _handleDetections(List<Detection> detections) {
    if (detections.isEmpty) return;

    // Haptic feedback on detection
    HapticFeedback.mediumImpact();

    // TalkBack — announce top object every 2 seconds debounced
    _announceTimer?.cancel();
    _announceTimer = Timer(const Duration(seconds: 2), () {
      final top = detections.first.label;
      if (top != _lastAnnounced) {
        _lastAnnounced = top;
        SemanticsService.announce(
          'Detected: $top ${detections.first.confidencePercent}',
          TextDirection.ltr,
        );
      }
    });
  }

  @override
  void dispose() {
    _announceTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DetectorCubit>(),
      child: Builder(builder: (context) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Live Object Detector'),
          ),
          body: BlocConsumer<DetectorCubit, DetectorState>(
            listener: (context, state) {
              if (state is DetectorResults) {
                _handleDetections(state.detections);
              }
            },
            builder: (context, state) {
              final isPaused = state is DetectorPaused;
              final detections =
                  state is DetectorResults ? state.detections : <Detection>[];

              return Column(
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Camera preview
                        Semantics(
                          label: 'Live camera feed for object detection',
                          child: _cameraReady && _cameraController != null
                              ? CameraPreview(_cameraController!)
                              : const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        // Bounding boxes overlay
                        if (_cameraReady && _cameraController != null)
                          SizedBox.expand(
                            child: CustomPaint(
                              painter: BoundingBoxPainter(
                                detections,
                                Size(
                                  _cameraController!.value.previewSize!.width.toDouble(),
                                  _cameraController!.value.previewSize!.height.toDouble(),
                                ),
                              ),
                            ),
                          ),
                        // Paused overlay
                        if (isPaused)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                              child: Icon(
                                Icons.pause_circle_filled,
                                color: Colors.white,
                                size: 80,
                              ),
                            ),
                          ),
                        // Detection count badge
                        if (!isPaused)
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                detections.isEmpty 
                                  ? 'Scanning...' 
                                  : '${detections.length} detected',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ),
                        // Debug info
                        Positioned(
                          bottom: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Ready: ${_cameraReady ? 'Yes' : 'No'}\nDetections: ${detections.length}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Controls bar
                  Container(
                    color: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Semantics(
                          button: true,
                          label: isPaused
                              ? 'Resume detection'
                              : 'Pause detection',
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                context.read<DetectorCubit>().togglePause(),
                            icon: Icon(
                                isPaused ? Icons.play_arrow : Icons.pause),
                            label: Text(
                                isPaused ? 'Resume' : 'Pause'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(160, 52),
                              backgroundColor: isPaused
                                  ? Colors.green
                                  : Colors.white24,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}