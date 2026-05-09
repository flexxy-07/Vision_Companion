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

  static const double _confidenceThreshold = 0.3;
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

      // Input tensor: [1, 300, 300, 3] - normalized to 0-1 range
      final input = inputBytes.reshape([1, _inputSize, _inputSize, 3]);

      // SSD MobileNet v1 outputs:
      // output0: boxes [1, 1, 100, 4]
      // output1: classes [1, 1, 100, 91] 
      // output2: scores [1, 1, 100]
      // output3: count [1]
      
      final boxesTensor = List<double>.filled(1 * 1 * 100 * 4, 0.0).reshape([1, 1, 100, 4]);
      final classesTensor = List<double>.filled(1 * 1 * 100 * 91, 0.0).reshape([1, 1, 100, 91]);
      final scoresTensor = List<double>.filled(1 * 1 * 100, 0.0).reshape([1, 1, 100]);
      final countTensor = List<double>.filled(1, 0.0).reshape([1]);

      final outputs = <int, Object>{
        0: boxesTensor,
        1: classesTensor,
        2: scoresTensor,
        3: countTensor,
      };

      interpreter.runForMultipleInputs([input], outputs);

      final detections = <Map<String, dynamic>>[];
      
      try {
        // Extract detections from outputs
        final boxes = outputs[0] as List<dynamic>;
        final classes = outputs[1] as List<dynamic>;
        final scores = outputs[2] as List<dynamic>;
        final count = ((outputs[3] as List<dynamic>)[0] as double).toInt().clamp(0, 100);

        // Extract the first batch and first anchor
        final boxesBatch = boxes[0] as List<dynamic>;
        final classesBatch = classes[0] as List<dynamic>;
        final scoresBatch = scores[0] as List<dynamic>;

        for (int i = 0; i < count; i++) {
          final score = scoresBatch[i] as double;
          
          // Skip low confidence detections
          if (score < data.confidenceThreshold) continue;

          // Get the class with highest confidence for this detection
          final classScores = classesBatch[i] as List<dynamic>;
          int maxClassIdx = 0;
          double maxClassScore = 0.0;
          
          for (int j = 0; j < classScores.length && j < data.labels.length; j++) {
            final classScore = classScores[j] as double;
            if (classScore > maxClassScore) {
              maxClassScore = classScore;
              maxClassIdx = j;
            }
          }

          final label = maxClassIdx < data.labels.length 
              ? data.labels[maxClassIdx]
              : 'Unknown';

          final box = boxesBatch[i] as List<dynamic>;
          final top = (box[0] as double).clamp(0.0, 1.0);
          final left = (box[1] as double).clamp(0.0, 1.0);
          final bottom = (box[2] as double).clamp(0.0, 1.0);
          final right = (box[3] as double).clamp(0.0, 1.0);

          // Only add valid boxes
          if (right > left && bottom > top) {
            detections.add({
              'label': label,
              'confidence': score,
              'left': left,
              'top': top,
              'right': right,
              'bottom': bottom,
            });
          }
        }
      } catch (parseErr) {
        // If parsing fails, send the error
        data.sendPort.send({'error': 'Parse error: $parseErr'});
        return;
      }

      // Sort by confidence
      detections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

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

    // Convert to bytes [300, 300, 3] with normalization to 0-1 range
    final bytes = Uint8List(_inputSize * _inputSize * 3);
    int idx = 0;
    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        // Store as uint8 (0-255), model will handle normalization
        bytes[idx++] = pixel.r.toInt().clamp(0, 255);
        bytes[idx++] = pixel.g.toInt().clamp(0, 255);
        bytes[idx++] = pixel.b.toInt().clamp(0, 255);
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