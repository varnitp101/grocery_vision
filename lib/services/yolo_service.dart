import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/yolo_detection.dart';
import '../utils/image_converter.dart';

class YoloService {
  Interpreter? _interpreter;

  List<String> _labels = [
    'Chaizop Tea Mix',
    'Dark Fantasy Bourbon',
    'Dark Fantasy Sandwich Creme',
    'WishCare Shampoo',
  ];
  bool _isModelLoaded = false;
  bool _isBusy = false;

  int _inputWidth = 320;
  int _inputHeight = 320;
  int _numAttributes = 8; // 4 box coords + 4 classes
  int _numAnchors = 2100;

  // Dynamically sized flat Float32List buffers for 0.1ms native memcpy in tflite_flutter
  Float32List _inputBuffer = Float32List(1 * 320 * 320 * 3);
  Float32List _outputBuffer = Float32List(1 * 8 * 2100);

  // Temporal stability tracking
  String? _lastCandidateClass;
  int _consecutiveHits = 0;
  static const int minConsecutiveFrames = 2;

  // Duplicate suppression
  String? _lastAnnouncedClass;
  DateTime? _lastDetectionTime;
  static const Duration duplicateCooldown = Duration(seconds: 2);

  // Silence reminder tracking
  DateTime? _lastSilenceReminderTime;
  static const Duration silenceReminderInterval = Duration(seconds: 8);

  bool get isModelLoaded => _isModelLoaded;
  List<String> get labels => _labels;
  int get inputWidth => _inputWidth;
  int get inputHeight => _inputHeight;

  Future<void> initialize() async {
    if (_isModelLoaded) return;
    try {
      try {
        final labelsData = await rootBundle.loadString('assets/models/labels.txt');
        final lines = labelsData
            .split('\n')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (lines.isNotEmpty) {
          _labels = lines;
        }
      } catch (_) {
        _labels = [
          'Chaizop Tea Mix',
          'Dark Fantasy Bourbon',
          'Dark Fantasy Sandwich Creme',
          'WishCare Shampoo',
        ];
      }

      final options = InterpreterOptions()..threads = 4;
      try {
        _interpreter = await Interpreter.fromAsset(
          'assets/models/weights_int8.tflite',
          options: options,
        );
      } catch (_) {
        _interpreter = await Interpreter.fromAsset(
          'assets/models/best_int8.tflite',
          options: options,
        );
      }

      final inT = _interpreter!.getInputTensor(0);
      final outT = _interpreter!.getOutputTensor(0);

      // Dynamically adapt to model input & output tensor dimensions
      _inputHeight = inT.shape[1];
      _inputWidth = inT.shape[2];
      _numAttributes = outT.shape[1];
      _numAnchors = outT.shape[2];

      _inputBuffer = Float32List(1 * _inputHeight * _inputWidth * 3);
      _outputBuffer = Float32List(1 * _numAttributes * _numAnchors);

      _isModelLoaded = true;
      debugPrint('YoloService: Model initialized successfully. Labels: $_labels');
      debugPrint('YoloService: in=${inT.shape} type=${inT.type}, out=${outT.shape} type=${outT.type} (anchors=$_numAnchors)');
    } catch (e) {
      debugPrint('YoloService: Model failed to load: $e');
      _isModelLoaded = false;
    }
  }

  String getDisplayName(String rawName) {
    if (rawName.isEmpty) return 'Grocery Item';
    return rawName.replaceAll('_', ' ');
  }

  /// High-performance live inference directly from camera stream via flat buffer
  Future<List<YoloDetection>> detectFromCameraImage(
    CameraImage cameraImage, {
    int sensorOrientation = 90,
    double confidenceThreshold = 0.25,
  }) async {
    if (!_isModelLoaded || _interpreter == null || _isBusy) {
      return [];
    }

    _isBusy = true;
    try {
      final letterbox = ImageConverter.fillLetterboxedFloat32List(
        cameraImage,
        _inputBuffer,
        sensorOrientation: sensorOrientation,
        targetWidth: _inputWidth,
        targetHeight: _inputHeight,
      );

      if (letterbox == null) return [];

      // Direct native C memcpy execution
      _interpreter!.run(_inputBuffer.buffer, _outputBuffer.buffer);

      return _parseOutput(
        output: _outputBuffer,
        confidenceThreshold: confidenceThreshold,
        letterbox: letterbox,
      );
    } catch (e, stack) {
      debugPrint('YoloService error: $e\n$stack');
      return [];
    } finally {
      _isBusy = false;
    }
  }

