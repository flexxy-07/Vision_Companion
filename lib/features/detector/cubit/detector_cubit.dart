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
  CameraImage? _latestImage;  // Track latest frame
  DateTime? _lastHistorySave; // Throttle history saving

  static const double _confidenceThreshold = 0.2;
  static const int _inputSize = 300;

  DetectorCubit(this._historyRepo) : super(const DetectorState());

  Future<void> loadModel() async {
    emit(state.copyWith(isLoading: true));
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


      emit(state.copyWith(isLoading: false));
    } catch (e) {

      emit(state.copyWith(isLoading: false, error: 'Failed to load model: $e'));
    }
  }

  void togglePause() {
    _isPaused = !_isPaused;
    emit(state.copyWith(isPaused: _isPaused));
  }
  

  Future<void> runInference(CameraImage image) async {
    if (_isPaused) return;
    
    // Always save latest frame
    _latestImage = image;
    
    // If already processing, wait for it to finish then process latest frame
    if (_isProcessing) return;
    
    if (_interpreter == null) {
      emit(state.copyWith(
        detections: [
          Detection(
            label: 'ERR: Interpreter is null! Did you restart the app?',
            confidence: 1.0,
            boundingBox: const Rect.fromLTRB(0.1, 0.4, 0.9, 0.6),
          )
        ],
      ));
      return;
    }
    
    _isProcessing = true;

    try {
      // Keep processing latest frames until caught up
      while (_latestImage != null) {
        if (_isPaused) {
          _latestImage = null;
          break;
        }
        
        final currentImage = _latestImage;
        _latestImage = null;  // Mark as processed
        
        final results = await _runInIsolate(currentImage!);
        
        if (_isPaused) break; // Check again after isolate completes
        
        if (results.isNotEmpty) {
          if (!state.isPaused) {
            emit(state.copyWith(detections: results));
          }
          
          // Don't save heartbeat to history
          final actualDetections = results.where((d) => d.label != 'Inference Active').toList();
          
          // Throttle saving to history (e.g. once every 3 seconds) to prevent Firestore hangs/spam
          final now = DateTime.now();
          if (actualDetections.isNotEmpty && 
              (_lastHistorySave == null || now.difference(_lastHistorySave!).inSeconds >= 3)) {
            _lastHistorySave = now;
            
            // Fire-and-forget so we don't block the next frame!
            _historyRepo.saveHistory(
              featureType: 'object_detection',
              resultSummary: actualDetections.map((d) => d.label).take(3).join(', '),
            ).catchError((e) {
              print('History save error: $e');
            });
          }
        } else {
          if (!state.isPaused) {
            emit(state.copyWith(detections: []));
          }
        }
      }
    } catch (e, st) {
      print('Inference error: $e\n$st');
      // Show the exact error on screen
      emit(state.copyWith(
        detections: [
          Detection(
            label: 'ERROR: ${e.toString().replaceAll('\n', ' ')}',
            confidence: 1.0,
            boundingBox: const Rect.fromLTRB(0.05, 0.4, 0.95, 0.6),
          )
        ],
      ));
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
    receivePort.close();
    
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

      final inputTensors = interpreter.getInputTensors();
      final inputType = inputTensors[0].type;
      
      Object input;
      if (inputType.toString().contains('float32')) {
        // Normalize to [-1, 1] for common float SSD models
        final floatInput = Float32List(_inputSize * _inputSize * 3);
        for (int i = 0; i < inputBytes.length; i++) {
          floatInput[i] = (inputBytes[i] - 127.5) / 127.5;
        }
        input = floatInput.reshape([1, _inputSize, _inputSize, 3]);
      } else {
        input = inputBytes.reshape([1, _inputSize, _inputSize, 3]);
      }

      // Get output tensor info
      final outputTensors = interpreter.getOutputTensors();
      final outputs = <int, Object>{};
      
      // Dynamically prepare output buffers based on model's actual shapes
      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        if (outputTensors[i].type.toString().contains('float32')) {
          outputs[i] = List<double>.filled(shape.reduce((a, b) => a * b), 0.0).reshape(shape);
        } else {
          // Some models use int32 or uint8 for classes/count
          outputs[i] = List<int>.filled(shape.reduce((a, b) => a * b), 0).reshape(shape);
        }
      }

      interpreter.runForMultipleInputs([input], outputs);

      // Discovery: identify which output is which by shape and values
      List<dynamic>? boxes;
      List<dynamic>? scores;
      List<dynamic>? classes;
      int count = 0;

      for (int i = 0; i < outputTensors.length; i++) {
        final shape = outputTensors[i].shape;
        final data = outputs[i];
        
        if (shape.length == 3 && shape[2] == 4) {
          // [1, N, 4] is definitely boxes
          boxes = (data as List)[0];
        } else if (shape.length == 1 && shape[0] == 1) {
          // [1] is likely count
          final val = (data as List)[0];
          count = (val is num) ? val.toInt() : (val as List)[0].toInt();
        } else if (shape.length == 2) {
          // [1, N] could be scores or classes
          final list = (data as List)[0];
          if (list.isEmpty) continue;
          
          // Heuristic: Scores are 0..1, Classes are often > 1
          double maxVal = 0;
          bool hasHighVal = false;
          for (var v in list) {
             final num val = v as num;
             if (val > maxVal) maxVal = val.toDouble();
             if (val > 1.1) hasHighVal = true;
          }
          
          if (hasHighVal) {
            classes = list;
          } else {
            scores = list;
          }
        }
      }

      // Fallback if discovery failed (try common SSD order)
      boxes ??= (outputs[0] as List)[0];
      classes ??= (outputs[1] as List)[0];
      scores ??= (outputs[2] as List)[0];
      if (count == 0) {
        final countData = outputs[3];
        count = (countData is List) ? (countData[0] as num).toInt() : 10;
      }

      // Final safety check: if we swapped scores and classes (e.g. all scores < 1 and classes also < 1)
      // we check if classes has any non-integers
      if (classes != null && scores != null) {
        bool classesHasFractional = false;
        for (var v in classes) {
          if (v is double && v != v.roundToDouble()) {
            classesHasFractional = true;
            break;
          }
        }
        if (classesHasFractional) {
          final temp = classes;
          classes = scores;
          scores = temp;
        }
      }

      final List<Map<String, dynamic>> detections = [];
      final maxCount = boxes!.length;
      final actualCount = count.clamp(0, maxCount);

      for (int i = 0; i < actualCount; i++) {
        final score = (scores![i] as num).toDouble().clamp(0.0, 1.0);
        if (score < data.confidenceThreshold) continue;

        int classIdx = (classes![i] as num).toInt();
        // Shift if 1-indexed
        if (classIdx > 0 && classIdx <= data.labels.length) {
           // Standard SSD behavior
           classIdx -= 1;
        }
        
        final label = classIdx >= 0 && classIdx < data.labels.length 
            ? data.labels[classIdx] 
            : 'Object';

        final box = boxes[i] as List<dynamic>;
        final top = (box[0] as double).clamp(0.0, 1.0);
        final left = (box[1] as double).clamp(0.0, 1.0);
        final bottom = (box[2] as double).clamp(0.0, 1.0);
        final right = (box[3] as double).clamp(0.0, 1.0);



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

    // Rotate 90 degrees clockwise (Android portrait mode)
    final rotated = img.copyRotate(imgLib, angle: 90);

    // Resize to 300x300
    final resized = img.copyResize(rotated, width: _inputSize, height: _inputSize);

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
    emit(const DetectorState());
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