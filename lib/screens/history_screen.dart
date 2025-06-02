import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_database.dart';
import '../models/borrow_record.dart';
import '../models/student.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Student? _selectedStudent;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Widget _buildInfoRow(String label, String value, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: textColor,
                fontWeight: textColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BorrowRecord record) {
    final color = record.isReturned
        ? Colors.green
        : record.isOverdue
            ? Colors.red
            : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        record.isReturned
            ? 'Đã trả'
            : record.isOverdue
                ? 'Quá hạn'
                : 'Đang mượn',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = Provider.of<LibraryDatabase>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử mượn sách'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên sinh viên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _selectedStudent = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _selectedStudent = null;
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<BorrowRecord>>(
        stream: database.borrowRecordsStream,
        builder: (context, recordsSnapshot) {
          if (!recordsSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return StreamBuilder<List<Student>>(
            stream: database.studentsStream,
            builder: (context, studentsSnapshot) {
              if (!studentsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final records = recordsSnapshot.data!;
              final students = studentsSnapshot.data!;

              if (records.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có lịch sử mượn sách nào',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                );
              }

              // Filter students based on search query
              final filteredStudents = _searchQuery.isEmpty
                  ? students
                  : students
                      .where((student) => student.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();

              // If we have a search query but no matching students
              if (_searchQuery.isNotEmpty && filteredStudents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Không tìm thấy sinh viên với tên "$_searchQuery"',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // If we have a selected student, show their records
              if (_selectedStudent != null) {
                final studentRecords = records
                    .where(
                        (record) => record.student.id == _selectedStudent!.id)
                    .toList();

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.blue.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              _selectedStudent!.name[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedStudent!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  'Mã SV: ${_selectedStudent!.studentId} - Lớp: ${_selectedStudent!.className}',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _selectedStudent = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: studentRecords.isEmpty
                          ? Center(
                              child: Text(
                                'Sinh viên chưa mượn sách nào',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: studentRecords.length,
                              itemBuilder: (context, index) {
                                final record = studentRecords[index];
                                return _buildRecordCard(record);
                              },
                            ),
                    ),
                  ],
                );
              }

              // Show the list of students with borrowing history
              return ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = filteredStudents[index];
                  final studentRecords = records
                      .where((record) => record.student.id == student.id)
                      .toList();

                  if (studentRecords.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        student.name[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(student.name),
                    subtitle: Text(
                        'Mã SV: ${student.studentId} - ${studentRecords.length} lượt mượn'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      setState(() {
                        _selectedStudent = student;
                      });
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRecordCard(BorrowRecord record) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: record.isReturned
              ? Colors.green
              : record.isOverdue
                  ? Colors.red
                  : Colors.orange,
          child: Icon(
            record.isReturned
                ? Icons.check
                : record.isOverdue
                    ? Icons.warning
                    : Icons.book,
            color: Colors.white,
          ),
        ),
        title: Text(
          record.book.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          record.book.author,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildStatusChip(record),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Tác giả:', record.book.author),
                _buildInfoRow('Nhà xuất bản:', record.book.publisher),
                _buildInfoRow('ISBN:', record.book.isbn),
                _buildInfoRow('Ngày mượn:', _formatDate(record.borrowDate)),
                if (record.isReturned)
                  _buildInfoRow(
                    'Ngày trả:',
                    _formatDate(record.returnDate!),
                    textColor: Colors.green,
                  )
                else if (record.isOverdue)
                  _buildInfoRow(
                    'Quá hạn:',
                    '${record.daysOverdue} ngày',
                    textColor: Colors.red,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