  /// Inference on a static decoded Image
  Future<List<YoloDetection>> detect({
    required img.Image image,
    double confidenceThreshold = 0.25,
  }) async {
    if (!_isModelLoaded || _interpreter == null || _isBusy) {
      return [];
    }

    _isBusy = true;
    try {
      final letterbox = ImageConverter.fillPlanarFloat32ListFromImage(
        image,
        _inputBuffer,
        targetWidth: _inputWidth,
        targetHeight: _inputHeight,
      );

      _interpreter!.run(_inputBuffer.buffer, _outputBuffer.buffer);

      return _parseOutput(
        output: _outputBuffer,
        confidenceThreshold: confidenceThreshold,
        letterbox: letterbox,
      );
    } catch (e, stack) {
      debugPrint('YoloService error: $e\n$stack');
      return [];
    } finally {
      _isBusy = false;
    }
  }

  List<YoloDetection> _parseOutput({
    required Float32List output,
    required double confidenceThreshold,
    LetterboxInfo? letterbox,
  }) {
    final List<YoloDetection> candidates = [];
    final numClasses = _labels.length;
    double highestScore = 0.0;
    int highestClass = -1;

    for (int i = 0; i < _numAnchors; i++) {
      double maxClassScore = 0.0;
      int bestClassIdx = -1;

      for (int c = 0; c < numClasses; c++) {
        final rawScore = output[(4 + c) * _numAnchors + i];
        double score = rawScore;
        // If raw score is logit, apply sigmoid
        if (score < 0.0 || score > 1.0) {
          score = 1.0 / (1.0 + exp(-rawScore));
        }

        if (score > maxClassScore) {
          maxClassScore = score;
          bestClassIdx = c;
        }
      }

      if (maxClassScore > highestScore) {
        highestScore = maxClassScore;
        highestClass = bestClassIdx;
      }

      if (maxClassScore >= confidenceThreshold && bestClassIdx >= 0) {
        final double cx = output[0 * _numAnchors + i];
        final double cy = output[1 * _numAnchors + i];
        final double w = output[2 * _numAnchors + i];
        final double h = output[3 * _numAnchors + i];

        double normX;
        double normY;
        double normW;
        double normH;

        if (letterbox != null) {
          // Unpad from letterboxed tensor back to normalized camera frame (0..1)
          normX = (cx - letterbox.padX) / letterbox.activeWidth;
          normY = (cy - letterbox.padY) / letterbox.activeHeight;
          normW = w / letterbox.activeWidth;
          normH = h / letterbox.activeHeight;
        } else {
          normX = cx / _inputWidth;
          normY = cy / _inputHeight;
          normW = w / _inputWidth;
          normH = h / _inputHeight;
        }

        // Only accept detections that fall within the active camera bounds
        if (normX < -0.1 || normX > 1.1 || normY < -0.1 || normY > 1.1) {
          continue;
        }

        final rawClassName = _labels[bestClassIdx];
        final displayName = getDisplayName(rawClassName);

        candidates.add(
          YoloDetection(
            classIndex: bestClassIdx,
            className: rawClassName,
            displayName: displayName,
            confidence: maxClassScore,
            x: normX.clamp(0.0, 1.0),
            y: normY.clamp(0.0, 1.0),
            width: normW.clamp(0.0, 1.0),
            height: normH.clamp(0.0, 1.0),
          ),
        );
      }
    }

    debugPrint(
      'YOLO: top=${highestClass >= 0 ? _labels[highestClass] : "none"} conf=${(highestScore * 100).toStringAsFixed(1)}% (thresh: ${(confidenceThreshold * 100).toInt()}%, cands: ${candidates.length})',
    );

    if (candidates.isEmpty) return [];

    // Sort by confidence descending
    candidates.sort((a, b) => b.confidence.compareTo(a.confidence));

    // Apply strict cross-class NMS to guarantee only 1 label per physical item
    return _applyCrossClassNms(candidates, iouThreshold: 0.45);
  }

