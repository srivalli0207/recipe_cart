import 'package:flutter/material.dart';
import 'package:recipe_cart/screens/home/home_screen.dart';
import 'package:recipe_cart/screens/browse/browse_screen.dart';
import 'package:recipe_cart/screens/shopping/shopping_list_screen.dart';
import 'package:recipe_cart/screens/meal_planning/meal_plan_screen.dart';
import 'package:recipe_cart/screens/profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const BrowseScreen(),
    const ShoppingListScreen(),
    const MealPlanScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = [
    'Home',
    'Browse',
    'Shopping List',
    'Meal Plan',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Meal Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}