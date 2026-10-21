import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/theme_provider.dart';

class MallInfo {
  final String id;
  final String name;
  final String tagline;
  final String category;

  const MallInfo({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
  });
}

class MallState {
  final String selectedMall;
  final String customMallName;
  final List<MallInfo> presetMalls;
  final bool isMallConfirmed;

  const MallState({
    required this.selectedMall,
    this.customMallName = '',
    required this.presetMalls,
    this.isMallConfirmed = false,
  });

  String get displayName {
    if (selectedMall == 'Others' && customMallName.trim().isNotEmpty) {
      return customMallName.trim();
    }
    return selectedMall;
  }

  MallState copyWith({
    String? selectedMall,
    String? customMallName,
    List<MallInfo>? presetMalls,
    bool? isMallConfirmed,
  }) {
    return MallState(
      selectedMall: selectedMall ?? this.selectedMall,
      customMallName: customMallName ?? this.customMallName,
      presetMalls: presetMalls ?? this.presetMalls,
      isMallConfirmed: isMallConfirmed ?? this.isMallConfirmed,
    );
  }
}

class MallNotifier extends StateNotifier<MallState> {
  final SharedPreferences _prefs;
  static const _mallKey = 'selected_grocery_mall';
  static const _customMallKey = 'custom_grocery_mall';
  static const _isMallConfirmedKey = 'is_mall_confirmed';

  static const List<MallInfo> defaultMalls = [
    MallInfo(
      id: 'dmart',
      name: 'DMart',
      tagline: 'Everyday Low Prices & Bulk Grocery',
      category: 'Hypermarket',
    ),
    MallInfo(
      id: 'reliance_smart_bazaar',
      name: 'Reliance Smart Bazaar',
      tagline: 'Big Savings on Daily Essentials',
      category: 'Supermarket',
    ),
    MallInfo(
      id: 'others',
      name: 'Others',
      tagline: 'Local Kirana, Spencer\'s, Nature\'s Basket, etc.',
      category: 'Custom Store',
    ),
  ];

  MallNotifier(this._prefs)
      : super(
          MallState(
            selectedMall: _prefs.getString(_mallKey) ?? 'DMart',
            customMallName: _prefs.getString(_customMallKey) ?? '',
            presetMalls: defaultMalls,
            isMallConfirmed: false, // Always prompt user to select mall on launch/restart
          ),
        ) {
    // Reset stored flag so every fresh app startup begins at the Select Mall gate
    _prefs.setBool(_isMallConfirmedKey, false);
  }

  void selectMall(String mallName) {
    state = state.copyWith(selectedMall: mallName);
    _prefs.setString(_mallKey, mallName);
  }

  void confirmMall(String mallName) {
    state = state.copyWith(
      selectedMall: mallName,
      isMallConfirmed: true,
    );
    _prefs.setString(_mallKey, mallName);
    _prefs.setBool(_isMallConfirmedKey, true);
  }

  void confirmCustomMall(String customName) {
    final trimmed = customName.trim();
    state = state.copyWith(
      selectedMall: 'Others',
      customMallName: trimmed,
      isMallConfirmed: true,
    );
    _prefs.setString(_mallKey, 'Others');
    _prefs.setString(_customMallKey, trimmed);
    _prefs.setBool(_isMallConfirmedKey, true);
  }

  void setCustomMall(String customName) {
    confirmCustomMall(customName);
  }

  void resetMallSelection() {
    state = state.copyWith(isMallConfirmed: false);
    _prefs.setBool(_isMallConfirmedKey, false);
  }
}

final mallProvider = StateNotifierProvider<MallNotifier, MallState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return MallNotifier(prefs);
});