  /// Cross-class NMS: If any two candidate bounding boxes overlap by > iouThreshold,
  /// keep ONLY the one with the higher confidence score.
  /// Prevents multiple labels from ever appearing over the same detected product.
  List<YoloDetection> _applyCrossClassNms(List<YoloDetection> boxes, {double iouThreshold = 0.45}) {
    final List<YoloDetection> selected = [];

    for (final box in boxes) {
      bool keep = true;
      for (final kept in selected) {
        final iou = _calculateIoU(box, kept);
        if (iou > iouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) {
        selected.add(box);
        if (selected.length >= 5) break;
      }
    }

    return selected;
  }

  double _calculateIoU(YoloDetection a, YoloDetection b) {
    final aLeft = a.x - a.width / 2;
    final aRight = a.x + a.width / 2;
    final aTop = a.y - a.height / 2;
    final aBottom = a.y + a.height / 2;

    final bLeft = b.x - b.width / 2;
    final bRight = b.x + b.width / 2;
    final bTop = b.y - b.height / 2;
    final bBottom = b.y + b.height / 2;

    final intersectionLeft = max(aLeft, bLeft);
    final intersectionTop = max(aTop, bTop);
    final intersectionRight = min(aRight, bRight);
    final intersectionBottom = min(aBottom, bBottom);

    if (intersectionRight < intersectionLeft || intersectionBottom < intersectionTop) {
      return 0.0;
    }

    final intersectionArea =
        (intersectionRight - intersectionLeft) * (intersectionBottom - intersectionTop);
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    final unionArea = areaA + areaB - intersectionArea;

    return unionArea > 0 ? (intersectionArea / unionArea) : 0.0;
  }

  String? processTemporalStability(List<YoloDetection> detections) {
    final now = DateTime.now();

    if (detections.isEmpty) {
      if (_lastDetectionTime != null &&
          now.difference(_lastDetectionTime!) > duplicateCooldown) {
        _lastAnnouncedClass = null;
      }
      _lastCandidateClass = null;
      _consecutiveHits = 0;
      return null;
    }

    final winner = detections.first;
    _lastDetectionTime = now;

    if (winner.className == _lastCandidateClass) {
      _consecutiveHits++;
    } else {
      _lastCandidateClass = winner.className;
      _consecutiveHits = 1;
    }

    if (_consecutiveHits >= minConsecutiveFrames) {
      if (winner.className != _lastAnnouncedClass) {
        _lastAnnouncedClass = winner.className;
        return winner.displayName;
      }
    }

    return null;
  }

  bool shouldTriggerSilenceReminder() {
    final now = DateTime.now();
    if (_lastDetectionTime == null ||
        now.difference(_lastDetectionTime!) > silenceReminderInterval) {
      if (_lastSilenceReminderTime == null ||
          now.difference(_lastSilenceReminderTime!) > silenceReminderInterval) {
        _lastSilenceReminderTime = now;
        return true;
      }
    }
    return false;
  }

  void resetStability() {
    _lastCandidateClass = null;
    _consecutiveHits = 0;
    _lastAnnouncedClass = null;
    _lastDetectionTime = null;
    _lastSilenceReminderTime = null;
  }

  void dispose() {
    try {
      _interpreter?.close();
    } catch (_) {}
    _interpreter = null;
    _isModelLoaded = false;
  }
}

final yoloServiceProvider = Provider<YoloService>((ref) {
  final service = YoloService();
  service.initialize();
  ref.onDispose(() => service.dispose());
  return service;
});
