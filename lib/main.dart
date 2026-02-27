import 'package:flutter/material.dart';
import 'package:smart_life1/expense.dart';
import 'home_page.dart';
import 'package:provider/provider.dart';
import 'task_page.dart';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'note_page.dart';
import 'mission_pages.dart';
import 'expense.dart';
/*void main() {
  runApp(SmartLifeApp());
}

class SmartLifeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartLife',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: HomePage(
        token: 'predefined_token', // You can use any string here
        userName: 'Postgres User', // Default user name
        userId:
            'f08ffb63-ebec-4cae-a1c3-027a62fe2f7a', // Your predefined user ID
      ),
    );
  }
}*/

void main() async {
  // Ensure Flutter is initialized before calling async methods
  WidgetsFlutterBinding.ensureInitialized();
  //await _initializeDatabase();
  // Initialize the SQLite database
  await TaskService.initDB();
  // Initialize database through DatabaseHelper
  //await DatabaseHelper.instance.database;
  await DatabaseHelper.instance.database;
  await DatabaseHelperNotes.instance.database;
  final dbHelper = DatabaseHelperExpense();
  await dbHelper.database;
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const SmartLifeApp(),
    ),
  );
}

class SmartLifeApp extends StatelessWidget {
  const SmartLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SmartLife',
          theme: themeNotifier.themeData,
          home: const HomePage(
            token: 'predefined_token',
            userName: 'Ashesh',
            userId: 'f08ffb63-ebec-4cae-a1c3-027a62fe2f7b',
          ),
        );
      },
    );
  }
}

/*class ThemeNotifier extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.ben10;
  

  AppTheme get currentTheme => _currentTheme;

  ThemeData get themeData => ThemeManager.getTheme(_currentTheme);

  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}*/

class ThemeNotifier extends ChangeNotifier {
  AppTheme _currentTheme =
      AppTheme.harryPotter; // Keep your default theme as Ben10

  AppTheme get currentTheme => _currentTheme;

  // Get theme data directly from ThemeManager
  ThemeData get themeData => ThemeManager.getTheme(_currentTheme);

  // Get wallpapers from ThemeManager
  WallpaperAssets get wallpapers => ThemeManager.getWallpapers(_currentTheme);

  // Individual getters for ease of use in different screens
  String get homeWallpaper => wallpapers.homeWallpaper;
  String get notesWallpaper => wallpapers.notesWallpaper;
  String get expenseWallpaper => wallpapers.expenseWallpaper;
  String get missionWallpaper => wallpapers.missionWallpaper;
  String get tasksWallpaper => wallpapers.tasksWallpaper;
  String get addbudgetWallpaper => wallpapers.addbudgetWallpaper;
  String get addexpenseWallpaper => wallpapers.addexpenseWallpaper;

  //addbudgetWallpaper;

  // Your existing setTheme method
  void setTheme(AppTheme theme) {
    _currentTheme = theme;
    notifyListeners();
  }
}

// Placeholder Profile Page (Create a separate profile_page.dart)


