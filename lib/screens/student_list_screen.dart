import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/library_database.dart';
import '../models/student.dart';
import '../models/borrow_record.dart';
import 'package:uuid/uuid.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreStudents();
    }
  }

  Future<void> _loadMoreStudents() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final database = Provider.of<LibraryDatabase>(context, listen: false);
      await database.loadMoreStudents();
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
          'Students',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search students...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Colors.blue.shade300, width: 1.5),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: database.isLoadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading && database.students.value.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder<Map<String, Student>>(
            valueListenable: database.students,
            builder: (context, students, child) {
              final studentsList = students.values.toList();
              final filteredStudents = _searchQuery.isEmpty
                  ? studentsList
                  : studentsList
                      .where((student) =>
                          student.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          student.studentId
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          student.className
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList();

              if (filteredStudents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isEmpty ? Icons.people : Icons.search_off,
                        size: 72,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No students registered'
                            : 'No students found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_searchQuery.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          '"$_searchQuery"',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
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
                      itemCount: filteredStudents.length +
                          (_searchQuery.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredStudents.length) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: database.hasMoreStudentsNotifier,
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

                        final student = filteredStudents[index];
                        return _buildStudentCard(student, database);
                      },
                    ),
                  ),
                  if (isLoading && students.isNotEmpty)
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
        heroTag: 'add_student_fab',
        onPressed: () => _showAddStudentDialog(context, database),
        icon: const Icon(Icons.add),
        label: const Text('Add Student'),
      ),
    );
  }

  Widget _buildStudentCard(Student student, LibraryDatabase database) {
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
              onPressed: (_) => _deleteStudent(context, database, student.id),
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
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentDetailScreen(student: student),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    student.name.isNotEmpty
                        ? student.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Student details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${student.studentId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (student.className.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Class: ${student.className}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Borrowed books chip
                _buildBorrowedBooksChip(student, database),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBorrowedBooksChip(Student student, LibraryDatabase database) {
    return ValueListenableBuilder<Map<String, BorrowRecord>>(
      valueListenable: database.borrowRecords,
      builder: (context, borrowRecords, _) {
        final borrowedCount = borrowRecords.values
            .where((record) =>
                record.student.id == student.id && !record.isReturned)
            .length;

        final color = borrowedCount >= 3 ? Colors.red : Colors.green;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color),
          ),
          child: Text(
            '$borrowedCount/3',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAddStudentDialog(
      BuildContext context, LibraryDatabase database) {
    final nameController = TextEditingController();
    final studentIdController = TextEditingController();
    final classController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Full Name', Icons.person),
              const SizedBox(height: 16),
              _buildTextField(studentIdController, 'Student ID', Icons.badge),
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
              if (nameController.text.isNotEmpty &&
                  studentIdController.text.isNotEmpty) {
                final student = Student(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  studentId: studentIdController.text,
                  className: classController.text,
                  email: emailController.text,
                  phoneNumber: phoneController.text,
                );
                database.addStudent(student);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Student added successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
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

  void _deleteStudent(
      BuildContext context, LibraryDatabase database, String studentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Student'),
        content: const Text('Are you sure you want to delete this student?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              database.deleteStudent(studentId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Student deleted successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
