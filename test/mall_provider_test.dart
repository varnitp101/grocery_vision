import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:grocery_vision/features/dashboard/providers/mall_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MallNotifier Tests', () {
    test('Initializes with default mall (DMart) and isMallConfirmed = false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = MallNotifier(prefs);

      expect(notifier.state.selectedMall, 'DMart');
      expect(notifier.state.displayName, 'DMart');
      expect(notifier.state.isMallConfirmed, false);
      expect(notifier.state.presetMalls.length, 3);
    });

    test('selectMall updates selected mall and persists', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = MallNotifier(prefs);

      notifier.selectMall('Reliance Smart Bazaar');
      expect(notifier.state.selectedMall, 'Reliance Smart Bazaar');
      expect(notifier.state.displayName, 'Reliance Smart Bazaar');
      expect(prefs.getString('selected_grocery_mall'), 'Reliance Smart Bazaar');
    });

    test('confirmMall sets isMallConfirmed to true', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = MallNotifier(prefs);

      notifier.confirmMall('Reliance Smart Bazaar');
      expect(notifier.state.selectedMall, 'Reliance Smart Bazaar');
      expect(notifier.state.isMallConfirmed, true);
    });

    test('confirmCustomMall sets Others, custom name, and isMallConfirmed', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = MallNotifier(prefs);

      notifier.confirmCustomMall('Nature\'s Basket');
      expect(notifier.state.selectedMall, 'Others');
      expect(notifier.state.customMallName, 'Nature\'s Basket');
      expect(notifier.state.displayName, 'Nature\'s Basket');
      expect(notifier.state.isMallConfirmed, true);
      expect(prefs.getString('selected_grocery_mall'), 'Others');
      expect(prefs.getString('custom_grocery_mall'), 'Nature\'s Basket');
    });

    test('resetMallSelection sets isMallConfirmed back to false', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final notifier = MallNotifier(prefs);

      notifier.confirmMall('DMart');
      expect(notifier.state.isMallConfirmed, true);

      notifier.resetMallSelection();
      expect(notifier.state.isMallConfirmed, false);
      expect(notifier.state.displayName, 'DMart');
    });

    test('Always resets isMallConfirmed = false on fresh app restart even if stored true', () async {
      SharedPreferences.setMockInitialValues({'is_mall_confirmed': true, 'selected_grocery_mall': 'Reliance Smart Bazaar'});
      final prefs = await SharedPreferences.getInstance();
      final notifier = MallNotifier(prefs);

      expect(notifier.state.selectedMall, 'Reliance Smart Bazaar');
      expect(notifier.state.isMallConfirmed, false);
      expect(prefs.getBool('is_mall_confirmed'), false);
    });
  });
}
