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

  /// Convert normalized bounding box (0..1 relative to camera frame) to screen Rect matching BoxFit.cover
  Rect toRect(Size screenSize, {double cameraAspectRatio = 4 / 3}) {
    final screenRatio = screenSize.height / screenSize.width;
    double renderedW;
    double renderedH;
    double offsetX = 0.0;
    double offsetY = 0.0;

    if (screenRatio > cameraAspectRatio) {
      // Screen is taller than camera preview -> camera fills height, cropped horizontally
      renderedH = screenSize.height;
      renderedW = screenSize.height / cameraAspectRatio;
      offsetX = (renderedW - screenSize.width) / 2.0;
    } else {
      // Screen is wider than camera preview -> camera fills width, cropped vertically
      renderedW = screenSize.width;
      renderedH = screenSize.width * cameraAspectRatio;
      offsetY = (renderedH - screenSize.height) / 2.0;
    }

    final boxW = width * renderedW;
    final boxH = height * renderedH;
    final left = x * renderedW - boxW / 2.0 - offsetX;
    final top = y * renderedH - boxH / 2.0 - offsetY;

    return Rect.fromLTWH(
      left.clamp(0.0, screenSize.width),
      top.clamp(0.0, screenSize.height),
      boxW.clamp(0.0, screenSize.width),
      boxH.clamp(0.0, screenSize.height),
    );
  }

  @override
  String toString() {
    return 'YoloDetection(class: $displayName, conf: ${(confidence * 100).toStringAsFixed(1)}%, box: [${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${width.toStringAsFixed(2)}, ${height.toStringAsFixed(2)}])';
  }
}
