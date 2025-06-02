import 'package:flutter/material.dart';
import '../models/book.dart';

class BorrowedBooksList extends StatelessWidget {
  final Stream<List<Book>> stream;
  final VoidCallback onAddPressed;
  final Function(Book) onReturnPressed;

  const BorrowedBooksList({
    super.key,
    required this.stream,
    required this.onAddPressed,
    required this.onReturnPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sách đang mượn',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FilledButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add),
                label: const Text('Mượn sách'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Book>>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có sách nào được mượn',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                      ),
                    ],
                  ),
                );
              }

              final books = snapshot.data!;
              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.book),
                      ),
                      title: Text(book.title),
                      subtitle: Text(book.author),
                      trailing: TextButton.icon(
                        onPressed: () => onReturnPressed(book),
                        icon: const Icon(Icons.check),
                        label: const Text('Trả sách'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
