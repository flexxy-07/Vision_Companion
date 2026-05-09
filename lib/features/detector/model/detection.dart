import 'package:flutter/material.dart';

class Detection {
  final String label;
  final double confidence;
  final Rect boundingBox;

  const Detection({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  Color get categoryColor {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return colors[label.hashCode.abs() % colors.length];
  }

  String get confidencePercent =>
      '${(confidence * 100).toStringAsPrecision(0)}%';
}
