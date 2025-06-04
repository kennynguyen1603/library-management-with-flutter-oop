import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_database.dart';
import '../models/borrow_record.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  List<BorrowRecord> _displayedRecords = [];
  bool _isLoading = false;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMoreRecords();
    }
  }

  void _loadMoreRecords() {
    if (!_isLoading && _displayedRecords.length % _pageSize == 0) {
      setState(() {
        _isLoading = true;
      });
    }
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
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

  Widget _buildRecordItem(BorrowRecord record) {
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
          'Mượn bởi: ${record.student.name}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: _buildStatusChip(record),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Sinh viên:', record.student.name),
                _buildInfoRow('Mã SV:', record.student.studentId),
                _buildInfoRow('Lớp:', record.student.className),
                const Divider(),
                _buildInfoRow('Sách:', record.book.title),
                _buildInfoRow('Tác giả:', record.book.author),
                _buildInfoRow('NXB:', record.book.publisher),
                _buildInfoRow('ISBN:', record.book.isbn),
                const Divider(),
                _buildInfoRow('Ngày mượn:', _formatDate(record.borrowDate)),
                if (record.returnDate != null)
                  _buildInfoRow(
                    'Ngày trả:',
                    _formatDate(record.returnDate!),
                    textColor: Colors.green,
                  ),
                if (record.isOverdue)
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

  @override
  Widget build(BuildContext context) {
    final database = context.read<LibraryDatabase>();

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
                hintText: 'Tìm kiếm theo tên sinh viên hoặc tên sách...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _displayedRecords.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _displayedRecords.clear();
                });
              },
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder<bool>(
        valueListenable: database.isLoadingNotifier,
        builder: (context, isLoading, child) {
          if (isLoading && _displayedRecords.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return ValueListenableBuilder<Map<String, BorrowRecord>>(
            valueListenable: database.borrowRecords,
            builder: (context, borrowRecordsMap, child) {
              final allRecords = borrowRecordsMap.values.toList();

              if (allRecords.isEmpty) {
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

              // Filter records based on search query
              final filteredRecords = _searchQuery.isEmpty
                  ? allRecords
                  : allRecords
                      .where((record) =>
                          record.student.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          record.book.title
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList();

              if (filteredRecords.isEmpty) {
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
                        'Không tìm thấy kết quả cho "$_searchQuery"',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // Update displayed records
              if (_displayedRecords.isEmpty) {
                _displayedRecords = filteredRecords.take(_pageSize).toList();
              } else if (_isLoading) {
                final currentLength = _displayedRecords.length;
                final newRecords = filteredRecords
                    .skip(currentLength)
                    .take(_pageSize)
                    .toList();
                if (newRecords.isNotEmpty) {
                  _displayedRecords.addAll(newRecords);
                }
                _isLoading = false;
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: _displayedRecords.length + 1,
                itemBuilder: (context, index) {
                  if (index == _displayedRecords.length) {
                    if (_displayedRecords.length < filteredRecords.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  return _buildRecordItem(_displayedRecords[index]);
                },
              );
            },
          );
        },
      ),
    );
  }
}
