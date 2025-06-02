import 'package:flutter/material.dart';
import 'package:library_management_with_flutter_oop/providers/notifiers.dart';
import 'home_screen.dart';
import 'book_list_screen.dart';
import 'student_list_screen.dart';
import 'history_screen.dart';

List<Widget> screens = const [
  HomeScreen(),
  BookListScreen(),
  StudentListScreen(),
  HistoryScreen(),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  void _onItemTapped(int index) {
    selectedPageNotifier.value = index;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedIndex, child) {
          return screens[selectedIndex];
        },
      ),
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: selectedPageNotifier,
        builder: (context, selectedIndex, child) {
          return NavigationBar(
            backgroundColor: Colors.white,
            indicatorColor: Colors.blue,
            indicatorShape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.book),
                label: 'Books',
              ),
              NavigationDestination(
                icon: Icon(Icons.person),
                label: 'Students',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'History',
              ),
            ],
            onDestinationSelected: _onItemTapped,
            selectedIndex: selectedIndex,
          );
        },
      ),
    );
  }
}
