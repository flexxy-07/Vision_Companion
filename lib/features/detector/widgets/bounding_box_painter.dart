import 'package:flutter/material.dart';
import 'package:vision_companion/features/detector/model/detection.dart';

class BoundingBoxPainter extends CustomPainter{
  final List<Detection> detections;
  final Size imageSize;

  BoundingBoxPainter(this.detections, this.imageSize);

  @override
  void paint(Canvas canvas, Size size){
    for(final det in detections){
      final paint = Paint()
      ..color = det.categoryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

      final rect = Rect.fromLTRB(
        det.boundingBox.left * size.width,
        det.boundingBox.top * size.height,
        det.boundingBox.right * size.width,
        det.boundingBox.bottom * size.height,
      );

      canvas.drawRect(rect, paint);

      final bgPaint = Paint()
      // ignore: deprecated_member_use
      ..color = det.categoryColor.withOpacity(0.85)
      ..style = PaintingStyle.fill;

      final textSpan = TextSpan(
        text: ' ${det.label} ${det.confidencePercent} ',
        style: const TextStyle(color: Colors.white, fontSize: 12),
      );

      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final labelRect = Rect.fromLTWH(
        rect.left,
        rect.top - tp.height - 2,
        tp.width,
        tp.height + 2,
      );

      canvas.drawRect(labelRect, bgPaint);
      tp.paint(canvas, Offset(rect.left, rect.top - tp.height - 1));
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter old) => 
  old.detections != detections;
}