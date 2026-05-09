import 'package:flutter/material.dart';
import 'package:vision_companion/features/detector/model/detection.dart';

class BoundingBoxPainter extends CustomPainter{
  final List<Detection> detections;
  final Size imageSize;

  BoundingBoxPainter(this.detections, this.imageSize);

  @override
  void paint(Canvas canvas, Size size){
    if (detections.isEmpty) return;
    

    
    for(final det in detections){
      // Skip only the "Inference Active" heartbeat boxes
      if (det.label == 'Inference Active') continue;
      
      final paint = Paint()
      ..color = det.categoryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

      final left = det.boundingBox.left * size.width;
      final top = det.boundingBox.top * size.height;
      final right = det.boundingBox.right * size.width;
      final bottom = det.boundingBox.bottom * size.height;
      
      final rect = Rect.fromLTRB(left, top, right, bottom);

      canvas.drawRect(rect, paint);

      final bgPaint = Paint()
      ..color = det.categoryColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

      final textSpan = TextSpan(
        text: ' ${det.label} ${det.confidencePercent} ',
        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
      );

      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelTop = (top - tp.height - 4).clamp(0.0, size.height - tp.height);
      final labelRect = Rect.fromLTWH(
        left,
        labelTop,
        tp.width + 4,
        tp.height + 4,
      );

      canvas.drawRect(labelRect, bgPaint);
      tp.paint(canvas, Offset(left + 2, labelTop + 2));
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter old) => 
  old.detections != detections;
}