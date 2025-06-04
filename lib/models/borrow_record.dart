import 'book.dart';
import 'student.dart';

class BorrowRecord {
  final String id;
  final Book book;
  final Student student;
  final DateTime borrowDate;
  DateTime? returnDate;
  bool isReturned;

  BorrowRecord({
    required this.id,
    required this.book,
    required this.student,
    required this.borrowDate,
    this.returnDate,
    this.isReturned = false,
  });

  factory BorrowRecord.fromDatabaseRow({
    required Map<String, dynamic> recordRow,
    required Book book,
    required Student student,
  }) {
    return BorrowRecord(
      id: recordRow['id'],
      book: book,
      student: student,
      borrowDate: DateTime.parse(recordRow['borrow_date']),
      returnDate: recordRow['return_date'] != null
          ? DateTime.parse(recordRow['return_date'])
          : null,
      isReturned: recordRow['is_returned'] ?? false,
    );
  }

  void returnBook() {
    if (!isReturned) {
      isReturned = true;
      returnDate = DateTime.now();
      book.returnBook();
    }
  }

  int get daysOverdue {
    if (isReturned) return 0;

    final dueDate = borrowDate.add(
      const Duration(days: 14),
    ); // 2 weeks borrowing period
    final today = DateTime.now();

    if (today.isAfter(dueDate)) {
      return today.difference(dueDate).inDays;
    }
    return 0;
  }

  bool get isOverdue => daysOverdue > 0;

  Map<String, dynamic> toDatabaseRow() {
    return {
      'id': id,
      'book_id': book.id,
      'student_id': student.id,
      'borrow_date': borrowDate.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'is_returned': isReturned,
    };
  }
}
