import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/book.dart';
import '../services/library_database.dart';
import '../widgets/borrowed_books_list.dart';
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
      appBar: AppBar(
        title: Text(student.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context, database),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.withValues(alpha: 0.1),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue,
                  child: Text(
                    student.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
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
                        'Sinh viên',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.blue,
                                ),
                      ),
                      Text(
                        student.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (student.className.isNotEmpty)
                        Text(
                          'Lớp: ${student.className}',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showEditDialog(context, database),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Thay đổi'),
                ),
              ],
            ),
          ),
          Expanded(
            child: BorrowedBooksList(
              stream: database.getBorrowedBooksForStudent(student.id),
              onAddPressed: () => _showBorrowBookDialog(context, database),
              onReturnPressed: (book) => _returnBook(context, database, book),
            ),
          ),
        ],
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
        title: const Text('Chỉnh sửa thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              TextField(
                controller: classController,
                decoration: const InputDecoration(labelText: 'Lớp'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
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
              }
            },
            child: const Text('Lưu'),
          ),
        ],
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
        title: const Text('Trả sách'),
        content: Text('Bạn có chắc muốn trả sách "${book.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              database.returnBook(book.id);
              Navigator.pop(context);
            },
            child: const Text('Trả sách'),
          ),
        ],
      ),
    );
  }
}
