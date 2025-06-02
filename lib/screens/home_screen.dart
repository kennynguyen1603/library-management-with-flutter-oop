import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_database.dart';
import '../widgets/loading_state_widget.dart';
import 'book_list_screen.dart';
import 'student_list_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Management System'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<LibraryDatabase>(
          builder: (context, database, child) {
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              children: [
                _buildMenuCard(
                  context,
                  'Books',
                  Icons.book,
                  Colors.blue,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BookListScreen()),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Students',
                  Icons.people,
                  Colors.green,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const StudentListScreen()),
                  ),
                ),
                _buildMenuCard(
                  context,
                  'Borrow History',
                  Icons.history,
                  Colors.orange,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const HistoryScreen()),
                  ),
                ),
                LoadingStateWidget<int>(
                  stream: database.totalBooksStream,
                  emptyMessage: 'No books available',
                  emptyIcon: Icons.library_books,
                  onData: (totalBooks) {
                    return _buildStatsCard(
                      context,
                      'Total Books',
                      totalBooks.toString(),
                      Icons.library_books,
                      Colors.purple,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4.0,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48.0,
              color: color,
            ),
            const SizedBox(height: 16.0),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48.0,
            color: color,
          ),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8.0),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
