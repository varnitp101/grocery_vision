import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../../history/screens/history_screen.dart';
import '../../cart/screens/cart_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../../core/theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  final int initialIndex;
  const DashboardScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const CartScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkSurface,
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.darkNavy.withValues(alpha: 0.5),
          selectedItemColor: AppTheme.primaryAmber,
          unselectedItemColor: Colors.white54,
          currentIndex: _currentIndex,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled, size: 26),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded, size: 26),
              label: 'HISTORY',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart, size: 26),
              label: 'CART',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded, size: 26),
              label: 'PROFILE',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings, size: 26),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}
