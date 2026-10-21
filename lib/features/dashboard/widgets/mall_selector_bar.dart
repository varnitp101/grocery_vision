import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/haptic_service.dart';
import '../../../services/tts_service.dart';
import '../providers/mall_provider.dart';

class MallSelectorBar extends ConsumerWidget {
  const MallSelectorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mallState = ref.watch(mallProvider);
    final activeMallName = mallState.displayName;

    return Semantics(
      label: 'Selected Mall: $activeMallName. Tap to change your shopping mall.',
      button: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main Bar Card
          GestureDetector(
            onTap: () => _openMallSelectionSheet(context, ref),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2042),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.primaryAmber.withAlpha(160),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(60),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Storefront Icon Block
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.darkNavy,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryAmber.withAlpha(100),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: AppTheme.primaryAmber,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SELECT YOUR MALL',
                          style: TextStyle(
                            color: AppTheme.primaryAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeMallName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Change Chip / Chevron
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryAmber.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryAmber.withAlpha(90),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'CHANGE',
                          style: TextStyle(
                            color: AppTheme.primaryAmber,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primaryAmber,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Selection Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickPill(
                  context,
                  ref,
                  label: 'DMart',
                  isSelected: mallState.selectedMall == 'DMart',
                  onTap: () => _selectQuickMall(ref, 'DMart'),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  context,
                  ref,
                  label: 'Reliance Smart Bazaar',
                  isSelected: mallState.selectedMall == 'Reliance Smart Bazaar',
                  onTap: () => _selectQuickMall(ref, 'Reliance Smart Bazaar'),
                ),
                const SizedBox(width: 8),
                _buildQuickPill(
                  context,
                  ref,
                  label: mallState.selectedMall == 'Others' &&
                          mallState.customMallName.isNotEmpty
                      ? mallState.customMallName
                      : 'Others...',
                  isSelected: mallState.selectedMall == 'Others',
                  onTap: () {
                    if (mallState.selectedMall == 'Others') {
                      _openMallSelectionSheet(context, ref);
                    } else {
                      _selectQuickMall(ref, 'Others', openSheetIfCustom: true, context: context);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPill(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryAmber : const Color(0xFF0F2042),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryAmber
                : Colors.white.withAlpha(40),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.darkNavy,
                size: 14,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.darkNavy : Colors.white70,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectQuickMall(
    WidgetRef ref,
    String mallName, {
    bool openSheetIfCustom = false,
    BuildContext? context,
  }) {
    ref.read(hapticServiceProvider).detectionStable();
    ref.read(mallProvider.notifier).selectMall(mallName);
    ref.read(ttsServiceProvider).speak(
          'Shopping at $mallName',
          priority: TtsPriority.immediate,
        );

    if (openSheetIfCustom && context != null) {
      _openMallSelectionSheet(context, ref);
    }
  }

  void _openMallSelectionSheet(BuildContext context, WidgetRef ref) {
    ref.read(hapticServiceProvider).captureTriggered();
    ref.read(ttsServiceProvider).speak(
          'Select your shopping mall: DMart, Reliance Smart Bazaar, or Others.',
          priority: TtsPriority.immediate,
        );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _MallSelectionSheet(parentRef: ref),
    );
  }
}

class _MallSelectionSheet extends StatefulWidget {
  final WidgetRef parentRef;

  const _MallSelectionSheet({required this.parentRef});

  @override
  State<_MallSelectionSheet> createState() => _MallSelectionSheetState();
}

class _MallSelectionSheetState extends State<_MallSelectionSheet> {
  late final TextEditingController _customController;
  bool _isEnteringCustom = false;

  @override
  void initState() {
    super.initState();
    final mallState = widget.parentRef.read(mallProvider);
    _customController = TextEditingController(text: mallState.customMallName);
    _isEnteringCustom = mallState.selectedMall == 'Others';
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mallState = widget.parentRef.watch(mallProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF07142A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppTheme.primaryAmber, width: 3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.store_rounded, color: AppTheme.primaryAmber, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'SELECT YOUR MALL',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 26),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the store where you are currently shopping for tailored aisle and catalog guidance.',
            style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 18),

          // Options List
          ...mallState.presetMalls.map((mall) {
            final isSelected = mallState.selectedMall == mall.name;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Semantics(
                button: true,
                selected: isSelected,
                label: '${mall.name}. ${mall.tagline}',
                child: InkWell(
                  onTap: () {
                    widget.parentRef.read(hapticServiceProvider).productFound();
                    if (mall.name == 'Others') {
                      setState(() {
                        _isEnteringCustom = true;
                      });
                      widget.parentRef.read(mallProvider.notifier).selectMall('Others');
                    } else {
                      widget.parentRef.read(mallProvider.notifier).selectMall(mall.name);
                      widget.parentRef.read(ttsServiceProvider).speak(
                            'Shopping at ${mall.name}. Ready to scan.',
                            priority: TtsPriority.immediate,
                          );
                      Navigator.of(context).pop();
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryAmber.withAlpha(35)
                          : const Color(0xFF0F2042),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryAmber
                            : Colors.white.withAlpha(30),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryAmber
                                : Colors.white.withAlpha(15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            mall.name == 'DMart'
                                ? Icons.shopping_basket_rounded
                                : mall.name == 'Reliance Smart Bazaar'
                                    ? Icons.shopping_bag_rounded
                                    : mall.name == 'More Supermarket'
                                        ? Icons.local_grocery_store_rounded
                                        : Icons.storefront_outlined,
                            color: isSelected ? AppTheme.darkNavy : AppTheme.primaryAmber,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mall.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected ? FontWeight.w900 : FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                mall.tagline,
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryAmber
                                  : Colors.white38,
                              width: 2,
                            ),
                            color: isSelected
                                ? AppTheme.primaryAmber
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: AppTheme.darkNavy,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          // If 'Others' selected, show custom name input field
          if (_isEnteringCustom) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2042),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryAmber, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'ENTER YOUR STORE / SUPERMARKET NAME:',
                    style: TextStyle(
                      color: AppTheme.primaryAmber,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: 'e.g. Spencer\'s, Nature\'s Basket, Local Shop',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                      filled: true,
                      fillColor: AppTheme.darkNavy,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withAlpha(50)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.primaryAmber, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final customName = _customController.text.trim();
                      if (customName.isNotEmpty) {
                        widget.parentRef.read(mallProvider.notifier).setCustomMall(customName);
                        widget.parentRef.read(ttsServiceProvider).speak(
                              'Shopping at $customName. Ready to scan.',
                              priority: TtsPriority.immediate,
                            );
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAmber,
                      foregroundColor: AppTheme.darkNavy,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'SAVE STORE NAME',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.0),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
