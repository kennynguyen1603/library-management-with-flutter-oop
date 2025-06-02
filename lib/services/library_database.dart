import 'dart:async';
import '../models/book.dart';
import '../models/student.dart';
import '../models/borrow_record.dart';
import 'postgres_database.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class LibraryDatabase extends ChangeNotifier {
  // Singleton pattern
  static final LibraryDatabase _instance = LibraryDatabase._internal();
  factory LibraryDatabase() => _instance;

  // In-memory storage with ValueNotifier for immediate UI updates
  final ValueNotifier<Map<String, Book>> _books = ValueNotifier({});
  final ValueNotifier<Map<String, Student>> _students = ValueNotifier({});
  final ValueNotifier<Map<String, BorrowRecord>> _borrowRecords =
      ValueNotifier({});

  // Stream controllers for real-time updates
  final _booksController = StreamController<List<Book>>.broadcast();
  final _studentsController = StreamController<List<Student>>.broadcast();
  final _borrowRecordsController =
      StreamController<List<BorrowRecord>>.broadcast();

  final _postgresDb = PostgresDatabase();
  bool _isInitialized = false;
  bool _isLoading = false;

  // Value notifiers for immediate UI updates
  final ValueNotifier<int> totalBooksNotifier = ValueNotifier(0);
  final ValueNotifier<bool> isLoadingNotifier = ValueNotifier(false);

  // Getters for streams
  Stream<List<Book>> get booksStream => _booksController.stream;
  Stream<List<Student>> get studentsStream => _studentsController.stream;
  Stream<List<BorrowRecord>> get borrowRecordsStream =>
      _borrowRecordsController.stream;

  // Add totalBooksStream
  Stream<int> get totalBooksStream => booksStream.map((books) => books.length);

  // Getters for ValueNotifiers
  ValueNotifier<Map<String, Book>> get books => _books;
  ValueNotifier<Map<String, Student>> get students => _students;
  ValueNotifier<Map<String, BorrowRecord>> get borrowRecords => _borrowRecords;

  // Private constructor
  LibraryDatabase._internal();

  @override
  void dispose() {
    _booksController.close();
    _studentsController.close();
    _borrowRecordsController.close();
    totalBooksNotifier.dispose();
    isLoadingNotifier.dispose();
    super.dispose();
  }

  // Initialize database
  Future<void> initialize() async {
    if (_isInitialized && !_isLoading) {
      debugPrint('Database already initialized, refreshing data...');
      await _initializeData();
      return;
    }

    if (_isLoading) {
      debugPrint('Database initialization already in progress...');
      return;
    }

    _isLoading = true;
    isLoadingNotifier.value = true;

    try {
      debugPrint('Starting database initialization...');
      await _postgresDb.connect();

      // Load initial data in parallel
      await _initializeData();
      _isInitialized = true;

      debugPrint('Database initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing database: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
    } finally {
      _isLoading = false;
      isLoadingNotifier.value = false;
      notifyListeners();
    }
  }

  // Initialize data with parallel loading
  Future<void> _initializeData() async {
    try {
      debugPrint('Starting to load initial data...');

      // Load all data in parallel for faster initialization
      final results = await Future.wait([
        _loadBooks(),
        _loadStudents(),
        _loadBorrowRecords(),
      ]);

      // Update UI immediately after all data is loaded
      _notifyAllUpdates();

      debugPrint('Initial data loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('Error loading initial data: $e');
      debugPrint('Stack trace: $stackTrace');
      // Keep existing data on error
      _notifyAllUpdates();
    }
  }

  void _notifyAllUpdates() {
    // Update streams and notifiers
    _booksController.add(_books.value.values.toList());
    _studentsController.add(_students.value.values.toList());
    _borrowRecordsController.add(_borrowRecords.value.values.toList());
    totalBooksNotifier.value = _books.value.length;
    notifyListeners();
  }

  // Load data from PostgreSQL with immediate updates
  Future<void> _loadBooks() async {
    try {
      final books = await _postgresDb.getAllBooks();

      // Update ValueNotifier immediately
      final newBooks = <String, Book>{};
      for (var book in books) {
        newBooks[book.id] = book;
      }
      _books.value = newBooks;

      // Update total books count
      totalBooksNotifier.value = books.length;

      // Update stream
      _booksController.add(books);
    } catch (e, stackTrace) {
      debugPrint('Error loading books: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadStudents() async {
    try {
      final students = await _postgresDb.getAllStudents();

      // Update ValueNotifier immediately
      final newStudents = <String, Student>{};
      for (var student in students) {
        newStudents[student.id] = student;
      }
      _students.value = newStudents;

      // Update stream
      _studentsController.add(students);
    } catch (e, stackTrace) {
      debugPrint('Error loading students: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  Future<void> _loadBorrowRecords() async {
    try {
      final records = await _postgresDb.getBorrowRecords();

      // Update ValueNotifier immediately
      final newRecords = <String, BorrowRecord>{};
      for (var record in records) {
        newRecords[record.id] = record;
      }
      _borrowRecords.value = newRecords;

      // Update stream
      _borrowRecordsController.add(records);
    } catch (e, stackTrace) {
      debugPrint('Error loading borrow records: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // Book operations
  Future<void> addBook(Book book) async {
    try {
      await _postgresDb.addBook(book);
      await _loadBooks();
    } catch (e) {
      debugPrint('Error adding book: $e');
      rethrow;
    }
  }

  Future<void> updateBook(Book book) async {
    try {
      await _postgresDb.updateBook(book);
      await _loadBooks();
    } catch (e) {
      debugPrint('Error updating book: $e');
      rethrow;
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      await _postgresDb.deleteBook(id);
      await _loadBooks();
    } catch (e) {
      debugPrint('Error deleting book: $e');
      rethrow;
    }
  }

  Book? getBook(String bookId) => _books.value[bookId];

  List<Book> searchBooks(String query) {
    if (query.isEmpty) return _books.value.values.toList();
    return _books.value.values
        .where((book) => book.matchesSearch(query))
        .toList();
  }

  Stream<List<Book>> getAvailableBooks() {
    return booksStream.map((books) =>
        books.where((book) => book.status == BookStatus.available).toList());
  }

  Stream<List<Book>> getBorrowedBooksForStudent(String studentId) {
    return borrowRecordsStream.map((records) {
      final studentRecords = records.where(
          (record) => record.student.id == studentId && !record.isReturned);
      return studentRecords.map((record) => record.book).toList();
    });
  }

  // Student operations
  Future<void> addStudent(Student student) async {
    try {
      await _postgresDb.addStudent(student);
      await _loadStudents();
    } catch (e) {
      debugPrint('Error adding student: $e');
      rethrow;
    }
  }

  Future<void> updateStudent(Student student) async {
    try {
      await _postgresDb.updateStudent(student);
      await _loadStudents();
    } catch (e) {
      debugPrint('Error updating student: $e');
      rethrow;
    }
  }

  Future<void> deleteStudent(String id) async {
    try {
      await _postgresDb.deleteStudent(id);
      await _loadStudents();
    } catch (e) {
      debugPrint('Error deleting student: $e');
      rethrow;
    }
  }

  Student? getStudent(String studentId) => _students.value[studentId];

  // Borrow operations
  Future<void> borrowBook(String studentId, String bookId) async {
    try {
      final student = _students.value[studentId];
      final book = _books.value[bookId];

      if (student == null || book == null) {
        throw Exception('Student hoặc sách không tồn tại');
      }

      if (book.status != BookStatus.available) {
        throw Exception('Sách này hiện không có sẵn để mượn');
      }

      // Kiểm tra số lượng sách đang mượn
      final currentBorrowedBooks = _borrowRecords.value.values
          .where((record) =>
              record.student.id == studentId && record.isReturned == false)
          .length;

      if (currentBorrowedBooks >= 3) {
        throw Exception('Sinh viên đã mượn tối đa 3 cuốn sách');
      }

      // Tạo bản ghi mượn sách mới
      final record = BorrowRecord(
        id: const Uuid().v4(),
        book: book,
        student: student,
        borrowDate: DateTime.now(),
      );

      // Cập nhật trạng thái sách
      book.status = BookStatus.borrowed;
      book.currentBorrowerId = studentId;

      // Cập nhật database
      await _postgresDb.addBorrowRecord(record);
      await _postgresDb.updateBook(book);

      // Cập nhật state
      final newBooks = Map<String, Book>.from(_books.value);
      newBooks[book.id] = book;
      _books.value = newBooks;

      final newRecords = Map<String, BorrowRecord>.from(_borrowRecords.value);
      newRecords[record.id] = record;
      _borrowRecords.value = newRecords;

      notifyListeners();
    } catch (e) {
      debugPrint('Error borrowing book: $e');
      rethrow;
    }
  }

  Future<void> returnBook(String bookId) async {
    try {
      // Tìm sách trong state
      final book = _books.value[bookId];
      if (book == null) {
        throw Exception('Không tìm thấy sách');
      }

      // Tìm bản ghi mượn sách chưa trả
      final record = _borrowRecords.value.values.firstWhere(
        (record) => record.book.id == bookId && !record.isReturned,
        orElse: () => throw Exception('Không tìm thấy bản ghi mượn sách'),
      );

      // Cập nhật trạng thái sách
      book.status = BookStatus.available;
      book.currentBorrowerId = null;

      // Cập nhật bản ghi mượn sách
      record.returnBook();

      // Cập nhật trong database
      await _postgresDb.updateBook(book);
      await _postgresDb.updateBorrowRecord(record);

      // Cập nhật state
      final newBooks = Map<String, Book>.from(_books.value);
      newBooks[book.id] = book;
      _books.value = newBooks;

      final newRecords = Map<String, BorrowRecord>.from(_borrowRecords.value);
      newRecords[record.id] = record;
      _borrowRecords.value = newRecords;

      // Thông báo thay đổi
      notifyListeners();
      debugPrint('Trả sách thành công: ${book.title}');
    } catch (e) {
      debugPrint('Lỗi khi trả sách: $e');
      rethrow;
    }
  }

  List<BorrowRecord> getOverdueRecords() {
    return _borrowRecords.value.values
        .where((record) => record.isOverdue)
        .toList();
  }

  // Method to refresh all data
  Future<void> refreshData() async {
    try {
      debugPrint('Refreshing data...');
      // Load each type of data independently
      await Future.wait([
        _loadBooks(),
        _loadStudents(),
        _loadBorrowRecords(),
      ]);
      debugPrint('Data refreshed successfully');
    } catch (e) {
      debugPrint('Error refreshing data: $e');
      // Keep existing cache on error
      notifyListeners();
    }
  }

  // Check if data is loaded
  bool get hasData => _books.value.isNotEmpty || _students.value.isNotEmpty;
}
