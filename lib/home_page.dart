import 'package:flutter/material.dart';
import 'dart:math';
import 'task_page.dart';
import 'mission_pages.dart';
import 'note_page.dart';
import 'expense.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'weather.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // This imports StreamController

class HomePage extends StatefulWidget {
  // Changed to StatefulWidget
  final String token;
  final String userName;
  final String userId;

  const HomePage({
    super.key,
    required this.token,
    required this.userName,
    required this.userId,
  });

  static Route<dynamic> route() {
    return MaterialPageRoute(
      builder: (context) {
        final args =
            ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return HomePage(
            token: args['token'] ?? '',
            userName: args['userName'] ?? '',
            userId: args['userId'] ?? '');
      },
    );
  }

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _upcomingTask;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingTask();
  }

  // Get current time and return greeting message
  String getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning, ${widget.userName}!";
    } else if (hour < 18) {
      return "Good Afternoon, ${widget.userName}!";
    } else {
      return "Good Evening, ${widget.userName}!";
    }
  }

  // List of motivational quotes
  final List<String> quotes = [
    "Believe in yourself and all that you are.",
    "Every day is a new opportunity to grow.",
    "You are stronger than you think.",
    "Success is the sum of small efforts, repeated daily.",
  ];

  // Function to get a random quote
  String getRandomQuote() {
    final random = Random();
    return quotes[random.nextInt(quotes.length)];
  }

  // Widget for Quick Actions
  Widget quickActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        color: color,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadUpcomingTask() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final task = await TaskService.getUpcomingTask(widget.userId);

      setState(() {
        _upcomingTask = task;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading upcoming task: $e');
      setState(() {
        _upcomingTask = null;
        _isLoading = false;
      });
    }
  }

  void _dismissNotification() {
    setState(() {
      _upcomingTask = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the theme's text styles
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.homeWallpaper;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("SmartLife"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/profile');
            },
          ),
          PopupMenuButton<AppTheme>(
            icon: const Icon(Icons.color_lens),
            onSelected: (AppTheme selectedTheme) {
              Provider.of<ThemeNotifier>(context, listen: false)
                  .setTheme(selectedTheme);
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<AppTheme>>[
              const PopupMenuItem(
                value: AppTheme.ben10,
                child: Text('Ben 10'),
              ),
              const PopupMenuItem(
                value: AppTheme.deadpool,
                child: Text('Deadpool'),
              ),
              const PopupMenuItem(
                value: AppTheme.ironman,
                child: Text('Iron Man'),
              ),
              const PopupMenuItem(
                value: AppTheme.batman,
                child: Text('Batman'),
              ),
              const PopupMenuItem(
                value: AppTheme.harryPotter,
                child: Text('Harry Potter'),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background container with gradient

          Image.asset(
            wallpaperAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: kToolbarHeight + 20),

                  // Greeting Section - Fixed to respect theme font
                  Text(
                    getGreeting(),
                    style: headlineStyle.copyWith(
                      fontSize: 26,
                      color: Colors.white,
                      // Now the fontFamily from the theme will be preserved
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Motivational Quote - Fixed to respect theme font
                  Text(
                    getRandomQuote(),
                    style: bodyStyle.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                      // Now the fontFamily from the theme will be preserved
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Upcoming Task Notification
                  /*if (_isLoading)
                    const SizedBox(
                      height: 80.0,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () {
                        // Navigate to task details page if there's an upcoming task
                        if (_upcomingTask != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TaskPage(
                                userId: widget.userId,
                                //initialTaskId: _upcomingTask!['id'],
                              ),
                            ),
                          );
                        }
                      },*/
                  /*child: UpcomingTaskNotification(
                        upcomingTask: _upcomingTask,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        textColor: Colors.white,
                      ),*/
                  if (!_isLoading && _upcomingTask != null)
                    TaskNotificationBar(
                      upcomingTask: _upcomingTask,
                      onDismiss: _dismissNotification,
                      // Optional: Add a custom image
                      leadingImage: Image.asset(
                        'assets/tanjiro/notif.jpg',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 20),

                  WeatherWidget(token: widget.token),

                  const SizedBox(height: 30),

// First row - single button (full width)
                  SizedBox(
                    width: double.infinity,
                    height: 60, // Using a 10:6 ratio (where width is dynamic)
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskPage(userId: widget.userId),
                          ),
                        );
                      },
                      child: const Text("Go to Tasks & Reminders"),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60, // Height maintaining the 10:6 ratio
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MissionScreen(
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                            child: const Text("Start a Mission"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), // Space between buttons
                      Expanded(
                        child: SizedBox(
                          height: 60, // Height maintaining the 10:6 ratio
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      PastMissionsScreen(userId: widget.userId),
                                ),
                              );
                            },
                            child: const Text("View Past Missions"),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 60, // Height maintaining the 10:6 ratio
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        NotesPage(userId: widget.userId)),
                              );
                            },
                            child: const Text("Go to Notes"),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12), // Space between buttons
                      Expanded(
                        child: SizedBox(
                          height: 60, // Height maintaining the 10:6 ratio
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      DashboardScreen(userId: widget.userId),
                                ),
                              );
                            },
                            child: const Text("Go to Expense Tracker"),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WallpaperAssets {
  final String homeWallpaper;
  final String notesWallpaper;
  final String expenseWallpaper;
  final String missionWallpaper;
  final String tasksWallpaper;
  final String addnoteWallpaper;
  final String addexpenseWallpaper;
  final String addbudgetWallpaper;

  const WallpaperAssets({
    required this.homeWallpaper,
    required this.notesWallpaper,
    required this.expenseWallpaper,
    required this.missionWallpaper,
    required this.tasksWallpaper,
    required this.addnoteWallpaper,
    required this.addexpenseWallpaper,
    required this.addbudgetWallpaper,
  });
}

enum AppTheme { ben10, deadpool, ironman, batman, harryPotter, defaultTheme }

class ThemeManager {
  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.ben10:
        return _ben10Theme();
      case AppTheme.deadpool:
        return _deadpoolTheme();
      case AppTheme.ironman:
        return _ironmanTheme();
      case AppTheme.batman:
        return _batmanTheme();
      case AppTheme.harryPotter:
        return _harryPotterTheme();
      default:
        return ThemeData.light();
    }
  }

  static WallpaperAssets getWallpapers(AppTheme theme) {
    switch (theme) {
      case AppTheme.ben10:
        return _ben10Wallpapers();
      case AppTheme.deadpool:
        return _deadpoolWallpapers();
      case AppTheme.ironman:
        return _ironmanWallpapers();
      case AppTheme.batman:
        return _batmanWallpapers();
      case AppTheme.harryPotter:
        return _harryPotterWallpapers();
      default:
        return _defaultWallpapers();
    }
  }

  // Ben 10 wallpapers
  static WallpaperAssets _ben10Wallpapers() {
    return const WallpaperAssets(
      homeWallpaper: 'assets/ben10/home_wallpaper.jpg',
      notesWallpaper: 'assets/ben10/notes_wallpaper.jpg',
      expenseWallpaper: 'assets/ben10/expense_wallpaper.jpg',
      missionWallpaper: 'assets/ben10/mission_wallpaper.jpg',
      tasksWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addnoteWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addexpenseWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addbudgetWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
    );
  }

  // Deadpool wallpapers
  static WallpaperAssets _deadpoolWallpapers() {
    return const WallpaperAssets(
      homeWallpaper: 'assets/deadpool/home_wallpaper.jpg',
      notesWallpaper: 'assets/deadpool/notes_wallpaper.jpg',
      expenseWallpaper: 'assets/deadpool/expense_wallpaper.jpg',
      missionWallpaper: 'assets/deadpool/mission_wallpaper.jpg',
      tasksWallpaper: 'assets/deadpool/tasks_wallpaper.jpg',
      addnoteWallpaper: 'assets/deadpool/tasks_wallpaper.jpg',
      addexpenseWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addbudgetWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
    );
  }

  // Iron Man wallpapers
  static WallpaperAssets _ironmanWallpapers() {
    return const WallpaperAssets(
      homeWallpaper: 'assets/ironman/home_wallpaper.jpg',
      notesWallpaper: 'assets/ironman/notes_wallpaper.jpg',
      expenseWallpaper: 'assets/ironman/expense_wallpaper.jpg',
      missionWallpaper: 'assets/ironman/mission_wallpaper.jpg',
      tasksWallpaper: 'assets/ironman/tasks_wallpaper.jpg',
      addnoteWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addexpenseWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addbudgetWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
    );
  }

  // Batman wallpapers
  static WallpaperAssets _batmanWallpapers() {
    return const WallpaperAssets(
      homeWallpaper: 'assets/batman/home_wallpaper.jpg',
      notesWallpaper: 'assets/batman/notes_wallpaper.jpg',
      expenseWallpaper: 'assets/batman/expense_wallpaper.jpg',
      missionWallpaper: 'assets/batman/mission_wallpaper.jpg',
      tasksWallpaper: 'assets/batman/tasks_wallpaper.jpg',
      addnoteWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addexpenseWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addbudgetWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
    );
  }

  // Tanjiro wallpapers
  static WallpaperAssets _harryPotterWallpapers() {
    return const WallpaperAssets(
      homeWallpaper: 'assets/tanjiro/harrpotter_homepage.jpg',
      notesWallpaper: 'assets/tanjiro/harrypotter_new.jpg',
      expenseWallpaper: 'assets/tanjiro/harrypotter_budgetdash2.jpg',
      missionWallpaper: 'assets/tanjiro/harrypotter_addexpense.jpg',
      tasksWallpaper: 'assets/tanjiro/harrypotter_tasklist.jpg',
      addnoteWallpaper: 'assets/tanjiro/harrypotter_noteadd.jpg',
      addexpenseWallpaper: 'assets/tanjiro/harrypotter_addexpense2.jpg',
      addbudgetWallpaper: 'assets/tanjiro/harrypotter_addbudget.jpg',
    );
  }

  // Default wallpapers
  static WallpaperAssets _defaultWallpapers() {
    return const WallpaperAssets(
      homeWallpaper: 'assets/default/home_wallpaper.jpg',
      notesWallpaper: 'assets/default/notes_wallpaper.jpg',
      expenseWallpaper: 'assets/default/expense_wallpaper.jpg',
      missionWallpaper: 'assets/default/mission_wallpaper.jpg',
      tasksWallpaper: 'assets/default/tasks_wallpaper.jpg',
      addnoteWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addexpenseWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
      addbudgetWallpaper: 'assets/ben10/tasks_wallpaper.jpg',
    );
  }

  static ThemeData _ben10Theme() {
    return ThemeData(
      primaryColor: const Color(0xFF00FF00), // Neon green
      primaryColorDark: const Color(0xFF006600),
      primaryColorLight: const Color(0xFF66FF66),
      scaffoldBackgroundColor: Colors.black12,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF00FF00),
        secondary: Color(0xFFAAAAAA), // Silver
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Orbitron',
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Orbitron', // Changed to match theme
          color: Colors.black,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Orbitron',
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(color: Color(0xFF00FF00), width: 2),
        ),
        elevation: 5,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF00), // neon green
          foregroundColor: Colors.black, // text color
          textStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFF00FF00), width: 2),
          ),
          minimumSize: const Size(200, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      /*elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF00),
          foregroundColor: Colors.black,
          textStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),*/
      // Add this to ensure AppBar text uses the theme font
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /*static ThemeData _deadpoolTheme() {
    return ThemeData(
      primaryColor: const Color(0xFFFF0000), // Red
      primaryColorDark: const Color(0xFFCC0000),
      primaryColorLight: const Color(0xFFFF6666),
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF0000),
        secondary: Color(0xFF000000), // Black
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Bangers', // Comic-like font
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Bangers',
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Bangers',
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFF0000), width: 2),
        ),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB71C1C), // dark blood red
          foregroundColor: Colors.white, // text color
          textStyle: const TextStyle(
            fontFamily: 'Bangers',
            fontWeight: FontWeight.bold,
          ),
          shape: const StadiumBorder(
            side: BorderSide(color: Colors.black, width: 2),
          ),
          minimumSize: const Size(200, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }*/

  static ThemeData _deadpoolTheme() {
    // Basic Deadpool theme
    final baseTheme = ThemeData(
      primaryColor: const Color(0xFFFF0000), // Red
      primaryColorDark: const Color(0xFFCC0000),
      primaryColorLight: const Color(0xFFFF6666),
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF0000),
        secondary: Color(0xFF000000), // Black
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Bangers', // Comic-like font
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Bangers',
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Bangers',
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFFF0000), width: 2),
        ),
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB71C1C), // dark blood red
          foregroundColor: Colors.white, // text color
          textStyle: const TextStyle(
            fontFamily: 'Bangers',
            fontWeight: FontWeight.bold,
          ),
          shape: const StadiumBorder(
            side: BorderSide(color: Colors.black, width: 2),
          ),
          minimumSize: const Size(200, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFFB71C1C),
        titleTextStyle: TextStyle(
          fontFamily: 'Bangers',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFFFF0000),
        inactiveTrackColor: Colors.grey[800],
        thumbColor: Colors.white,
        overlayColor: const Color(0xFFFF0000).withOpacity(0.3),
        valueIndicatorColor: const Color(0xFFB71C1C),
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Bangers',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(
          fontFamily: 'Bangers',
          color: Colors.white,
          fontSize: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFF0000), width: 2),
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFFF0000), width: 3),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    // Add Deadpool-specific timer extension
    return baseTheme.copyWith(
      extensions: [
        TimerThemeExtension(
            // Timer progress color
            progressColor: const Color(0xFFFF0000),
            // Timer background color
            backgroundColor: Colors.black,
            // Timer text color
            timerTextColor: Colors.white,
            // Timer text style
            timerTextStyle: const TextStyle(
              fontFamily: 'Bangers',
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            // Timer decoration (Deadpool mask effect)
            timerDecoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF0000),
                width: 4,
              ),
            ),
            // Sound to play when timer starts
            soundAsset: 'assets/sounds/hedwigs_theme.mp3',
            // Background image for the mission screen
            backgroundAsset: 'assets/deadpool/mission_wallpaper.jpg',
            timerBackgroundAsset: 'assets/deadpool/deadpool_timer_bg.png',
            // Deadpool eyes overlay
            overlayWidget: null),
      ],
    );
  }

  static ThemeData _ironmanTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFB40000), // Ironman red
      scaffoldBackgroundColor: const Color(0xFF0D0D0D), // Dark techy bg
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFB40000),
        secondary: Color(0xFFE5C100), // Gold
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'Orbitron',
          color: Color(0xFF00D9FF), // Arc reactor blue
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Orbitron',
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Orbitron',
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF00D9FF), width: 1.5),
        ),
        elevation: 6,
        color: Colors.grey.shade900,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFD700), // gold
          foregroundColor: const Color(0xFFB40000), // maroon
          textStyle: const TextStyle(
            fontFamily: 'Orbitron',
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.bold,
          ),
          shape: BeveledRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Colors.red, width: 2),
          ),
          minimumSize: const Size(200, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontFamily: 'Orbitron',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  static ThemeData _batmanTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.black,
      scaffoldBackgroundColor: const Color(0xFF1A1A1A),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFFD700), // Yellow highlight
        secondary: Color(0xFF444444),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'RobotoCondensed',
          color: Colors.yellow.shade700,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: const TextStyle(
          fontFamily: 'RobotoCondensed',
          color: Colors.white70,
        ),
        labelLarge: const TextStyle(
          fontFamily: 'RobotoCondensed',
          color: Colors.black,
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.yellow.shade700, width: 1.5),
        ),
        elevation: 4,
        color: const Color(0xFF292929),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF212121), // deep grey
          foregroundColor: const Color(0xFFFFD600), // yellow-gold
          textStyle: const TextStyle(
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // rectangle
            side: const BorderSide(color: Colors.grey, width: 2),
          ),
          minimumSize: const Size(200, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        titleTextStyle: TextStyle(
          fontFamily: 'RobotoCondensed',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  static ThemeData _harryPotterTheme() {
    // Basic Harry Potter theme
    final baseTheme = ThemeData(
      primaryColor: const Color(0xFF740001), // Gryffindor Burgundy
      primaryColorDark: const Color(0xFF4C0001),
      primaryColorLight: const Color(0xFF9A7B4F), // Gold accent
      scaffoldBackgroundColor: const Color(0xFF1A1A1A), // Dark parchment-like
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF740001), // Gryffindor Burgundy
        secondary: Color(0xFF9A7B4F), // Gold accent
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontFamily: 'ParryHotter', // Harry Potter-inspired font
          color: Color(0xFFE2D3A7), // Aged parchment color
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Lumos', // Another HP-style font for body text
          color: Color(0xFFE2D3A7),
        ),
        labelLarge: TextStyle(
          fontFamily: 'Lumos',
          color: Color(0xFFE2D3A7),
        ),
      ),
      cardTheme: CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Color(0xFF9A7B4F), width: 1.5),
        ),
        elevation: 6,
        color: const Color(0xFF2A2A2A), // Darker parchment-like
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF740001), // Gryffindor burgundy
          foregroundColor: const Color(0xFFE2D3A7), // Aged parchment text color
          textStyle: const TextStyle(
            fontFamily: 'Lumos',
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(
                color: Color(0xFF9A7B4F), width: 1), // Gold border
          ),
          minimumSize: const Size(200, 50),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF2A1A0A), // Dark wood-like color
        titleTextStyle: TextStyle(
          fontFamily: 'ParryHotter',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE2D3A7),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: const Color(0xFF9A7B4F), // Gold
        inactiveTrackColor: const Color(0xFF3A3A3A), // Dark gray
        thumbColor: const Color(0xFFE2D3A7), // Light parchment
        overlayColor: const Color(0xFF740001).withOpacity(0.3),
        valueIndicatorColor: const Color(0xFF2A1A0A),
        valueIndicatorTextStyle: const TextStyle(
          color: Color(0xFFE2D3A7),
          fontFamily: 'Lumos',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(
          fontFamily: 'Lumos',
          color: Color(0xFFE2D3A7),
          fontSize: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF9A7B4F), width: 1.5),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF9A7B4F), width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        filled: true,
        fillColor: const Color(0xFF2A2A2A),
      ),
    );

    // Add Harry Potter-specific timer extension
    return baseTheme.copyWith(
      extensions: [
        TimerThemeExtension(
          // Timer progress color
          progressColor: const Color(0xFF9A7B4F), // Gold
          // Timer background color
          backgroundColor: const Color(0xFF1A1A1A), // Dark background
          // Timer text color
          timerTextColor: const Color(0xFFE2D3A7), // Parchment color
          // Timer text style
          timerTextStyle: const TextStyle(
            fontFamily: 'ParryHotter',
            color: Color.fromARGB(255, 68, 13, 116),
            fontSize: 50,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
          // Timer decoration (Golden Snitch inspired)
          timerDecoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF9A7B4F), // Gold
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9A7B4F).withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          // Sound to play when timer starts
          soundAsset: 'assets/sounds/Voicy_Descendo - Spell SFX.mp3',
          // Background image for the mission screen
          backgroundAsset: 'assets/tanjiro/harrypotter_mission.jpg',
          timerBackgroundAsset: 'assets/tanjiro/harrypotter_golden.jpg',
          // Optional overlay widget like floating magical elements
          overlayWidget: null,
        ),
      ],
    );
  }
}

