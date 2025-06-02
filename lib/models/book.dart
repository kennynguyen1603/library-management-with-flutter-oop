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
  BookStatus _status;
  String? _currentBorrowerId;

  Book({
    required this.id,
    required this.isbn,
    required String title,
    required String author,
    required String publisher,
    required int publishYear,
    BookStatus status = BookStatus.available,
    String? currentBorrowerId,
  })  : _title = title,
        _author = author,
        _publisher = publisher,
        _publishYear = publishYear,
        _status = status,
        _currentBorrowerId = currentBorrowerId;

  // Getters
  String get title => _title;
  String get author => _author;
  String get publisher => _publisher;
  int get publishYear => _publishYear;

  BookStatus get status => _status;
  String? get currentBorrowerId => _currentBorrowerId;

  // Setters with validation
  set title(String value) {
    if (value.isNotEmpty) {
      // Implementation of set title
    }
  }

  set author(String value) {
    if (value.isNotEmpty) {
      // Implementation of set author
    }
  }

  set publisher(String value) {
    if (value.isNotEmpty) {
      // Implementation of set publisher
    }
  }

  set publishYear(int value) {
    if (value > 0 && value <= DateTime.now().year) {
      // Implementation of set publishYear
    }
  }

  set status(BookStatus value) {
    _status = value;
  }

  set currentBorrowerId(String? value) {
    _currentBorrowerId = value;
  }

  // Methods
  void borrowBook(String studentId) {
    if (_status == BookStatus.available) {
      _status = BookStatus.borrowed;
      _currentBorrowerId = studentId;
    }
  }

  void returnBook() {
    _status = BookStatus.available;
    _currentBorrowerId = null;
  }

  void markForMaintenance() {
    _status = BookStatus.maintenance;
    _currentBorrowerId = null;
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
      'status': _status.toString(),
      'currentBorrowerId': _currentBorrowerId,
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
