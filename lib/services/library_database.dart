import 'dart:async';
import '../models/book.dart';
import '../models/student.dart';
import '../models/borrow_record.dart';
import 'postgres_database.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class LibraryDatabase {
  // Singleton pattern
  static final LibraryDatabase _instance = LibraryDatabase._internal();
  factory LibraryDatabase() => _instance;

  // In-memory storage
  final Map<String, Book> _books = {};
  final Map<String, Student> _students = {};
  final Map<String, BorrowRecord> _borrowRecords = {};

  // Stream controllers for real-time updates
  late StreamController<List<Book>> _booksController;
  late StreamController<List<Student>> _studentsController;
  late StreamController<List<BorrowRecord>> _borrowRecordsController;
  final _postgresDb = PostgresDatabase();
  bool _isInitialized = false;

  // Getters for streams
  Stream<List<Book>> get booksStream => _booksController.stream;
  Stream<List<Student>> get studentsStream => _studentsController.stream;
  Stream<List<BorrowRecord>> get borrowRecordsStream =>
      _borrowRecordsController.stream;

  // Add totalBooksStream
  Stream<int> get totalBooksStream => booksStream.map((books) => books.length);

  // Private constructor
  LibraryDatabase._internal() {
    _initializeControllers();
  }

  void _initializeControllers() {
    _booksController = StreamController<List<Book>>.broadcast();
    _studentsController = StreamController<List<Student>>.broadcast();
    _borrowRecordsController = StreamController<List<BorrowRecord>>.broadcast();
  }

  // Initialize database
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('Database already initialized');
      return;
    }

    try {
      debugPrint('Starting database initialization...');
      await _postgresDb.connect();
      debugPrint('Database connection established');
      await _initializeData();
      _isInitialized = true;
      debugPrint('Database initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing database: $e');
      debugPrint('Stack trace: $stackTrace');
      // Initialize empty data to prevent infinite loading
      _booksController.add([]);
      _studentsController.add([]);
      _borrowRecordsController.add([]);
      rethrow;
    }
  }

  // Initialize data
  Future<void> _initializeData() async {
    try {
      debugPrint('Starting to load initial data...');
      await Future.wait([
        _loadBooks(),
        _loadStudents(),
        _loadBorrowRecords(),
      ]);
      debugPrint('Initial data loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('Error loading initial data: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Load data from PostgreSQL
  Future<void> _loadBooks() async {
    try {
      debugPrint('Loading books from database...');
      final books = await _postgresDb.getAllBooks();
      debugPrint('Loaded ${books.length} books from database');
      _books.clear(); // Clear existing data before adding new
      for (var book in books) {
        _books[book.id] = book;
      }
      if (!_booksController.isClosed) {
        _booksController.add(books);
        debugPrint('Books loaded and added to stream');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading books: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!_booksController.isClosed) {
        _booksController.add([]);
      }
    }
  }

  Future<void> _loadStudents() async {
    try {
      debugPrint('Loading students from database...');
      final students = await _postgresDb.getAllStudents();
      debugPrint('Loaded ${students.length} students from database');
      _students.clear(); // Clear existing data before adding new
      for (var student in students) {
        _students[student.id] = student;
      }
      if (!_studentsController.isClosed) {
        _studentsController.add(students);
        debugPrint('Students loaded and added to stream');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading students: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!_studentsController.isClosed) {
        _studentsController.add([]);
      }
    }
  }

  Future<void> _loadBorrowRecords() async {
    try {
      debugPrint('Loading borrow records from database...');
      final records = await _postgresDb.getBorrowRecords();
      debugPrint('Loaded ${records.length} borrow records from database');
      _borrowRecords.clear(); // Clear existing data before adding new
      for (var record in records) {
        _borrowRecords[record.id] = record;
      }
      if (!_borrowRecordsController.isClosed) {
        _borrowRecordsController.add(records);
        debugPrint('Borrow records loaded and added to stream');
      }
    } catch (e, stackTrace) {
      debugPrint('Error loading borrow records: $e');
      debugPrint('Stack trace: $stackTrace');
      if (!_borrowRecordsController.isClosed) {
        _borrowRecordsController.add([]);
      }
    }
  }

  // Book operations
  Future<void> addBook(Book book) async {
    await _postgresDb.addBook(book);
    await _loadBooks();
  }

  Future<void> updateBook(Book book) async {
    await _postgresDb.updateBook(book);
    await _loadBooks();
  }

  Future<void> deleteBook(String id) async {
    await _postgresDb.deleteBook(id);
    await _loadBooks();
  }

  Book? getBook(String bookId) => _books[bookId];

  List<Book> searchBooks(String query) {
    if (query.isEmpty) return _books.values.toList();
    return _books.values.where((book) => book.matchesSearch(query)).toList();
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
    await _postgresDb.addStudent(student);
    await _loadStudents();
  }

  Future<void> updateStudent(Student student) async {
    await _postgresDb.updateStudent(student);
    await _loadStudents();
  }

  Future<void> deleteStudent(String id) async {
    await _postgresDb.deleteStudent(id);
    await _loadStudents();
  }

  Student? getStudent(String studentId) => _students[studentId];

  // Borrow operations
  Future<void> borrowBook(String studentId, String bookId) async {
    final student = _students[studentId];
    final book = _books[bookId];

    if (student == null || book == null) {
      throw Exception('Student or book not found');
    }

    if (book.status != BookStatus.available) {
      throw Exception('Book is not available');
    }

    final borrowedBooks = await getBorrowedBooksForStudent(studentId).first;
    if (borrowedBooks.length >= 3) {
      throw Exception('Student has reached maximum number of borrowed books');
    }

    final record = BorrowRecord(
      id: const Uuid().v4(),
      book: book,
      student: student,
      borrowDate: DateTime.now(),
    );

    await _postgresDb.addBorrowRecord(record);
    book.status = BookStatus.borrowed;
    book.currentBorrowerId = studentId;
    await _postgresDb.updateBook(book);

    await _loadBooks();
    await _loadBorrowRecords();
  }

  Future<void> returnBook(String bookId) async {
    final book = _books[bookId];
    if (book == null) {
      throw Exception('Book not found');
    }

    final records = await borrowRecordsStream.first;
    final record = records.firstWhere(
      (r) => r.book.id == bookId && !r.isReturned,
      orElse: () => throw Exception('Borrow record not found'),
    );

    record.returnBook();
    book.status = BookStatus.available;
    book.currentBorrowerId = null;

    await _postgresDb.updateBook(book);
    await _loadBooks();
    await _loadBorrowRecords();
  }

  List<BorrowRecord> getOverdueRecords() {
    return _borrowRecords.values.where((record) => record.isOverdue).toList();
  }

  // Cleanup
  void dispose() {
    _booksController.close();
    _studentsController.close();
    _borrowRecordsController.close();
    _isInitialized = false;
    _initializeControllers(); // Create new controllers for next use
  }

  // Method to refresh all data
  Future<void> refreshData() async {
    if (!_isInitialized) {
      await initialize();
    } else {
      await _initializeData();
    }
  }
}
