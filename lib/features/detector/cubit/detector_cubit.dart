import 'dart:isolate';

import 'package:camera/camera.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../features/history/repository/history_repository.dart';
import '../model/detection.dart';

part 'detector_state.dart';

class DetectorCubit extends Cubit<DetectorState> {
  final HistoryRepository _historyRepo;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isPaused = false;
  bool _isProcessing = false;

  static const double _confidenceThreshold = 0.2;
  static const int _inputSize = 300;

  DetectorCubit(this._historyRepo) : super(DetectorIdle());

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
          'assets/models/ssd_mobilenet_v1.tflite');

      // Load labels
      final labelsData =
          await rootBundle.loadString('assets/labels/coco_labels.txt');
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      emit(DetectorRunning());
    } catch (e) {
      emit(DetectorError('Failed to load model: $e'));
    }
  }

  void togglePause() {
    _isPaused = !_isPaused;
    emit(_isPaused ? DetectorPaused() : DetectorRunning());
  }

  Future<void> runInference(CameraImage image) async {
    if (_isPaused || _isProcessing) return;
    
    if (_interpreter == null) {
      emit(DetectorResults([
        Detection(
          label: 'ERR: Interpreter is null! Did you restart the app?',
          confidence: 1.0,
          boundingBox: const Rect.fromLTRB(0.1, 0.4, 0.9, 0.6),
        )
      ]));
      return;
    }
    
    _isProcessing = true;

    try {
      final results = await _runInIsolate(image);
      if (results.isNotEmpty) {
        emit(DetectorResults(results));
        
        // Don't save heartbeat to history
        final actualDetections = results.where((d) => d.label != 'Inference Active').toList();
        if (actualDetections.isNotEmpty) {
          await _historyRepo.saveHistory(
            featureType: 'object_detection',
            resultSummary: actualDetections.map((d) => d.label).take(3).join(', '),
          );
        }
      } else {
        emit(DetectorRunning());
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('Inference error: $e\n$st');
      // Show the exact error on screen as a fake bounding box!
      emit(DetectorResults([
        Detection(
          label: 'ERR: ${e.toString().replaceAll('\n', ' ')}',
          confidence: 1.0,
          boundingBox: const Rect.fromLTRB(0.05, 0.4, 0.95, 0.6),
        )
      ]));
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<Detection>> _runInIsolate(CameraImage image) async {
    final receivePort = ReceivePort();

    // Extract plane data to send to isolate
    final planesData = image.planes.map((p) => {
      'bytes': p.bytes,
      'bytesPerRow': p.bytesPerRow,
      'bytesPerPixel': p.bytesPerPixel,
    }).toList();

    await Isolate.spawn(
      _isolateInference,
      _IsolateData(
        sendPort: receivePort.sendPort,
        planesData: planesData,
        width: image.width,
        height: image.height,
        interpreterAddress: _interpreter!.address,
        labels: _labels,
        confidenceThreshold: _confidenceThreshold,
      ),
    );

    final result = await receivePort.first;
    if (result is Map && result.containsKey('error')) {
      throw Exception(result['error']);
    }

    final detections = result as List<Map<String, dynamic>>;
    return detections
        .map((e) => Detection(
              label: e['label'] as String,
              confidence: e['confidence'] as double,
              boundingBox: Rect.fromLTRB(
                e['left'] as double,
                e['top'] as double,
                e['right'] as double,
                e['bottom'] as double,
              ),
            ))
        .toList();
  }

  static void _isolateInference(_IsolateData data) {
    try {
      final inputBytes = _preprocessPlanes(
        data.planesData,
        data.width,
        data.height,
      );

      final interpreter = Interpreter.fromAddress(data.interpreterAddress);

      // Input tensor: [1, 300, 300, 3] uint8
      final input = inputBytes.reshape([1, _inputSize, _inputSize, 3]);

      // Dynamically discover outputs to prevent shape mismatch crashes
      final outputTensors = interpreter.getOutputTensors();
      final outputs = <int, Object>{};
      
      int boxesIdx = -1;
      int classesIdx = -1;
      int scoresIdx = -1;
      int countIdx = -1;

      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        
        // Count tensor is [1]
        if (shape.length == 1 && shape[0] == 1) {
          countIdx = i;
          outputs[i] = List.filled(1, 0.0).reshape(shape);
        }
        // Boxes tensor is [1, 10, 4]
        else if (shape.length == 3 && shape[2] == 4) {
          boxesIdx = i;
          outputs[i] = List.filled(shape[0] * shape[1] * shape[2], 0.0).reshape(shape);
        }
        // Classes and scores are both [1, 10]
        // We will assign them temporarily, and figure it out later.
        else if (shape.length == 2) {
          if (classesIdx == -1) {
            classesIdx = i; // Will verify after inference
          } else {
            scoresIdx = i;
          }
          outputs[i] = List.filled(shape[0] * shape[1], 0.0).reshape(shape);
        }
      }

      // Fallback defaults if discovery failed
      if (outputs.isEmpty) {
        outputs[0] = List.filled(1 * 10 * 4, 0.0).reshape([1, 10, 4]);
        outputs[1] = List.filled(1 * 10, 0.0).reshape([1, 10]);
        outputs[2] = List.filled(1 * 10, 0.0).reshape([1, 10]);
        outputs[3] = List.filled(1, 0.0).reshape([1]);
        boxesIdx = 0; classesIdx = 1; scoresIdx = 2; countIdx = 3;
      }

      interpreter.runForMultipleInputs([input], outputs);

      // Heuristic: If classes output has values like 0.8, it's actually scores!
      // Classes should be integer values like 0.0, 1.0, 2.0...
      final classesRaw = outputs[classesIdx] as List<dynamic>;
      final scoresRaw = outputs[scoresIdx] as List<dynamic>;
      
      List<dynamic> actualClasses = classesRaw[0];
      List<dynamic> actualScores = scoresRaw[0];
      
      if (actualClasses.isNotEmpty && actualClasses[0] is double) {
        final val = actualClasses[0] as double;
        if (val > 0.0 && val < 1.0 && val != val.roundToDouble()) {
           // This means classesIdx actually points to scores! Swap them.
           actualClasses = scoresRaw[0];
           actualScores = classesRaw[0];
        }
      }

      final countArray = outputs[countIdx] as List<dynamic>;
      final count = (countArray[0] as double).toInt();
      
      final boxesArray = outputs[boxesIdx] as List<dynamic>;
      final List<Map<String, dynamic>> detections = [];

      for (int i = 0; i < count; i++) {
        final score = actualScores[i] as double;
        if (score < data.confidenceThreshold) continue;

        final classIndex = (actualClasses[i] as double).toInt();
        final label = classIndex < data.labels.length
            ? data.labels[classIndex]
            : 'Unknown';

        final box = boxesArray[0][i] as List<dynamic>;
        final top = (box[0] as double).clamp(0.0, 1.0);
        final left = (box[1] as double).clamp(0.0, 1.0);
        final bottom = (box[2] as double).clamp(0.0, 1.0);
        final right = (box[3] as double).clamp(0.0, 1.0);

        detections.add({
          'label': label,
          'confidence': score,
          'left': left,
          'top': top,
          'right': right,
          'bottom': bottom,
        });
      }

      // Add a debug heartbeat box so we know inference is running
      detections.add({
        'label': 'Inference Active',
        'confidence': 1.0,
        'left': 0.0,
        'top': 0.0,
        'right': 0.3,
        'bottom': 0.1,
      });

      data.sendPort.send(detections);
    } catch (e, st) {
      data.sendPort.send({'error': '$e\n$st'});
    }
  }

  static Uint8List _preprocessPlanes(
      List<Map<String, dynamic>> planesData, int width, int height) {
    // Convert YUV420 to RGB image
    final imgLib = _convertYUV420Planes(planesData, width, height);

    // Resize to 300x300
    final resized = img.copyResize(imgLib, width: _inputSize, height: _inputSize);

    // Convert to bytes [300, 300, 3]
    final bytes = Uint8List(_inputSize * _inputSize * 3);
    int idx = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        bytes[idx++] = pixel.r.toInt();
        bytes[idx++] = pixel.g.toInt();
        bytes[idx++] = pixel.b.toInt();
      }
    }
    return bytes;
  }

  static img.Image _convertYUV420Planes(
      List<Map<String, dynamic>> planesData, int width, int height) {
    final yPlane = planesData[0]['bytes'] as Uint8List;
    final uPlane = planesData[1]['bytes'] as Uint8List;
    final vPlane = planesData[2]['bytes'] as Uint8List;
    
    final yRowStride = planesData[0]['bytesPerRow'] as int;
    final uRowStride = planesData[1]['bytesPerRow'] as int;
    final uPixelStride = planesData[1]['bytesPerPixel'] as int? ?? 1;

    final rgbImage = img.Image(width: width, height: height);

    for (int h = 0; h < height; h++) {
      for (int w = 0; w < width; w++) {
        final yIndex = h * yRowStride + w;
        final uvIndex =
            (h ~/ 2) * uRowStride + (w ~/ 2) * uPixelStride;

        final y = yPlane[yIndex];
        final u = uPlane[uvIndex];
        final v = vPlane[uvIndex];

        final r = (y + 1.402 * (v - 128)).clamp(0, 255).toInt();
        final g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128))
            .clamp(0, 255)
            .toInt();
        final b = (y + 1.772 * (u - 128)).clamp(0, 255).toInt();

        rgbImage.setPixelRgb(w, h, r, g, b);
      }
    }
    return rgbImage;
  }

  void stopDetection() {
    _isPaused = false;
    emit(DetectorIdle());
  }

  @override
  Future<void> close() {
    _interpreter?.close();
    return super.close();
  }
}

class _IsolateData {
  final SendPort sendPort;
  final List<Map<String, dynamic>> planesData;
  final int width;
  final int height;
  final int interpreterAddress;
  final List<String> labels;
  final double confidenceThreshold;

  _IsolateData({
    required this.sendPort,
    required this.planesData,
    required this.width,
    required this.height,
    required this.interpreterAddress,
    required this.labels,
    required this.confidenceThreshold,
  });
}