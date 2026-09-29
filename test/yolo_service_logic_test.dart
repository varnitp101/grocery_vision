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
      const detectionChaizop = YoloDetection(
        classIndex: 0,
        className: 'Chaizop Tea Mix',
        displayName: 'Chaizop Tea Mix',
        confidence: 0.85,
        x: 0.5,
        y: 0.5,
        width: 0.4,
        height: 0.4,
      );

      // Frame 1: 1 hit -> null
      expect(yoloService.processTemporalStability([detectionChaizop]), isNull);

      // Frame 2: 2 hits -> returns "Chaizop Tea Mix"
      expect(yoloService.processTemporalStability([detectionChaizop]), 'Chaizop Tea Mix');

      // Frame 3: 3 hits (duplicate suppression) -> null
      expect(yoloService.processTemporalStability([detectionChaizop]), isNull);
    });

    test('Switching candidate class resets consecutive hits counter', () {
      const detectionBourbon = YoloDetection(
        classIndex: 1,
        className: 'Dark Fantasy Bourbon',
        displayName: 'Dark Fantasy Bourbon',
        confidence: 0.80,
        x: 0.5,
        y: 0.5,
        width: 0.4,
        height: 0.4,
      );

      const detectionCreme = YoloDetection(
        classIndex: 2,
        className: 'Dark Fantasy Sandwich Creme',
        displayName: 'Dark Fantasy Sandwich Creme',
        confidence: 0.75,
        x: 0.5,
        y: 0.5,
        width: 0.4,
        height: 0.4,
      );

      // 1 hit of Bourbon
      expect(yoloService.processTemporalStability([detectionBourbon]), isNull);

      // Switch to Creme -> resets counter
      expect(yoloService.processTemporalStability([detectionCreme]), isNull);
      // 2nd hit of Creme -> triggers announcement
      expect(yoloService.processTemporalStability([detectionCreme]), 'Dark Fantasy Sandwich Creme');
    });

    test('Empty detections reset candidate counter', () {
      const detectionChaizop = YoloDetection(
        classIndex: 0,
        className: 'Chaizop Tea Mix',
        displayName: 'Chaizop Tea Mix',
        confidence: 0.85,
        x: 0.5,
        y: 0.5,
        width: 0.4,
        height: 0.4,
      );

      expect(yoloService.processTemporalStability([detectionChaizop]), isNull);

      // Empty frame
      expect(yoloService.processTemporalStability([]), isNull);

      // Next frame of Chaizop starts from 1 again
      expect(yoloService.processTemporalStability([detectionChaizop]), isNull);
      expect(yoloService.processTemporalStability([detectionChaizop]), 'Chaizop Tea Mix');
    });
  });
}