// Define a custom extension for timer-specific theme data
class TimerThemeExtension extends ThemeExtension<TimerThemeExtension> {
  final Color progressColor;
  final Color backgroundColor;
  final Color timerTextColor;
  final TextStyle timerTextStyle;
  final BoxDecoration timerDecoration;
  final String soundAsset;
  final String backgroundAsset;
  final String timerBackgroundAsset;
  final Widget? overlayWidget;

  TimerThemeExtension({
    required this.progressColor,
    required this.backgroundColor,
    required this.timerTextColor,
    required this.timerTextStyle,
    required this.timerDecoration,
    required this.soundAsset,
    required this.backgroundAsset,
    required this.timerBackgroundAsset,
    this.overlayWidget,
  });

  @override
  TimerThemeExtension copyWith({
    Color? progressColor,
    Color? backgroundColor,
    Color? timerTextColor,
    TextStyle? timerTextStyle,
    BoxDecoration? timerDecoration,
    String? soundAsset,
    String? backgroundAsset,
    String? timerBackgroundAsset,
    Widget? overlayWidget,
  }) {
    return TimerThemeExtension(
      progressColor: progressColor ?? this.progressColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      timerTextColor: timerTextColor ?? this.timerTextColor,
      timerTextStyle: timerTextStyle ?? this.timerTextStyle,
      timerDecoration: timerDecoration ?? this.timerDecoration,
      soundAsset: soundAsset ?? this.soundAsset,
      backgroundAsset: backgroundAsset ?? this.backgroundAsset,
      timerBackgroundAsset: timerBackgroundAsset ?? this.timerBackgroundAsset,
      overlayWidget: overlayWidget ?? this.overlayWidget,
    );
  }

