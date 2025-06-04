import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/library_database.dart';
import '../models/book.dart';
import 'package:uuid/uuid.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreBooks();
    }
  }

  Future<void> _loadMoreBooks() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final database = Provider.of<LibraryDatabase>(context, listen: false);
      await database.loadMoreBooks();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<LibraryDatabase>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Books',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: database.isLoadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading && database.books.value.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ValueListenableBuilder<Map<String, Book>>(
            valueListenable: database.books,
            builder: (context, books, child) {
              final booksList = books.values.toList();

              if (booksList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.book,
                        size: 72,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No books available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add some books to get started!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(const Duration(seconds: 1));
                      if (mounted) setState(() {});
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: booksList.length + 1,
                      itemBuilder: (context, index) {
                        if (index == booksList.length) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: database.hasMoreBooksNotifier,
                            builder: (context, hasMore, _) {
                              if (!hasMore) return const SizedBox.shrink();

                              return Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              );
                            },
                          );
                        }

                        final book = booksList[index];
                        return _buildBookCard(book, database);
                      },
                    ),
                  ),
                  if (isLoading && books.isNotEmpty)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_book_fab',
        onPressed: () => _showAddBookDialog(context, database),
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
      ),
    );
  }

  Widget _buildBookCard(Book book, LibraryDatabase database) {
    final statusColor = _getStatusColor(book.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _deleteBook(context, database, book.id),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Book icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.book,
                  color: statusColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Book details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'by ${book.author}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (book.publisher.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        book.publisher,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Status chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  _getStatusText(book.status),
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(BookStatus status) {
    switch (status) {
      case BookStatus.available:
        return Colors.green;
      case BookStatus.borrowed:
        return Colors.orange;
      case BookStatus.maintenance:
        return Colors.red;
    }
  }

  String _getStatusText(BookStatus status) {
    switch (status) {
      case BookStatus.available:
        return 'Available';
      case BookStatus.borrowed:
        return 'Borrowed';
      case BookStatus.maintenance:
        return 'Maintenance';
    }
  }

  void _deleteBook(
      BuildContext context, LibraryDatabase database, String bookId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Book'),
        content: const Text('Are you sure you want to delete this book?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await database.deleteBook(bookId);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Book deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting book: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddBookDialog(BuildContext context, LibraryDatabase database) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final publisherController = TextEditingController();
    final isbnController = TextEditingController();
    final publishYearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Book'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(titleController, 'Title', Icons.title),
              const SizedBox(height: 16),
              _buildTextField(authorController, 'Author', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(publisherController, 'Publisher', Icons.business),
              const SizedBox(height: 16),
              _buildTextField(isbnController, 'ISBN', Icons.numbers),
              const SizedBox(height: 16),
              _buildTextField(
                publishYearController,
                'Publish Year',
                Icons.calendar_today,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty &&
                  authorController.text.isNotEmpty) {
                try {
                  final book = Book(
                    id: const Uuid().v4(),
                    title: titleController.text,
                    author: authorController.text,
                    publisher: publisherController.text,
                    isbn: isbnController.text,
                    publishYear: int.tryParse(publishYearController.text) ??
                        DateTime.now().year,
                  );
                  await database.addBook(book);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Book added successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error adding book: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
