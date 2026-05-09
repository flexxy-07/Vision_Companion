import 'dart:isolate';
import 'dart:typed_data';

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

      print('✅ MODEL LOADED: interpreter=$_interpreter, labels=${_labels.length}');
      emit(DetectorRunning());
    } catch (e) {
      print('❌ MODEL LOAD FAILED: $e');
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
      print('🔄 runInference: got ${results.length} results from isolate');
      
      // Always emit results to keep UI updating
      if (results.isNotEmpty) {
        print('📡 Emitting ${results.length} detections to UI');
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
        // Emit heartbeat so UI knows inference is running
        emit(DetectorResults([
          Detection(
            label: 'Scanning...',
            confidence: 0.5,
            boundingBox: const Rect.fromLTRB(0.0, 0.0, 0.3, 0.05),
          )
        ]));
      }
    } catch (e, st) {
      print('Inference error: $e\n$st');
      // Show the exact error on screen
      emit(DetectorResults([
        Detection(
          label: 'ERROR: ${e.toString().replaceAll('\n', ' ')}',
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
    print('✅ RECEIVED ${detections.length} detections from isolate');
    
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
      print('🔄 ISOLATE STARTED: width=${data.width}, height=${data.height}, threshold=${data.confidenceThreshold}');
      
      final inputBytes = _preprocessPlanes(
        data.planesData,
        data.width,
        data.height,
      );

      final interpreter = Interpreter.fromAddress(data.interpreterAddress);

      // Input tensor: [1, 300, 300, 3] uint8
      final input = inputBytes.reshape([1, _inputSize, _inputSize, 3]);

      // Get actual output tensor info
      final outputTensors = interpreter.getOutputTensors();
      
      print('🔍 OUTPUT TENSORS: count=${outputTensors.length}');
      for (int i = 0; i < outputTensors.length; i++) {
        print('  Tensor[$i]: shape=${outputTensors[i].shape}, type=${outputTensors[i].type}');
      }
      
      // Try to find correct tensor indices based on shape
      int boxesIdx = -1, classesIdx = -1, scoresIdx = -1, countIdx = -1;
      
      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        
        if (shape.length == 1 && shape[0] == 1) {
          countIdx = i;
        } else if (shape.length == 3 && shape[2] == 4) {
          // [1, N, 4] - boxes
          boxesIdx = i;
        } else if (shape.length == 2) {
          // [1, N] - could be scores or classes
          if (scoresIdx == -1) {
            scoresIdx = i;
          } else if (classesIdx == -1) {
            classesIdx = i;
          }
        }
      }
      
      // Fallback with larger capacity for SSD MobileNet v1
      if (countIdx == -1) countIdx = 3;
      if (boxesIdx == -1) boxesIdx = 0;
      if (scoresIdx == -1) scoresIdx = 2;
      if (classesIdx == -1) classesIdx = 1;
      
      // Create output tensors with appropriate sizes
      final outputs = <int, Object>{};
      
      final boxesShape = [1, 10, 4];
      final scoresShape = [1, 10];
      final classesShape = [1, 10];
      final countShape = [1];
      
      outputs[boxesIdx] = List<double>.filled(1 * 10 * 4, 0.0).reshape(boxesShape);
      outputs[scoresIdx] = List<double>.filled(1 * 10, 0.0).reshape(scoresShape);
      outputs[classesIdx] = List<double>.filled(1 * 10, 0.0).reshape(classesShape);
      outputs[countIdx] = List<double>.filled(1, 0.0).reshape(countShape);

      print('🔄 Running inference with inputs reshaped...');
      interpreter.runForMultipleInputs([input], outputs);
      print('✅ Inference complete');

      final countArray = outputs[countIdx] as List<dynamic>;
      final count = (countArray[0] as double).toInt().clamp(0, 10);
      
      print('🔍 DETECTOR: count=$count, boxesIdx=$boxesIdx, scoresIdx=$scoresIdx, classesIdx=$classesIdx, countIdx=$countIdx');
      
      final boxesArray = outputs[boxesIdx] as List<dynamic>;
      final scoresArray = outputs[scoresIdx] as List<dynamic>;
      final classesArray = outputs[classesIdx] as List<dynamic>;
      
      final boxesBatch = boxesArray[0] as List<dynamic>;
      final scoresBatch = scoresArray[0] as List<dynamic>;
      final classesBatch = classesArray[0] as List<dynamic>;
      
      final List<Map<String, dynamic>> detections = [];

      for (int i = 0; i < count; i++) {
        final score = (scoresBatch[i] as double).clamp(0.0, 1.0);
        
        if (i < 5) {
          print('  Score[$i]: $score');
        }
        
        // Skip low confidence
        if (score < data.confidenceThreshold) continue;

        final classIdx = (classesBatch[i] as double).toInt().clamp(0, data.labels.length - 1);
        final label = classIdx < data.labels.length ? data.labels[classIdx] : 'Unknown';

        final box = boxesBatch[i] as List<dynamic>;
        final top = (box[0] as double).clamp(0.0, 1.0);
        final left = (box[1] as double).clamp(0.0, 1.0);
        final bottom = (box[2] as double).clamp(0.0, 1.0);
        final right = (box[3] as double).clamp(0.0, 1.0);

        print('  Box[$i]: top=$top, left=$left, bottom=$bottom, right=$right, label=$label, score=$score');

        // Validate box
        if (right > left && bottom > top && (right - left) > 0.01 && (bottom - top) > 0.01) {
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

      // Sort by confidence
      detections.sort((a, b) => (b['confidence'] as double).compareTo(a['confidence'] as double));

      // Add heartbeat only if we have real detections
      if (detections.isNotEmpty) {
        detections.add({
          'label': 'Inference Active',
          'confidence': 1.0,
          'left': 0.0,
          'top': 0.0,
          'right': 0.3,
          'bottom': 0.1,
        });
      }

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