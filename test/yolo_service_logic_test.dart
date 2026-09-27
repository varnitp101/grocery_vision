import 'package:flutter_test/flutter_test.dart';
import 'package:grocery_vision/models/yolo_detection.dart';
import 'package:grocery_vision/services/yolo_service.dart';

void main() {
  group('YOLO Service Logic Tests', () {
    late YoloService yoloService;

    setUp(() {
      yoloService = YoloService();
    });

    test('Temporal stability requires 2 consecutive frames of same class', () {
      const detectionBhujiya = YoloDetection(
        classIndex: 0,
        className: 'bhujiya',
        displayName: 'Bhujiya',
        confidence: 0.85,
        x: 0.5,
        y: 0.5,
        width: 0.4,
        height: 0.4,
      );

      // Frame 1: 1 hit -> null
      expect(yoloService.processTemporalStability([detectionBhujiya]), isNull);

      // Frame 2: 2 hits -> returns "Bhujiya"
      expect(yoloService.processTemporalStability([detectionBhujiya]), 'Bhujiya');

      // Frame 3: 3 hits (duplicate suppression) -> null
      expect(yoloService.processTemporalStability([detectionBhujiya]), isNull);
    });

    test('Switching candidate class resets consecutive hits counter', () {
      const detectionDorito = YoloDetection(
        classIndex: 1,
        className: 'dorito',
        displayName: 'Dorito',
        confidence: 0.80,
        x: 0.5,
        y: 0.5,
        width: 0.4,
        height: 0.4,
      );

      const detectionMaggie = YoloDetection(
        classIndex: 2,
        className: 'maggie_masala',
        displayName: 'Maggie Masala',
        confidence: 0.75,
        x: 0.5,
        y: 0.5,
        width: 0.4,
        height: 0.4,
      );

      // 1 hit of Dorito
      expect(yoloService.processTemporalStability([detectionDorito]), isNull);

      // Switch to Maggie -> resets counter
      expect(yoloService.processTemporalStability([detectionMaggie]), isNull);
      // 2nd hit of Maggie -> triggers announcement
      expect(yoloService.processTemporalStability([detectionMaggie]), 'Maggie Masala');
    });

    test('Empty detections reset candidate counter', () {
      const detectionBhujiya = YoloDetection(
        classIndex: 0,
        className: 'bhujiya',
        displayName: 'Bhujiya',
        confidence: 0.85,
        x: 0.5,
        y: 0.5,
        width: 0.4,
        height: 0.4,
      );

      expect(yoloService.processTemporalStability([detectionBhujiya]), isNull);

      // Empty frame
      expect(yoloService.processTemporalStability([]), isNull);

      // Next frame of Bhujiya starts from 1 again
      expect(yoloService.processTemporalStability([detectionBhujiya]), isNull);
      expect(yoloService.processTemporalStability([detectionBhujiya]), 'Bhujiya');
    });
  });
}