  @override
  ThemeExtension<TimerThemeExtension> lerp(
      ThemeExtension<TimerThemeExtension>? other, double t) {
    if (other is! TimerThemeExtension) {
      return this;
    }
    return TimerThemeExtension(
      progressColor: Color.lerp(progressColor, other.progressColor, t)!,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      timerTextColor: Color.lerp(timerTextColor, other.timerTextColor, t)!,
      timerTextStyle: TextStyle.lerp(timerTextStyle, other.timerTextStyle, t)!,
      timerDecoration:
          BoxDecoration.lerp(timerDecoration, other.timerDecoration, t)!,
      soundAsset: t < 0.5 ? soundAsset : other.soundAsset,
      backgroundAsset: t < 0.5 ? backgroundAsset : other.backgroundAsset,
      timerBackgroundAsset:
          t < 0.5 ? timerBackgroundAsset : other.timerBackgroundAsset,
      overlayWidget: t < 0.5 ? overlayWidget : other.overlayWidget,
    );
  }
}

/*class UpcomingTaskNotification extends StatelessWidget {
  final Map<String, dynamic>? upcomingTask;
  final double height;
  final Color backgroundColor;
  final Color textColor;

  const UpcomingTaskNotification({
    Key? key,
    required this.upcomingTask,
    this.height = 80.0,
    this.backgroundColor = const Color(0xFFE3F2FD), // Light blue background
    this.textColor = const Color(0xFF1565C0), // Darker blue text
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Space for character image (1.5x height of the bar)
          SizedBox(
            width: height * 1.2, // Width for the character image
            child: Stack(
              alignment: Alignment.bottomLeft,
              children: [
                // Position the character image to be 1.5x the height of the container
                Positioned(
                  bottom: 0,
                  left: 0,
                  child: Image.asset(
                    'assets/tanjiro/harrypotter_notif.jpg', // Replace with your character asset path
                    height: height * 1.5,
                    width: height * 1.2,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: height * 1.5,
                        width: height * 1.2,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: const Center(
                          child:
                              Icon(Icons.person, size: 48, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Task information
          Expanded(
            child: upcomingTask != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Upcoming Task:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          upcomingTask!['title'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDueDate(upcomingTask!['due_date']),
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'No upcoming tasks',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
          ),

          // Arrow icon
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(
              Icons.arrow_forward_ios,
              color: textColor,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDueDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'No due date';
    }

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = date.difference(now).inDays;

      if (difference == 0) {
        return 'Due today - ${DateFormat('h:mm a').format(date)}';
      } else if (difference == 1) {
        return 'Due tomorrow - ${DateFormat('h:mm a').format(date)}';
      } else if (difference > 1) {
        return 'Due ${DateFormat('MMM d, yyyy').format(date)}';
      } else {
        return 'Overdue by ${-difference} days';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}*/
