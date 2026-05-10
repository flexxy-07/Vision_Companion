import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vision_companion/features/detector/cubit/detector_cubit.dart';
import '../../../core/services/tts_service.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:vision_companion/l10n/app_localizations.dart';

import '../../../core/di/injection.dart';
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
  DateTime? _lastAnnounceTime;

  @override
  void initState() {
    super.initState();
    _initCamera();
    FirebaseAnalytics.instance.logEvent(
      name: 'feature_opened',
      parameters: {'feature': 'detector'},
    );
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

    final cubit = getIt<DetectorCubit>();
    await cubit.loadModel();

    _cameraController!.startImageStream((image) {
      cubit.runInference(image);
    });
  }

  void _handleDetections(List<Detection> detections) {
    final l10n = AppLocalizations.of(context);
    
    if (detections.isEmpty) {
      final now = DateTime.now();
      if (_lastAnnounceTime == null || now.difference(_lastAnnounceTime!).inSeconds >= 10) {
        if (_lastAnnounced != 'scanning') {
          _lastAnnounced = 'scanning';
          _lastAnnounceTime = now;
          getIt<TtsService>().speak(
            l10n.scanningText,
            l10n.localeName,
          );
        }
      }
      return;
    }

    HapticFeedback.mediumImpact();

    _announceTimer?.cancel();
    _announceTimer = Timer(const Duration(milliseconds: 1500), () {
      final top = detections.first.label;
      final now = DateTime.now();
      
      bool shouldAnnounce = top != _lastAnnounced;
      if (!shouldAnnounce && _lastAnnounceTime != null) {
        if (now.difference(_lastAnnounceTime!).inSeconds >= 5) {
          shouldAnnounce = true;
        }
      }

      if (shouldAnnounce) {
        _lastAnnounced = top;
        _lastAnnounceTime = now;
        getIt<TtsService>().speak(
          l10n.detectedAnnouncement(top, detections.first.confidencePercent),
          l10n.localeName,
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'object_detected',
          parameters: {
            'label': top,
            'confidence': detections.first.confidence,
          },
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
    final l10n = AppLocalizations.of(context);

    return BlocProvider.value(
      value: getIt<DetectorCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: Text(l10n.feature1Title),
            ),
            body: BlocConsumer<DetectorCubit, DetectorState>(
              listener: (context, state) {
                if (state.detections.isNotEmpty) {
                  _handleDetections(state.detections);
                }
              },
              builder: (context, state) {
                final isPaused = state.isPaused;
                final detections = state.detections;

                return Column(
                  children: [
                    Expanded(
                      child: ExcludeSemantics(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            (_cameraReady && _cameraController != null && !state.isLoading)
                                ? CameraPreview(_cameraController!)
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),

                            if (_cameraReady && _cameraController != null)
                              SizedBox.expand(
                                child: CustomPaint(
                                  painter: BoundingBoxPainter(
                                    detections,
                                    Size(
                                      _cameraController!.value.previewSize!.width
                                          .toDouble(),
                                      _cameraController!.value.previewSize!.height
                                          .toDouble(),
                                    ),
                                  ),
                                ),
                              ),
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
                            if (!isPaused)
                              Positioned(
                                top: 12,
                                left: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    detections.isEmpty
                                        ? l10n.scanningText
                                        : l10n.detectedText(
                                            '${detections.length}',
                                          ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${l10n.cameraStatus(_cameraReady ? l10n.yes : l10n.no)}\n${l10n.detectionCountStatus(detections.length)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        vertical: 20,
                        horizontal: 24,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Semantics(
                            button: true,
                            label: isPaused
                                ? l10n.resumeDetection
                                : l10n.pauseDetection,
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  context.read<DetectorCubit>().togglePause(),
                              icon: Icon(
                                isPaused ? Icons.play_arrow : Icons.pause,
                              ),
                              label: Text(
                                isPaused ? l10n.resumeButton : l10n.pauseButton,
                              ),
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
        },
      ),
    );
  }
}
