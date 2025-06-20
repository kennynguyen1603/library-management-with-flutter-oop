import 'searchable.dart';

enum BookStatus {
  available,
  borrowed,
  maintenance,
}

class Book implements Searchable {
  final String id;
  final String isbn;
  final String _title;
  final String _author;
  final String _publisher;
  final int _publishYear;
  BookStatus status;
  String? currentBorrowerId;

  Book({
    required this.id,
    required this.isbn,
    required String title,
    required String author,
    required String publisher,
    required int publishYear,
    this.status = BookStatus.available,
    this.currentBorrowerId,
  })  : _title = title,
        _author = author,
        _publisher = publisher,
        _publishYear = publishYear;

  // Getters
  String get title => _title;
  String get author => _author;
  String get publisher => _publisher;
  int get publishYear => _publishYear;

  // Methods
  void borrowBook(String studentId) {
    if (status == BookStatus.available) {
      status = BookStatus.borrowed;
      currentBorrowerId = studentId;
    }
  }

  void returnBook() {
    status = BookStatus.available;
    currentBorrowerId = null;
  }

  void markForMaintenance() {
    status = BookStatus.maintenance;
    currentBorrowerId = null;
  }

  // Implementation of Searchable interface
  @override
  bool matchesSearch(String query) {
    final searchQuery = query.toLowerCase();
    return title.toLowerCase().contains(searchQuery) ||
        author.toLowerCase().contains(searchQuery) ||
        isbn.toLowerCase().contains(searchQuery);
  }

  @override
  List<String> getSearchableFields() {
    return ['title', 'author', 'publisher', 'isbn'];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isbn': isbn,
      'title': _title,
      'author': _author,
      'publisher': _publisher,
      'publishYear': _publishYear,
      'status': status.toString(),
      'currentBorrowerId': currentBorrowerId,
    };
  }

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      publisher: json['publisher'] as String,
      publishYear: json['publishYear'] as int,
      status: BookStatus.values.firstWhere(
        (e) => e.toString() == json['status'] as String,
        orElse: () => BookStatus.available,
      ),
      currentBorrowerId: json['currentBorrowerId'] as String?,
    );
  }
}
