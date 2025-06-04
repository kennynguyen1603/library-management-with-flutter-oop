import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/book.dart';
import '../models/borrow_record.dart';
import '../services/library_database.dart';
import 'package:provider/provider.dart';
import '../screens/borrow_book_screen.dart';

class StudentDetailScreen extends StatelessWidget {
  final Student student;

  const StudentDetailScreen({
    super.key,
    required this.student,
  });

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<LibraryDatabase>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          student.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showEditDialog(context, database),
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Column(
        children: [
          // Student Info Header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    student.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${student.studentId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      if (student.className.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Class: ${student.className}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Contact Info (if available)
          if (student.email.isNotEmpty || student.phoneNumber.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (student.email.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.email,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          student.email,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (student.phoneNumber.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.phone,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          student.phoneNumber,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Borrowed Books Section
          Expanded(
            child: ValueListenableBuilder<Map<String, BorrowRecord>>(
              valueListenable: database.borrowRecords,
              builder: (context, borrowRecords, _) {
                final studentBorrowedBooks = borrowRecords.values
                    .where((record) =>
                        record.student.id == student.id &&
                        record.isReturned == false)
                    .map((record) => record.book)
                    .toList();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Borrowed Books',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${studentBorrowedBooks.length}/3 books',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            FilledButton.icon(
                              onPressed: studentBorrowedBooks.length >= 3
                                  ? null
                                  : () =>
                                      _showBorrowBookDialog(context, database),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Borrow'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: studentBorrowedBooks.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.book_outlined,
                                      size: 64,
                                      color: Colors.grey[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No books borrowed',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap the borrow button to add books',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  bottom: 16,
                                ),
                                itemCount: studentBorrowedBooks.length,
                                itemBuilder: (context, index) {
                                  final book = studentBorrowedBooks[index];
                                  return _buildBorrowedBookCard(
                                      book, context, database);
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBorrowedBookCard(
      Book book, BuildContext context, LibraryDatabase database) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.book,
                color: Colors.orange.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () => _returnBook(context, database, book),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Return'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(BuildContext context, LibraryDatabase database) {
    final nameController = TextEditingController(text: student.name);
    final classController = TextEditingController(text: student.className);
    final emailController = TextEditingController(text: student.email);
    final phoneController = TextEditingController(text: student.phoneNumber);

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Student Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Full Name', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(classController, 'Class', Icons.class_),
              const SizedBox(height: 16),
              _buildTextField(
                emailController,
                'Email',
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                phoneController,
                'Phone Number',
                Icons.phone,
                keyboardType: TextInputType.phone,
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
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final updatedStudent = Student(
                  id: student.id,
                  studentId: student.studentId,
                  name: nameController.text,
                  className: classController.text,
                  email: emailController.text,
                  phoneNumber: phoneController.text,
                );
                database.updateStudent(updatedStudent);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student information updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
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

  Future<void> _showBorrowBookDialog(
      BuildContext context, LibraryDatabase database) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BorrowBookScreen(student: student),
      ),
    );
  }

  void _returnBook(BuildContext context, LibraryDatabase database, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Return Book'),
        content: Text('Are you sure you want to return "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await database.returnBook(book.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully returned "${book.title}"'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Return'),
          ),
        ],
      ),
    );
  }
}
