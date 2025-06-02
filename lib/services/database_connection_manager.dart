import 'package:flutter/material.dart';
import 'postgres_database.dart';
import 'library_database.dart';

class DatabaseConnectionManager {
  static final DatabaseConnectionManager _instance =
      DatabaseConnectionManager._internal();
  factory DatabaseConnectionManager() => _instance;
  DatabaseConnectionManager._internal();

  bool _isInitialized = false;
  final _postgresDb = PostgresDatabase();
  final _libraryDb = LibraryDatabase();

  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('DatabaseConnectionManager already initialized');
      return;
    }

    try {
      debugPrint('Initializing database connections...');
      await _postgresDb.connect();
      await _libraryDb.initialize();
      _isInitialized = true;
      debugPrint('Database connections initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('Error initializing database connections: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> refreshConnections() async {
    debugPrint('Refreshing database connections...');
    try {
      await _postgresDb.close();
      await _postgresDb.connect();
      await _libraryDb.refreshData();
      debugPrint('Database connections refreshed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error refreshing database connections: $e');
      debugPrint('Stack trace: $stackTrace');
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> closeConnections() async {
    debugPrint('Closing database connections...');
    try {
      await _postgresDb.close();
      _libraryDb.dispose();
      _isInitialized = false;
      debugPrint('Database connections closed successfully');
    } catch (e, stackTrace) {
      debugPrint('Error closing database connections: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  bool get isInitialized => _isInitialized;
}
