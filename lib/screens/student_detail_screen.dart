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
      appBar: AppBar(
        title: Text(student.name),
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
            child: ValueListenableBuilder<Map<String, BorrowRecord>>(
              valueListenable: database.borrowRecords,
              builder: (context, borrowRecords, _) {
                final studentBorrowedBooks = borrowRecords.values
                    .where((record) =>
                        record.student.id == student.id &&
                        record.isReturned == false)
                    .map((record) => record.book)
                    .toList();

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
                            onPressed: () =>
                                _showBorrowBookDialog(context, database),
                            icon: const Icon(Icons.add),
                            label: const Text('Mượn sách'),
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
                                    Icons.book,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Chưa có sách nào được mượn',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: studentBorrowedBooks.length,
                              itemBuilder: (context, index) {
                                final book = studentBorrowedBooks[index];
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
                                      onPressed: () =>
                                          _returnBook(context, database, book),
                                      icon: const Icon(Icons.check),
                                      label: const Text('Trả sách'),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
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
            onPressed: () async {
              try {
                await database.returnBook(book.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã trả sách "${book.title}" thành công'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lỗi: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Trả sách'),
          ),
        ],
      ),
    );
  }
}
