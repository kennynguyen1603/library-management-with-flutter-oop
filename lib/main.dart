import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/library_database.dart';
import 'screens/main_screen.dart';
import 'services/database_connection_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseConnectionManager().initialize();
    final libraryDatabase = LibraryDatabase();
    await libraryDatabase.initialize();

    runApp(
      Provider<LibraryDatabase>.value(
        value: libraryDatabase,
        child: const MyApp(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
    // You might want to show an error screen here
    runApp(const ErrorApp());
  }
}

// Add this widget to show when database connection fails
class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to connect to database'),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await DatabaseConnectionManager().refreshConnections();
                    final libraryDatabase = LibraryDatabase();
                    await libraryDatabase.initialize();

                    // Restart app with provider
                    runApp(
                      Provider<LibraryDatabase>.value(
                        value: libraryDatabase,
                        child: const MyApp(),
                      ),
                    );
                  } catch (e) {
                    debugPrint('Error refreshing connection: $e');
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
    );
  }
}
