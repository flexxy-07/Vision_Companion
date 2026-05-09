import 'dart:typed_data'; import 'package:tflite_flutter/tflite_flutter.dart'; void main() { Uint8List bytes = Uint8List(270000); final reshaped = bytes.reshape([1, 300, 300, 3]); }
