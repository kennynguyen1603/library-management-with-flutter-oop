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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': book.id,
      'studentId': student.id,
      'borrowDate': borrowDate.toIso8601String(),
      'returnDate': returnDate?.toIso8601String(),
      'isReturned': isReturned,
    };
  }
}
