import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

class LetterboxInfo {
  final double scale;
  final int padX;
  final int padY;
  final int activeWidth;
  final int activeHeight;

  const LetterboxInfo({
    required this.scale,
    required this.padX,
    required this.padY,
    required this.activeWidth,
    required this.activeHeight,
  });
}

class ImageConverter {
  // Precomputed lookup table for byte to normalized float (0..255 -> 0.0..1.0)
  static final Float32List _normalizedLut = Float32List.fromList(
    List.generate(256, (i) => i / 255.0),
  );

  // Precomputed integer fixed-point coefficients (shifted by 10 bits) for BT.601 YUV -> RGB
  static final Int32List _vToR = Int32List.fromList(
    List.generate(256, (v) => ((v - 128) * 1436) >> 10),
  );
  static final Int32List _uToG = Int32List.fromList(
    List.generate(256, (u) => ((u - 128) * 352) >> 10),
  );
  static final Int32List _vToG = Int32List.fromList(
    List.generate(256, (v) => ((v - 128) * 731) >> 10),
  );
  static final Int32List _uToB = Int32List.fromList(
    List.generate(256, (u) => ((u - 128) * 1815) >> 10),
  );

  // Standard Ultralytics YOLO padding float: 114 / 255.0
  static const double yoloPadValue = 0.4470588235294118;

