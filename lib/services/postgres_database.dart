import 'package:postgres/postgres.dart';
import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/student.dart';
import '../models/borrow_record.dart';

class PostgresDatabase {
  static final PostgresDatabase _instance = PostgresDatabase._internal();
  factory PostgresDatabase() => _instance;
  PostgresDatabase._internal();

  Connection? _connection;
  bool _isConnected = false;
  bool _isConnecting = false;

  Future<void> connect() async {
    if (_isConnected && _connection != null) {
      debugPrint('Already connected to PostgreSQL database');
      return;
    }

    if (_isConnecting) {
      debugPrint('Connection attempt already in progress');
      return;
    }

    _isConnecting = true;
    debugPrint('Attempting to connect to PostgreSQL database...');

    try {
      _connection = await Connection.open(
        Endpoint(
          host: 'localhost',
          port: 5432,
          database: 'library_db',
          username: 'postgres',
          password: '590199nyphuyen',
        ),
        settings: const ConnectionSettings(
          sslMode: SslMode.disable,
          connectTimeout: Duration(seconds: 30),
          queryTimeout: Duration(seconds: 30),
        ),
      );

      _isConnected = true;
      debugPrint('Successfully connected to PostgreSQL database');
      await _createTables();
    } catch (e, stackTrace) {
      _isConnected = false;
      _connection = null;
      debugPrint('Error connecting to database: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> ensureConnection() async {
    if (!_isConnected || _connection == null) {
      debugPrint('No active connection, attempting to reconnect...');
      await connect();
    }
  }

  Future<T> _withConnection<T>(
      Future<T> Function(Connection conn) operation) async {
    try {
      await ensureConnection();
      if (_connection == null) {
        throw Exception('Failed to establish database connection');
      }
      return await operation(_connection!);
    } catch (e, stackTrace) {
      debugPrint('Database operation failed: $e');
      debugPrint('Stack trace: $stackTrace');
      _isConnected = false;
      _connection = null;
      rethrow;
    }
  }

  Future<void> _createTables() async {
    debugPrint('Creating/verifying database tables...');
    try {
      await _withConnection((conn) async {
        // Create Books table
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS books (
            id VARCHAR(50) PRIMARY KEY,
            isbn VARCHAR(20),
            title VARCHAR(255) NOT NULL,
            author VARCHAR(255) NOT NULL,
            publisher VARCHAR(255),
            publish_year INTEGER,
            status VARCHAR(20),
            current_borrower_id VARCHAR(50)
          )
        ''');

        // Create Students table
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS students (
            id VARCHAR(50) PRIMARY KEY,
            student_id VARCHAR(50) UNIQUE NOT NULL,
            name VARCHAR(255) NOT NULL,
            class_name VARCHAR(100),
            email VARCHAR(255),
            phone_number VARCHAR(20)
          )
        ''');

        // Create BorrowRecords table
        await conn.execute('''
          CREATE TABLE IF NOT EXISTS borrow_records (
            id VARCHAR(50) PRIMARY KEY,
            book_id VARCHAR(50) REFERENCES books(id),
            student_id VARCHAR(50) REFERENCES students(id),
            borrow_date TIMESTAMP NOT NULL,
            return_date TIMESTAMP,
            is_returned BOOLEAN DEFAULT FALSE,
            FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
            FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
          )
        ''');
      });
      debugPrint('Database tables created/verified successfully');
    } catch (e, stackTrace) {
      debugPrint('Error creating tables: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Book operations
  Future<void> addBook(Book book) async {
    await _withConnection((conn) async {
      const query = '''
        INSERT INTO books 
          (id, isbn, title, author, publisher, publish_year, status) 
        VALUES 
          (\$1, \$2, \$3, \$4, \$5, \$6, \$7)
      ''';

      await conn.execute(
        query,
        parameters: [
          book.id,
          book.isbn,
          book.title,
          book.author,
          book.publisher,
          book.publishYear,
          book.status.toString(),
        ],
      );
    });
  }

  Future<List<Book>> getAllBooks() async {
    return await _withConnection((conn) async {
      debugPrint('Fetching all books from database...');
      final results = await conn.execute('SELECT * FROM books');
      debugPrint('Successfully fetched ${results.length} books');
      return results.map((row) {
        final List<dynamic> values = row.toList();
        return _rowToBook(values);
      }).toList();
    });
  }

  Future<void> updateBook(Book book) async {
    await _withConnection((conn) async {
      const query = '''
        UPDATE books 
        SET 
          isbn = \$2, 
          title = \$3, 
          author = \$4, 
          publisher = \$5, 
          publish_year = \$6, 
          status = \$7, 
          current_borrower_id = \$8 
        WHERE id = \$1
      ''';

      await conn.execute(
        query,
        parameters: [
          book.id,
          book.isbn,
          book.title,
          book.author,
          book.publisher,
          book.publishYear,
          book.status.toString(),
          book.currentBorrowerId,
        ],
      );
    });
  }

  Future<void> deleteBook(String id) async {
    await _withConnection((conn) async {
      await conn.execute(
        'DELETE FROM books WHERE id = \$1',
        parameters: [id],
      );
    });
  }

  // Student operations
  Future<void> addStudent(Student student) async {
    await _withConnection((conn) async {
      const query = '''
        INSERT INTO students 
          (id, student_id, name, class_name, email, phone_number) 
        VALUES 
          (\$1, \$2, \$3, \$4, \$5, \$6)
      ''';

      await conn.execute(
        query,
        parameters: [
          student.id,
          student.studentId,
          student.name,
          student.className,
          student.email,
          student.phoneNumber,
        ],
      );
    });
  }

  Future<List<Student>> getAllStudents() async {
    return await _withConnection((conn) async {
      debugPrint('Fetching all students from database...');
      final results = await conn.execute('SELECT * FROM students');
      debugPrint('Successfully fetched ${results.length} students');
      return results.map((row) {
        final List<dynamic> values = row.toList();
        return _rowToStudent(values);
      }).toList();
    });
  }

  Future<void> updateStudent(Student student) async {
    await _withConnection((conn) async {
      const query = '''
        UPDATE students 
        SET 
          student_id = \$2, 
          name = \$3, 
          class_name = \$4, 
          email = \$5, 
          phone_number = \$6 
        WHERE id = \$1
      ''';

      await conn.execute(
        query,
        parameters: [
          student.id,
          student.studentId,
          student.name,
          student.className,
          student.email,
          student.phoneNumber,
        ],
      );
    });
  }

  Future<void> deleteStudent(String id) async {
    await _withConnection((conn) async {
      await conn.execute(
        'DELETE FROM students WHERE id = \$1',
        parameters: [id],
      );
    });
  }

  // Borrow operations
  Future<void> addBorrowRecord(BorrowRecord record) async {
    await _withConnection((conn) async {
      const query = '''
        INSERT INTO borrow_records 
          (id, book_id, student_id, borrow_date, return_date, is_returned) 
        VALUES 
          (\$1, \$2, \$3, \$4, \$5, \$6)
      ''';

      await conn.execute(
        query,
        parameters: [
          record.id,
          record.book.id,
          record.student.id,
          record.borrowDate,
          record.returnDate,
          record.isReturned,
        ],
      );
    });
  }

  Future<List<BorrowRecord>> getBorrowRecords() async {
    return await _withConnection((conn) async {
      debugPrint('Fetching all borrow records from database...');
      final results = await conn.execute('''
        SELECT 
          br.id,
          br.book_id,
          br.student_id,
          br.borrow_date,
          br.return_date,
          br.is_returned,
          b.title,
          b.author,
          b.publisher,
          b.isbn,
          b.publish_year,
          b.status,
          b.current_borrower_id,
          s.name,
          s.student_id as student_number,
          s.class_name,
          s.email,
          s.phone_number
        FROM borrow_records br
        JOIN books b ON br.book_id = b.id
        JOIN students s ON br.student_id = s.id
        ORDER BY br.borrow_date DESC
      ''');
      debugPrint('Successfully fetched ${results.length} borrow records');

      return results.map((row) {
        final List<dynamic> values = row.toList();
        return _rowToBorrowRecord(values);
      }).toList();
    });
  }

  Future<void> updateBorrowRecord(BorrowRecord record) async {
    try {
      await _withConnection((conn) async {
        const query = '''
          UPDATE borrow_records 
          SET 
            return_date = \$2, 
            is_returned = \$3 
          WHERE id = \$1
        ''';

        await conn.execute(
          query,
          parameters: [
            record.id,
            record.returnDate,
            record.isReturned,
          ],
        );
      });
      debugPrint('Cập nhật bản ghi mượn sách thành công: ${record.id}');
    } catch (e) {
      debugPrint('Lỗi khi cập nhật bản ghi mượn sách: $e');
      rethrow;
    }
  }

  // Helper methods to convert database rows to objects
  Book _rowToBook(List<dynamic> row) {
    return Book(
      id: row[0] as String,
      isbn: row[1] as String? ?? '',
      title: row[2] as String,
      author: row[3] as String,
      publisher: row[4] as String? ?? '',
      publishYear: row[5] as int? ?? DateTime.now().year,
      status: BookStatus.values.firstWhere(
        (e) =>
            e.toString() ==
            (row[6] as String? ?? BookStatus.available.toString()),
        orElse: () => BookStatus.available,
      ),
      currentBorrowerId: row[7] as String?,
    );
  }

  Student _rowToStudent(List<dynamic> row) {
    return Student(
      id: row[0] as String,
      studentId: row[1] as String,
      name: row[2] as String,
      className: row[3] as String? ?? '',
      email: row[4] as String? ?? '',
      phoneNumber: row[5] as String? ?? '',
    );
  }

  BorrowRecord _rowToBorrowRecord(List<dynamic> row) {
    // Parse book data
    final book = Book(
      id: row[1] as String, // book_id
      title: row[6] as String, // title
      author: row[7] as String, // author
      publisher: row[8] as String? ?? '', // publisher
      isbn: row[9] as String? ?? '', // isbn
      publishYear: row[10] as int? ?? DateTime.now().year, // publish_year
      status: BookStatus.values.firstWhere(
        (e) =>
            e.toString() ==
            (row[11] as String? ?? BookStatus.available.toString()),
        orElse: () => BookStatus.available,
      ),
      currentBorrowerId: row[12] as String?, // current_borrower_id
    );

    // Parse student data
    final student = Student(
      id: row[2] as String, // student_id from borrow_records
      name: row[13] as String, // name
      studentId: row[14] as String, // student_number
      className: row[15] as String? ?? '', // class_name
      email: row[16] as String? ?? '', // email
      phoneNumber: row[17] as String? ?? '', // phone_number
    );

    // Create borrow record
    return BorrowRecord(
      id: row[0] as String, // id
      book: book,
      student: student,
      borrowDate: row[3] as DateTime, // borrow_date
      returnDate: row[4] as DateTime?, // return_date
      isReturned: row[5] as bool, // is_returned
    );
  }

  Future<void> close() async {
    if (_isConnected && _connection != null) {
      await _connection!.close();
      _connection = null;
      _isConnected = false;
      debugPrint('Database connection closed');
    }
  }
}
