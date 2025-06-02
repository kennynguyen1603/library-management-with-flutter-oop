import 'package:flutter/material.dart';
import '../models/book.dart';
import 'loading_state_widget.dart';

class BorrowedBooksList extends LoadingStateWidget<List<Book>> {
  final VoidCallback onAddPressed;
  final Function(Book) onReturnPressed;

  BorrowedBooksList({
    super.key,
    required super.stream,
    required this.onAddPressed,
    required this.onReturnPressed,
  }) : super(
          emptyMessage:
              'Bạn chưa mượn quyển sách nào\nNhấn \'Thêm\' để bắt đầu hành trình đọc sách!',
          emptyIcon: Icons.menu_book,
          onData: (data) => data.isEmpty
              ? const SizedBox()
              : ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final book = data[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(book.title),
                        subtitle: Text(book.author),
                        trailing: IconButton(
                          icon: const Icon(Icons.check_circle_outline),
                          onPressed: () => onReturnPressed(book),
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
        );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: super.build(context),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onAddPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Thêm',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