  /// High-performance Letterboxed conversion for CameraImage into flat Float32List [1, 640, 640, 3] in NHWC format.
  /// Preserves exact 1:1 aspect ratio with zero squashing or distortion.
  /// Padding filled with standard YOLO gray (114/255 = 0.447).
  static LetterboxInfo? fillLetterboxedFloat32List(
    CameraImage cameraImage,
    Float32List targetBuffer, {
    int sensorOrientation = 90,
    int targetWidth = 640,
    int targetHeight = 640,
  }) {
    try {
      final int srcWidth = cameraImage.width;
      final int srcHeight = cameraImage.height;
      final lut = _normalizedLut;

      // In portrait (orientation 90/270), sensor height is portrait width, sensor width is portrait height
      final int portraitWidth = (sensorOrientation == 90 || sensorOrientation == 270) ? srcHeight : srcWidth;
      final int portraitHeight = (sensorOrientation == 90 || sensorOrientation == 270) ? srcWidth : srcHeight;

      // Calculate scale to fit inside targetWidth x targetHeight preserving aspect ratio
      final double scale = min(targetWidth / portraitWidth, targetHeight / portraitHeight);
      final int activeWidth = (portraitWidth * scale).round();
      final int activeHeight = (portraitHeight * scale).round();
      final int padX = (targetWidth - activeWidth) ~/ 2;
      final int padY = (targetHeight - activeHeight) ~/ 2;

      // Pre-fill entire buffer with standard YOLO letterbox gray (114/255.0)
      targetBuffer.fillRange(0, targetBuffer.length, yoloPadValue);

      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        final Plane yPlane = cameraImage.planes[0];
        final Plane uPlane = cameraImage.planes[1];
        final Plane vPlane = cameraImage.planes[2];

        final int yRowStride = yPlane.bytesPerRow;
        final int yPixelStride = yPlane.bytesPerPixel ?? 1;

        final int uRowStride = uPlane.bytesPerRow;
        final int uPixelStride = uPlane.bytesPerPixel ?? 1;

        final int vRowStride = vPlane.bytesPerRow;
        final int vPixelStride = vPlane.bytesPerPixel ?? 1;

        final Uint8List yBytes = yPlane.bytes;
        final Uint8List uBytes = uPlane.bytes;
        final Uint8List vBytes = vPlane.bytes;

        if (sensorOrientation == 90) {
          // Precompute lookup tables for active region coordinates
          final Int32List syTable = Int32List(activeWidth);
          final Int32List uvSyTable = Int32List(activeWidth);
          for (int lx = 0; lx < activeWidth; lx++) {
            final int sy = (lx * srcHeight) ~/ activeWidth;
            syTable[lx] = sy;
            uvSyTable[lx] = sy >> 1;
          }

          final Int32List sxTable = Int32List(activeHeight);
          final Int32List uvSxTable = Int32List(activeHeight);
          for (int ly = 0; ly < activeHeight; ly++) {
            final int sx = ((activeHeight - 1 - ly) * srcWidth) ~/ activeHeight;
            sxTable[ly] = sx;
            uvSxTable[ly] = sx >> 1;
          }

          // Populate active region with fast integer YUV -> RGB
          for (int ly = 0; ly < activeHeight; ly++) {
            final int targetY = padY + ly;
            final int rowOffset = targetY * targetWidth * 3;

            final int sx = sxTable[ly];
            final int uvSx = uvSxTable[ly];
            final int sxYPixel = sx * yPixelStride;
            final int uvSxUPixel = uvSx * uPixelStride;
            final int uvSxVPixel = uvSx * vPixelStride;

            for (int lx = 0; lx < activeWidth; lx++) {
              final int targetX = padX + lx;
              final int sy = syTable[lx];
              final int uvSy = uvSyTable[lx];

              final int yIndex = sy * yRowStride + sxYPixel;
              final int uIndex = uvSy * uRowStride + uvSxUPixel;
              final int vIndex = uvSy * vRowStride + uvSxVPixel;

              if (yIndex >= yBytes.length || uIndex >= uBytes.length || vIndex >= vBytes.length) {
                continue;
              }

              final int y = yBytes[yIndex];
              final int u = uBytes[uIndex];
              final int v = vBytes[vIndex];

              // Fast integer BT.601 YUV -> RGB via precomputed lookup tables
              final int r = (y + _vToR[v]).clamp(0, 255);
              final int g = (y - _uToG[u] - _vToG[v]).clamp(0, 255);
              final int b = (y + _uToB[u]).clamp(0, 255);

              final int pxIdx = rowOffset + targetX * 3;
              targetBuffer[pxIdx] = lut[r];
              targetBuffer[pxIdx + 1] = lut[g];
              targetBuffer[pxIdx + 2] = lut[b];
            }
          }

          return LetterboxInfo(
            scale: scale,
            padX: padX,
            padY: padY,
            activeWidth: activeWidth,
            activeHeight: activeHeight,
          );
        } else if (sensorOrientation == 270) {
          final Int32List syTable = Int32List(activeWidth);
          final Int32List uvSyTable = Int32List(activeWidth);
          for (int lx = 0; lx < activeWidth; lx++) {
            final int sy = ((activeWidth - 1 - lx) * srcHeight) ~/ activeWidth;
            syTable[lx] = sy;
            uvSyTable[lx] = sy >> 1;
          }

          final Int32List sxTable = Int32List(activeHeight);
          final Int32List uvSxTable = Int32List(activeHeight);
          for (int ly = 0; ly < activeHeight; ly++) {
            final int sx = (ly * srcWidth) ~/ activeHeight;
            sxTable[ly] = sx;
            uvSxTable[ly] = sx >> 1;
          }

          for (int ly = 0; ly < activeHeight; ly++) {
            final int targetY = padY + ly;
            final int rowOffset = targetY * targetWidth * 3;

            final int sx = sxTable[ly];
            final int uvSx = uvSxTable[ly];
            final int sxYPixel = sx * yPixelStride;
            final int uvSxUPixel = uvSx * uPixelStride;
            final int uvSxVPixel = uvSx * vPixelStride;

            for (int lx = 0; lx < activeWidth; lx++) {
              final int targetX = padX + lx;
              final int sy = syTable[lx];
              final int uvSy = uvSyTable[lx];

              final int yIndex = sy * yRowStride + sxYPixel;
              final int uIndex = uvSy * uRowStride + uvSxUPixel;
              final int vIndex = uvSy * vRowStride + uvSxVPixel;

              if (yIndex >= yBytes.length || uIndex >= uBytes.length || vIndex >= vBytes.length) {
                continue;
              }

              final int y = yBytes[yIndex];
              final int u = uBytes[uIndex];
              final int v = vBytes[vIndex];

              final int r = (y + _vToR[v]).clamp(0, 255);
              final int g = (y - _uToG[u] - _vToG[v]).clamp(0, 255);
              final int b = (y + _uToB[u]).clamp(0, 255);

              final int pxIdx = rowOffset + targetX * 3;
              targetBuffer[pxIdx] = lut[r];
              targetBuffer[pxIdx + 1] = lut[g];
              targetBuffer[pxIdx + 2] = lut[b];
            }
          }

          return LetterboxInfo(
            scale: scale,
            padX: padX,
            padY: padY,
            activeWidth: activeWidth,
            activeHeight: activeHeight,
          );
        } else {
          // Unrotated / 0 degree
          final Int32List sxTable = Int32List(activeWidth);
          final Int32List uvSxTable = Int32List(activeWidth);
          for (int lx = 0; lx < activeWidth; lx++) {
            final int sx = (lx * srcWidth) ~/ activeWidth;
            sxTable[lx] = sx;
            uvSxTable[lx] = sx >> 1;
          }

          final Int32List syTable = Int32List(activeHeight);
          final Int32List uvSyTable = Int32List(activeHeight);
          for (int ly = 0; ly < activeHeight; ly++) {
            final int sy = (ly * srcHeight) ~/ activeHeight;
            syTable[ly] = sy;
            uvSyTable[ly] = sy >> 1;
          }

          for (int ly = 0; ly < activeHeight; ly++) {
            final int targetY = padY + ly;
            final int rowOffset = targetY * targetWidth * 3;
            final int sy = syTable[ly];
            final int uvSy = uvSyTable[ly];
            final int syRow = sy * yRowStride;
            final int uvSyURow = uvSy * uRowStride;
            final int uvSyVRow = uvSy * vRowStride;

            for (int lx = 0; lx < activeWidth; lx++) {
              final int targetX = padX + lx;
              final int sx = sxTable[lx];
              final int uvSx = uvSxTable[lx];

              final int yIndex = syRow + sx * yPixelStride;
              final int uIndex = uvSyURow + uvSx * uPixelStride;
              final int vIndex = uvSyVRow + uvSx * vPixelStride;

              if (yIndex >= yBytes.length || uIndex >= uBytes.length || vIndex >= vBytes.length) {
                continue;
              }

              final int y = yBytes[yIndex];
              final int u = uBytes[uIndex];
              final int v = vBytes[vIndex];

              final int r = (y + _vToR[v]).clamp(0, 255);
              final int g = (y - _uToG[u] - _vToG[v]).clamp(0, 255);
              final int b = (y + _uToB[u]).clamp(0, 255);

              final int pxIdx = rowOffset + targetX * 3;
              targetBuffer[pxIdx] = lut[r];
              targetBuffer[pxIdx + 1] = lut[g];
              targetBuffer[pxIdx + 2] = lut[b];
            }
          }

          return LetterboxInfo(
            scale: scale,
            padX: padX,
            padY: padY,
            activeWidth: activeWidth,
            activeHeight: activeHeight,
          );
        }
      }

      // iOS BGRA8888 format
      if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        final plane = cameraImage.planes[0];
        final bytes = plane.bytes;
        final rowStride = plane.bytesPerRow;

        for (int ly = 0; ly < activeHeight; ly++) {
          final int sy = (ly * srcHeight) ~/ activeHeight;
          final int targetY = padY + ly;
          final int rowOffset = targetY * targetWidth * 3;

          for (int lx = 0; lx < activeWidth; lx++) {
            final int sx = (lx * srcWidth) ~/ activeWidth;
            final int targetX = padX + lx;
            final int index = sy * rowStride + sx * 4;

            if (index + 3 < bytes.length) {
              final int pxIdx = rowOffset + targetX * 3;
              targetBuffer[pxIdx] = lut[bytes[index + 2]]; // R
              targetBuffer[pxIdx + 1] = lut[bytes[index + 1]]; // G
              targetBuffer[pxIdx + 2] = lut[bytes[index]]; // B
            }
          }
        }

        return LetterboxInfo(
          scale: scale,
          padX: padX,
          padY: padY,
          activeWidth: activeWidth,
          activeHeight: activeHeight,
        );
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// Converts a static decoded Image into a flat Float32List with letterboxing
  static LetterboxInfo fillPlanarFloat32ListFromImage(
    img.Image image,
    Float32List targetBuffer, {
    int targetWidth = 640,
    int targetHeight = 640,
  }) {
    final double scale = min(targetWidth / image.width, targetHeight / image.height);
    final int activeWidth = (image.width * scale).round();
    final int activeHeight = (image.height * scale).round();
    final int padX = (targetWidth - activeWidth) ~/ 2;
    final int padY = (targetHeight - activeHeight) ~/ 2;

    targetBuffer.fillRange(0, targetBuffer.length, yoloPadValue);

    final resized = img.copyResize(image, width: activeWidth, height: activeHeight);
    final lut = _normalizedLut;

    for (int y = 0; y < activeHeight; y++) {
      final int targetY = padY + y;
      final int rowOffset = targetY * targetWidth * 3;
      for (int x = 0; x < activeWidth; x++) {
        final int targetX = padX + x;
        final pixel = resized.getPixel(x, y);
        final int pxIdx = rowOffset + targetX * 3;
        targetBuffer[pxIdx] = lut[pixel.r.toInt().clamp(0, 255)];
        targetBuffer[pxIdx + 1] = lut[pixel.g.toInt().clamp(0, 255)];
        targetBuffer[pxIdx + 2] = lut[pixel.b.toInt().clamp(0, 255)];
      }
    }

    return LetterboxInfo(
      scale: scale,
      padX: padX,
      padY: padY,
      activeWidth: activeWidth,
      activeHeight: activeHeight,
    );
  }

  /// Decodes JPEG/PNG bytes into img.Image
  static img.Image? decodeImageBytes(Uint8List bytes) {
    return img.decodeImage(bytes);
  }
}
