import 'package:flutter/material.dart';

class YoloDetection {
  final int classIndex;
  final String className;
  final String displayName;
  final double confidence;
  final double x; // normalized center x (0..1)
  final double y; // normalized center y (0..1)
  final double width; // normalized width (0..1)
  final double height; // normalized height (0..1)

  const YoloDetection({
    required this.classIndex,
    required this.className,
    required this.displayName,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Convert normalized bounding box to screen Rect
  Rect toRect(Size screenSize) {
    final left = (x - width / 2).clamp(0.0, 1.0) * screenSize.width;
    final top = (y - height / 2).clamp(0.0, 1.0) * screenSize.height;
    final rectWidth = width.clamp(0.0, 1.0) * screenSize.width;
    final rectHeight = height.clamp(0.0, 1.0) * screenSize.height;
    return Rect.fromLTWH(left, top, rectWidth, rectHeight);
  }

  @override
  String toString() {
    return 'YoloDetection(class: $displayName, conf: ${(confidence * 100).toStringAsFixed(1)}%, box: [${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${width.toStringAsFixed(2)}, ${height.toStringAsFixed(2)}])';
  }
}
