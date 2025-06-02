import 'person.dart';
import 'book.dart';

class Student extends Person {
  String studentId;
  String className;
  List<Book> borrowedBooks;
  DateTime registrationDate;

  Student({
    required String id,
    required String name,
    required String email,
    required String phoneNumber,
    required this.studentId,
    required this.className,
    List<Book>? borrowedBooks,
    DateTime? registrationDate,
  })  : borrowedBooks = borrowedBooks ?? [],
        registrationDate = registrationDate ?? DateTime.now(),
        super(id: id, name: name, email: email, phoneNumber: phoneNumber);

  @override
  String getRole() => 'Student';

  bool canBorrowBook() {
    // Students can borrow up to 3 books at a time
    return borrowedBooks.length < 3;
  }

  void borrowBook(Book book) {
    if (canBorrowBook()) {
      borrowedBooks.add(book);
    }
  }

  void returnBook(Book book) {
    borrowedBooks.removeWhere((b) => b.id == book.id);
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = super.toJson();
    data.addAll({
      'studentId': studentId,
      'className': className,
      'borrowedBooks': borrowedBooks.map((book) => book.toJson()).toList(),
      'registrationDate': registrationDate.toIso8601String(),
    });
    return data;
  }
}
