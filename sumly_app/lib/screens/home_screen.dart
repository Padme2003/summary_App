import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'dashboard_screen.dart';
import 'library_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;

  const HomeScreen({super.key, this.initialTab = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedIndex;

  void _changeTab(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> get _pages => [
    DashboardScreen(onTabChange: _changeTab),
    const LibraryScreen(),
    const FavoritesScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
          indicatorColor: isDark
              ? AppColors.gold.withOpacity(0.2)
              : AppColors.brown.withOpacity(0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              selectedIcon: Icon(
                Icons.home,
                color: isDark ? AppColors.gold : AppColors.brown,
              ),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.library_books_outlined,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              selectedIcon: Icon(
                Icons.library_books,
                color: isDark ? AppColors.gold : AppColors.brown,
              ),
              label: 'Biblioteca',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.favorite_outline,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              selectedIcon: Icon(
                Icons.favorite,
                color: isDark ? AppColors.gold : AppColors.brown,
              ),
              label: 'Favoritos',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
              selectedIcon: Icon(
                Icons.person,
                color: isDark ? AppColors.gold : AppColors.brown,
              ),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