class TaskNotificationBar extends StatelessWidget {
  final Map<String, dynamic>? upcomingTask;
  final VoidCallback? onDismiss;
  final Widget? leadingImage;

  const TaskNotificationBar({
    super.key,
    required this.upcomingTask,
    this.onDismiss,
    this.leadingImage,
  });

  @override
  Widget build(BuildContext context) {
    if (upcomingTask == null) {
      return const SizedBox.shrink(); // No notification if no upcoming task
    }

    // Format due date if available
    String formattedDate = '';
    if (upcomingTask!['due_date'] != null &&
        upcomingTask!['due_date'].isNotEmpty) {
      try {
        final dueDate = DateTime.parse(upcomingTask!['due_date']);
        formattedDate = DateFormat('MMM d, yyyy').format(dueDate);
      } catch (e) {
        formattedDate = upcomingTask!['due_date'];
      }
    }

    // Generate a friendly, exciting message
    String timePhrase = _getTimePhrase(upcomingTask!['due_date']);

    return GestureDetector(
      onTap: () => _showTaskDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image slot instead of icon
            leadingImage ??
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.task_alt,
                    color: Colors.red[800],
                    size: 20,
                  ),
                ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Your task \"${upcomingTask!['title']}\" is coming up $timePhrase! Tap to view details.",
                style: TextStyle(
                  color: Colors.red[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red[800], size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimePhrase(String? dueDateStr) {
    if (dueDateStr == null || dueDateStr.isEmpty) {
      return "soon";
    }

    try {
      final dueDate = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final difference = dueDate.difference(now);

      if (difference.inDays == 0) {
        return "today";
      } else if (difference.inDays == 1) {
        return "tomorrow";
      } else if (difference.inDays < 7) {
        return "this week";
      } else if (difference.inDays < 30) {
        return "soon";
      } else {
        return "on ${DateFormat('MMM d').format(dueDate)}";
      }
    } catch (e) {
      return "soon";
    }
  }

  void _showTaskDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(upcomingTask!['title']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (upcomingTask!['description'] != null &&
                upcomingTask!['description'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(upcomingTask!['description']),
              ),

            // Due date info
            if (upcomingTask!['due_date'] != null &&
                upcomingTask!['due_date'].isNotEmpty)
              _buildInfoRow(
                Icons.calendar_today,
                "Due date: ${_formatDueDate(upcomingTask!['due_date'])}",
              ),

            // Reminder info
            if (upcomingTask!['reminder_option'] != null)
              _buildInfoRow(
                Icons.notifications,
                "Reminder: ${upcomingTask!['reminder_option']}${_formatReminderTime(upcomingTask!['reminder_time'])}",
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
          ElevatedButton(
            onPressed: () {
              // Mark as completed option
              TaskService.toggleTaskCompletion(upcomingTask!['id'], true)
                  .then((_) {
                Navigator.pop(context);
                if (onDismiss != null) {
                  onDismiss!();
                }
              });
            },
            child: const Text("MARK COMPLETE"),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  String _formatDueDate(String dueDateStr) {
    try {
      final dueDate = DateTime.parse(dueDateStr);
      return DateFormat('EEEE, MMM d, yyyy').format(dueDate);
    } catch (e) {
      return dueDateStr;
    }
  }

  String _formatReminderTime(String? reminderTime) {
    if (reminderTime == null || reminderTime.isEmpty) {
      return "";
    }
    return " at $reminderTime";
  }
}

// Helper class for updating upcoming task notifications
class TaskNotificationHelper {
  // StreamController to broadcast notification updates
  static final _notificationStreamController =
      StreamController<Map<String, dynamic>?>.broadcast();

  // Stream that UI components can listen to
  static Stream<Map<String, dynamic>?> get notificationStream =>
      _notificationStreamController.stream;

  // Get the next upcoming task notification
  static Future<Map<String, dynamic>?> getNextTaskNotification(
      String userId) async {
    final task = await TaskService.getUpcomingTask(userId);
    return task;
  }

  // Refresh notifications and broadcast the update
  static Future<void> refreshTaskNotifications(String userId) async {
    try {
      // Get the latest upcoming task
      final task = await TaskService.getUpcomingTask(userId);

      // Broadcast the update to all listeners
      _notificationStreamController.add(task);
    } catch (e) {
      print('Error refreshing task notifications: $e');
      // Still add null to the stream to notify listeners even on error
      _notificationStreamController.add(null);
    }
  }

  // Dispose the stream controller when no longer needed
  static void dispose() {
    _notificationStreamController.close();
  }
}
