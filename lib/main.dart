import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/library_database.dart';
import 'screens/main_screen.dart';
import 'services/database_connection_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Provider.debugCheckInvalidValueType = null;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeDatabase(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Failed to connect to database'),
                    ElevatedButton(
                      onPressed: () {
                        // Force rebuild of FutureBuilder
                        main();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        final libraryDatabase = snapshot.data as LibraryDatabase;
        return ChangeNotifierProvider<LibraryDatabase>(
          create: (_) => libraryDatabase,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Library Management',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                primary: Colors.blue,
                secondary: Colors.purple,
                tertiary: Colors.orange,
              ),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                elevation: 0,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
              ),
              cardTheme: CardTheme(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            home: const MainScreen(),
          ),
        );
      },
    );
  }
}

Future<LibraryDatabase> _initializeDatabase() async {
  try {
    await DatabaseConnectionManager().initialize();
    final libraryDatabase = LibraryDatabase();
    await libraryDatabase.initialize();
    return libraryDatabase;
  } catch (e) {
    debugPrint('Error initializing database: $e');
    rethrow;
  }
}
