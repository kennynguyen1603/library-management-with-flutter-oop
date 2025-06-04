import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/library_database.dart';
import '../models/borrow_record.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  bool _isLoadingMore = false;
  Timer? _scrollDebounce;
  bool _isNearBottom = false;

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
    _scrollDebounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Kiểm tra xem đã gần cuối chưa
    final isNearBottom = _scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500;

    // Chỉ xử lý khi trạng thái gần cuối thay đổi
    if (isNearBottom != _isNearBottom) {
      _isNearBottom = isNearBottom;

      if (isNearBottom) {
        // Hủy timer cũ nếu có
        _scrollDebounce?.cancel();

        // Đặt timer mới
        _scrollDebounce = Timer(const Duration(milliseconds: 300), () {
          if (mounted) {
            _loadMoreRecords();
          }
        });
      }
    }
  }

  Future<void> _loadMoreRecords() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final database = Provider.of<LibraryDatabase>(context, listen: false);
      await database.loadMoreRecords();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Color _getStatusColor(BorrowRecord record) {
    return record.isReturned
        ? Colors.green
        : record.isOverdue
            ? Colors.red
            : Colors.orange;
  }

  String _getStatusText(BorrowRecord record) {
    return record.isReturned
        ? 'Đã trả'
        : record.isOverdue
            ? 'Quá hạn ${record.daysOverdue} ngày'
            : 'Đang mượn';
  }

  Widget _buildRecordItem(BorrowRecord record) {
    final statusColor = _getStatusColor(record);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.book, color: Colors.blue),
                ),
                const SizedBox(width: 12),

                // Title and student info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.book.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sinh viên: ${record.student.name}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
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
                    _getStatusText(record),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),

            // Student details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã SV: ${record.student.studentId}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lớp: ${record.student.className}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dates
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'Mượn: ${_formatDate(record.borrowDate)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (record.isReturned) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Trả: ${_formatDate(record.returnDate!)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.history : Icons.search_off,
            size: 72,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Chưa có lịch sử mượn sách'
                : 'Không tìm thấy kết quả phù hợp',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '"$_searchQuery"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = context.read<LibraryDatabase>();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Borrow History',
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
                hintText: 'Tìm kiếm theo tên sinh viên hoặc sách...',
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
          if (isLoading && database.borrowRecords.value.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return ValueListenableBuilder<Map<String, BorrowRecord>>(
            valueListenable: database.borrowRecords,
            builder: (context, records, _) {
              final recordsList = records.values.toList();
              final filteredRecords = _searchQuery.isEmpty
                  ? recordsList
                  : recordsList
                      .where((record) =>
                          record.student.name
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()) ||
                          record.book.title
                              .toLowerCase()
                              .contains(_searchQuery.toLowerCase()))
                      .toList();

              if (filteredRecords.isEmpty) {
                return _buildEmptyState();
              }

              return Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () async {
                      // Implement refresh logic here
                      await Future.delayed(const Duration(seconds: 1));
                      if (mounted) {
                        setState(() {});
                      }
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                      itemCount: filteredRecords.length +
                          (_searchQuery.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredRecords.length) {
                          return ValueListenableBuilder<bool>(
                            valueListenable: database.hasMoreRecordsNotifier,
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

                        final record = filteredRecords[index];
                        return _buildRecordItem(record);
                      },
                    ),
                  ),
                  if (isLoading && records.isNotEmpty)
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
    );
  }
}
