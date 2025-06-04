# Library Management System with Flutter

A modern library management system built with Flutter, implementing Object-Oriented Programming principles and PostgreSQL for data persistence.

## Features

- Book management (add, edit, delete, search)
- Student management
- Book borrowing and returning
- Overdue tracking
- Modern and responsive UI
- Smart search functionality
- Pagination and lazy loading
- Real-time updates

## System Requirements

Before you begin, ensure you have the following installed:
- [Flutter](https://flutter.dev/docs/get-started/install) (SDK version >=3.0.0)
- [PostgreSQL](https://www.postgresql.org/download/) (version 14 or higher)
- An IDE (VS Code, Android Studio, or IntelliJ IDEA)

## Installation

### 1. PostgreSQL Setup

1. Create a new database:
```sql
CREATE DATABASE library_db;
```

2. Create the necessary tables:
```sql
-- Books table
CREATE TABLE books (
    id VARCHAR(50) PRIMARY KEY,
    isbn VARCHAR(20),
    title VARCHAR(255) NOT NULL,
    author VARCHAR(255) NOT NULL,
    publisher VARCHAR(255),
    publish_year INTEGER,
    status VARCHAR(20),
    current_borrower_id VARCHAR(50)
);

-- Students table
CREATE TABLE students (
    id VARCHAR(50) PRIMARY KEY,
    student_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    class_name VARCHAR(100),
    email VARCHAR(255),
    phone_number VARCHAR(20)
);

-- Borrow Records table
CREATE TABLE borrow_records (
    id VARCHAR(50) PRIMARY KEY,
    book_id VARCHAR(50) REFERENCES books(id),
    student_id VARCHAR(50) REFERENCES students(id),
    borrow_date TIMESTAMP NOT NULL,
    return_date TIMESTAMP,
    is_returned BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);
```

### 2. Database Configuration

Update the database connection information in `lib/services/postgres_database.dart`:
```dart
Endpoint(
  host: 'localhost',
  port: 5432,
  database: 'library_db',
  username: 'your_username',
  password: 'your_password',
)
```

### 3. Install Dependencies

Run the following command to install required packages:
```bash
flutter pub get
```

### 4. Run the Application

```bash
flutter run
```

## Project Structure

```
lib/
├── models/         # Data models (Book, Student, BorrowRecord)
├── screens/        # UI screens (BookList, History, etc.)
├── services/       # Business logic and Database services
├── widgets/        # Reusable widgets
└── main.dart       # Application entry point
```

### Models
- `Book`: Manages book information and status
- `Student`: Handles student data and borrowing privileges
- `BorrowRecord`: Tracks borrowing and returning transactions

### Services
- `LibraryDatabase`: Manages state and business logic
- `PostgresDatabase`: Handles database connections and queries

### Screens
- `BookListScreen`: Displays and manages books with real-time updates
- `HistoryScreen`: Shows borrowing history with efficient pagination

## Performance Optimizations

- Uses ValueNotifier for instant UI updates
- Implements pagination and lazy loading for long lists
- Optimizes data loading and display
- Implements data caching to reduce database queries
- Efficient state management for real-time updates

Key optimizations include:
- Lazy loading of history records
- Instant UI updates using ValueNotifier
- Efficient data caching
- Optimized database queries
- Smart search with debouncing

## Performance Features

1. **Real-time Updates**
   - Instant reflection of data changes
   - Efficient state management
   - Optimized UI rebuilds

2. **Lazy Loading**
   - Paginated data loading
   - Smooth scrolling experience
   - Reduced memory usage

3. **Search Optimization**
   - Fast search results
   - Efficient filtering
   - Minimal database queries

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/NewFeature`)
3. Commit your changes (`git commit -m 'Add new feature'`)
4. Push to the branch (`git push origin feature/NewFeature`)
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email your.email@example.com or create an issue in the repository.
