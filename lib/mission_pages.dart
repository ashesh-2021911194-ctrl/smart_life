import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:just_audio/just_audio.dart';
import 'home_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';
import 'package:flutter/widgets.dart' show BuildContext;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('missions.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE missions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        mission_name TEXT NOT NULL,
        accuracy REAL NOT NULL,
        goal_time TEXT NOT NULL,
        spent_time TEXT NOT NULL,
        distraction_time TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
  }

  // Save mission to SQLite
  Future<int> saveMission({
    required String userId,
    required String missionName,
    required double accuracy,
    required Duration goalTime,
    required Duration spentTime,
    required Duration distractionTime,
  }) async {
    final db = await database;

    // Convert durations to string format
    String formatDuration(Duration d) {
      return "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
    }

    final data = {
      'user_id': userId,
      'mission_name': missionName,
      'accuracy': accuracy,
      'goal_time': formatDuration(goalTime),
      'spent_time': formatDuration(spentTime),
      'distraction_time': formatDuration(distractionTime),
      'date': DateTime.now().toIso8601String(),
    };

    return await db.insert('missions', data);
  }

  // Fetch all missions for a user
  Future<List<Map<String, dynamic>>> fetchPastMissions(String userId) async {
    final db = await database;
    return await db.query(
      'missions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
  }

  // Delete a mission
  Future<int> deleteMission(int missionId) async {
    final db = await database;
    return await db.delete(
      'missions',
      where: 'id = ?',
      whereArgs: [missionId],
    );
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

/*const String baseUrl =
    "http://192.168.0.114:5000"; // Replace with actual backend URL

Future<void> saveMission({
  required String userId,
  required String missionName,
  required double accuracy,
  required Duration goalTime,
  required Duration spentTime,
  required Duration distractionTime,
}) async {
  final url = Uri.parse('$baseUrl/save-mission');

  // Convert durations to PostgreSQL interval format
  String formatDuration(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "user_id": userId,
        "mission_name": missionName,
        "accuracy": accuracy,
        "goal_time": formatDuration(goalTime),
        "spent_time": formatDuration(spentTime),
        "distraction_time": formatDuration(distractionTime),
      }),
    );

    if (response.statusCode == 200) {
      print("Mission saved successfully: ${response.body}");
    } else {
      print(
          "Failed to save mission: ${response.statusCode} - ${response.body}");
      throw Exception("Failed to save mission: ${response.body}");
    }
  } catch (e) {
    print("Error saving mission: $e");
    rethrow;
  }
}

Future<List<Map<String, dynamic>>> fetchPastMissions(String userId) async {
  final url = Uri.parse('$baseUrl/past-missions?user_id=$userId');
  print("Fetching missions from: $url");

  try {
    final response = await http.get(url);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      print("Parsed data length: ${data.length}");
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(
          "Failed to fetch past missions: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("Error in fetchPastMissions: $e");
    rethrow;
  }
}

Future<void> deleteMission(String token, int missionId) async {
  final url = Uri.parse('$baseUrl/delete-mission/$missionId');

  final response = await http.delete(
    url,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    print("Mission deleted successfully");
  } else {
    print("Failed to delete mission: ${response.body}");
  }
}*/
// Save mission to local SQLite database
Future<int> saveMission({
  required String userId,
  required String missionName,
  required double accuracy,
  required Duration goalTime,
  required Duration spentTime,
  required Duration distractionTime,
}) async {
  try {
    final id = await DatabaseHelper.instance.saveMission(
      userId: userId,
      missionName: missionName,
      accuracy: accuracy,
      goalTime: goalTime,
      spentTime: spentTime,
      distractionTime: distractionTime,
    );
    print("Mission saved successfully with ID: $id");
    return id;
  } catch (e) {
    print("Error saving mission: $e");
    rethrow;
  }
}

// Fetch past missions from local SQLite database
Future<List<Map<String, dynamic>>> fetchPastMissions(String userId) async {
  try {
    final missions = await DatabaseHelper.instance.fetchPastMissions(userId);
    print("Fetched ${missions.length} missions");
    return missions;
  } catch (e) {
    print("Error in fetchPastMissions: $e");
    rethrow;
  }
}

// Delete mission from local SQLite database
Future<void> deleteMission(int missionId) async {
  try {
    final result = await DatabaseHelper.instance.deleteMission(missionId);
    if (result > 0) {
      print("Mission deleted successfully");
    } else {
      print("No mission found with ID: $missionId");
    }
  } catch (e) {
    print("Error deleting mission: $e");
    rethrow;
  }
}
// Import API functions

/*class MissionScreen extends StatefulWidget {
  final String userId;
  const MissionScreen({super.key, required this.userId});

  @override
  _MissionScreenState createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with WidgetsBindingObserver {
  bool isRunning = false;
  DateTime? missionStartTime;
  Timer? countdownTimer;
  Duration goalDuration = const Duration(minutes: 30);
  Duration elapsedTime = Duration.zero;
  Duration distractionTime = Duration.zero;
  DateTime? distractionStartTime;

  TextEditingController missionNameController = TextEditingController();
  int selectedMinutes = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    countdownTimer?.cancel();
    missionNameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isRunning) {
      distractionStartTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed && isRunning) {
      if (distractionStartTime != null) {
        setState(() {
          distractionTime += DateTime.now().difference(distractionStartTime!);
        });
        distractionStartTime = null;
      }
    }
  }

  void _startTimer() {
    if (!isRunning) {
      setState(() {
        goalDuration = Duration(minutes: selectedMinutes);
        isRunning = true;
        missionStartTime = DateTime.now();
        elapsedTime = Duration.zero;
        distractionTime = Duration.zero;

        countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (elapsedTime >= goalDuration) {
            timer.cancel();
            isRunning = false;
          } else {
            setState(() {
              elapsedTime += const Duration(seconds: 1);
            });
          }
        });
      });
    }
  }

  Future<void> _saveMission() async {
    if (missionStartTime == null || missionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Enter a mission name and start the timer first")),
      );
      return;
    }

    try {
      final missionName = missionNameController.text;
      final accuracy = calculateAccuracy();
      final goal = goalDuration;
      final spent = elapsedTime;
      final distraction = distractionTime;
      final date = DateTime.now().toIso8601String();

      await saveMission(
        userId: widget.userId,
        missionName: missionName,
        accuracy: accuracy,
        goalTime: goal,
        spentTime: spent,
        distractionTime: distraction,
      );

      countdownTimer?.cancel();
      setState(() {
        isRunning = false;
        missionStartTime = null;
        elapsedTime = Duration.zero;
        distractionTime = Duration.zero;
        missionNameController.clear();
      });

      // Build the mission map to pass to the details screen
      Map<String, dynamic> missionData = {
        "mission_name": missionName,
        "accuracy": accuracy,
        "goal_time": goal.toString(),
        "spent_time": spent.toString(),
        "distraction_time": distraction.toString(),
        "date": date,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MissionDetailsScreen(mission: missionData),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mission saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save mission: $e")),
      );
    }
  }

  double calculateAccuracy() {
    final total = elapsedTime.inSeconds;
    if (total == 0) return 100.0;
    final focus = total - distractionTime.inSeconds;
    return (focus / total * 100).clamp(0.0, 100.0);
  }

  String formatDuration(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final remainingTime = goalDuration - elapsedTime;
    final progress = goalDuration.inSeconds == 0
        ? 0.0
        : elapsedTime.inSeconds / goalDuration.inSeconds;
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    // Get the current wallpaper from ThemeNotifier
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.missionWallpaper;

    return Scaffold(
      appBar: AppBar(title: const Text('Start a Mission')),
      resizeToAvoidBottomInset:
          true, // Helps avoid overflow when keyboard appears
      body: Stack(
    children: [
      // 🌄 Background Image
      Image.asset(
        wallpaperAsset, // make sure this is defined based on theme
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      ),

      // 🌫️ Optional dark overlay for readability
      Container(
        color: Colors.black.withOpacity(0.3), // Optional
      ),

      // 📦 Main content
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: missionNameController,
                decoration: const InputDecoration(
                  labelText: "Enter Mission Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Set Goal (mins):",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: selectedMinutes.toDouble(),
                min: 5,
                max: 120,
                divisions: 23,
                label: "$selectedMinutes min",
                onChanged: (val) {
                  setState(() {
                    selectedMinutes = val.toInt();
                    goalDuration = Duration(
                        minutes:
                            selectedMinutes); // ensure goalDuration updates
                  });
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: CircularPercentIndicator(
                  radius: 120.0,
                  lineWidth: 12.0,
                  percent: progress.clamp(0.0, 1.0),
                  center: Text(
                    formatDuration(remainingTime),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  progressColor: Colors.blue,
                  backgroundColor: Colors.grey[300]!,
                  circularStrokeCap: CircularStrokeCap.round,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  "Distraction Time: ${formatDuration(distractionTime)}",
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _startTimer,
                child: Text(isRunning ? "Running..." : "Start Mission"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveMission,
                child: const Text("Save Mission"),
              ),
            ],
          ),
        ),
      ),
    ],
    ),
    );
  }
}*/
/*class MissionScreen extends StatefulWidget {
  final String userId;
  const MissionScreen({super.key, required this.userId});

  @override
  _MissionScreenState createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool isRunning = false;
  DateTime? missionStartTime;
  Timer? countdownTimer;
  Duration goalDuration = const Duration(minutes: 30);
  Duration elapsedTime = Duration.zero;
  Duration distractionTime = Duration.zero;
  DateTime? distractionStartTime;
  late AnimationController _animationController;
  bool hasPlayedSound = false;

  // Sound player
  final AudioPlayer _audioPlayer = AudioPlayer();

  TextEditingController missionNameController = TextEditingController();
  int selectedMinutes = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    countdownTimer?.cancel();
    missionNameController.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isRunning) {
      distractionStartTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed && isRunning) {
      if (distractionStartTime != null) {
        setState(() {
          distractionTime += DateTime.now().difference(distractionStartTime!);
        });
        distractionStartTime = null;
      }
    }
  }

  Future<void> _playTimerStartSound(String soundAsset) async {
    if (!hasPlayedSound) {
      await _audioPlayer.setAsset(soundAsset);
      await _audioPlayer.play();
      hasPlayedSound = true;
    }
  }

  void _startTimer(BuildContext context) {
    if (!isRunning) {
      setState(() {
        goalDuration = Duration(minutes: selectedMinutes);
        isRunning = true;
        missionStartTime = DateTime.now();
        elapsedTime = Duration.zero;
        distractionTime = Duration.zero;
        hasPlayedSound = false;
      });

      // Get theme-specific sound - use the context from build method
      final timerTheme = Theme.of(context).extension<TimerThemeExtension>();
      if (timerTheme != null) {
        _playTimerStartSound(timerTheme.soundAsset);
      }

      // Start the animation
      _animationController.forward();

      // Create and start the countdown timer
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (isRunning) {
            final now = DateTime.now();
            if (missionStartTime != null) {
              final totalDuration = now.difference(missionStartTime!);
              elapsedTime = totalDuration - distractionTime;

              if (elapsedTime >= goalDuration) {
                timer.cancel();
                isRunning = false;
                _animationController.reverse();
              }
            }
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  
  Future<void> _saveMission(BuildContext context) async {
    if (missionStartTime == null || missionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Enter a mission name and start the timer first")),
      );
      return;
    }

    try {
      final missionName = missionNameController.text;
      final accuracy = calculateAccuracy();
      final goal = goalDuration;
      final spent = elapsedTime;
      final distraction = distractionTime;

      final missionId = await saveMission(
        userId: widget.userId,
        missionName: missionName,
        accuracy: accuracy,
        goalTime: goal,
        spentTime: spent,
        distractionTime: distraction,
      );

      countdownTimer?.cancel();
      setState(() {
        isRunning = false;
        missionStartTime = null;
        elapsedTime = Duration.zero;
        distractionTime = Duration.zero;
        missionNameController.clear();
      });

      // Fetch the saved mission to get all fields including date
      final missions = await fetchPastMissions(widget.userId);
      final savedMission = missions.firstWhere((m) => m['id'] == missionId);

      Navigator.push(
        context as BuildContext,
        MaterialPageRoute(
          builder: (context) => MissionDetailsScreen(mission: savedMission),
        ),
      );

      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text("Mission saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text("Failed to save mission: $e")),
      );
    }
  }

  double calculateAccuracy() {
    final goal = goalDuration.inSeconds;
    final focused = (elapsedTime - distractionTime).inSeconds;

    if (goal == 0) return 100.0; // Avoid division by zero

    return (focused / goal * 100).clamp(0.0, 100.0);
  }

  String formatDuration(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final remainingTime = goalDuration - elapsedTime;
    final progress = goalDuration.inSeconds == 0
        ? 0.0
        : elapsedTime.inSeconds / goalDuration.inSeconds;

    // Get theme extension with timer styling
    final timerTheme = Theme.of(context).extension<TimerThemeExtension>();

    // Fallback values if theme extension is not available
    final progressColor = timerTheme?.progressColor ?? Colors.blue;
    final backgroundColor = timerTheme?.backgroundColor ?? Colors.grey[300]!;
    final timerTextStyle = timerTheme?.timerTextStyle ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    final timerDecoration =
        timerTheme?.timerDecoration ?? BoxDecoration(color: Colors.transparent);
    final backgroundAsset =
        timerTheme?.backgroundAsset ?? 'assets/deadpool/mission_wallpaper.jpg';
    final timerBackgroundAsset = timerTheme?.timerBackgroundAsset ??
        'assets/deadpool/deadpool_timer_bg.png';

    return Scaffold(
      appBar: AppBar(title: const Text('Start a Mission')),
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background Image
          Image.asset(
            backgroundAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Dark overlay for readability
          Container(
            color: Colors.black.withOpacity(0.3),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mission name input
                  TextField(
                    controller: missionNameController,
                    decoration: const InputDecoration(
                      labelText: "Enter Mission Name",
                    ),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),

                  // Goal setting
                  Text(
                    "Set Goal (mins):",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Slider(
                    value: selectedMinutes.toDouble(),
                    min: 5,
                    max: 120,
                    divisions: 23,
                    label: "$selectedMinutes min",
                    onChanged: (val) {
                      setState(() {
                        selectedMinutes = val.toInt();
                        goalDuration = Duration(minutes: selectedMinutes);
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Themed timer
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Custom timer decoration from theme
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(timerBackgroundAsset),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Custom timer decoration from theme (borders, etc)
                        Container(
                          width: 260,
                          height: 260,
                          decoration: timerDecoration.copyWith(
                            // Make sure the decoration doesn't have a background color that would hide the image
                            color: Colors.transparent,
                          ),
                        ),

                        // Theme-specific overlay widget (e.g., Deadpool eyes)
                        if (timerTheme?.overlayWidget != null)
                          timerTheme!.overlayWidget!,

                        // Progress indicator
                        SizedBox(
                          width: 240,
                          height: 240,
                          child: CircularPercentIndicator(
                            radius: 120.0,
                            lineWidth: 12.0,
                            percent: progress.clamp(0.0, 1.0),
                            backgroundColor: backgroundColor,
                            progressColor: progressColor,
                            circularStrokeCap: CircularStrokeCap.round,
                            center: Text(
                              formatDuration(remainingTime),
                              style: timerTextStyle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Distraction time
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Distraction Time: ${formatDuration(distractionTime)}",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Start mission button
                  ElevatedButton(
                    onPressed: isRunning
                        ? null
                        : () => _startTimer(context), // Wrap in function
                    child: Text(isRunning ? "Running..." : "Start Mission"),
                  ),
                  const SizedBox(height: 16),

                  // Save mission button
                  // Save mission button
                  ElevatedButton(
                    onPressed: () => _saveMission(context), // Wrap in function
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text("Save Mission"),
                  ),

                  // If current theme is Deadpool, add the quote
                  if (timerTheme?.backgroundAsset.contains('deadpool') ?? false)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          '"Maximum Effort!"',
                          style: TextStyle(
                            fontFamily: 'Bangers',
                            color: Colors.white,
                            fontSize: 20,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}*/

// This service will maintain the mission timer state throughout the app
class MissionTimerService extends ChangeNotifier {
  static final MissionTimerService _instance = MissionTimerService._internal();
  factory MissionTimerService() => _instance;
  MissionTimerService._internal();

  bool isRunning = false;
  DateTime? missionStartTime;
  Duration goalDuration = const Duration(minutes: 30);
  Duration elapsedTime = Duration.zero;
  Duration distractionTime = Duration.zero;
  DateTime? distractionStartTime;
  String missionName = '';
  Timer? countdownTimer;
  bool hasPlayedSound = false;

  void startTimer({required int minutes, required String name}) {
    if (!isRunning) {
      goalDuration = Duration(minutes: minutes);
      isRunning = true;
      missionStartTime = DateTime.now();
      elapsedTime = Duration.zero;
      distractionTime = Duration.zero;
      missionName = name;
      hasPlayedSound = false;

      // Create and start the countdown timer
      countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isRunning) {
          final now = DateTime.now();
          if (missionStartTime != null) {
            final totalDuration = now.difference(missionStartTime!);
            elapsedTime = totalDuration - distractionTime;

            if (elapsedTime >= goalDuration) {
              timer.cancel();
              isRunning = false;
            }
          }
        } else {
          timer.cancel();
        }
        notifyListeners();
      });
      notifyListeners();
    }
  }

  void stopTimer() {
    countdownTimer?.cancel();
    isRunning = false;
    notifyListeners();
  }

  void resetTimer() {
    countdownTimer?.cancel();
    isRunning = false;
    missionStartTime = null;
    elapsedTime = Duration.zero;
    distractionTime = Duration.zero;
    missionName = '';
    hasPlayedSound = false;
    notifyListeners();
  }

  void onAppLifecycleChange(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && isRunning) {
      distractionStartTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed && isRunning) {
      if (distractionStartTime != null) {
        distractionTime += DateTime.now().difference(distractionStartTime!);
        distractionStartTime = null;
        notifyListeners();
      }
    }
  }

  double calculateAccuracy() {
    final goal = goalDuration.inSeconds;
    final focused = (elapsedTime - distractionTime).inSeconds;

    if (goal == 0) return 100.0; // Avoid division by zero
    return (focused / goal * 100).clamp(0.0, 100.0);
  }

  String formatDuration(Duration d) {
    return "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }
}

class MissionScreen extends StatefulWidget {
  final String userId;
  const MissionScreen({super.key, required this.userId});

  @override
  _MissionScreenState createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Use the timer service
  final MissionTimerService _timerService = MissionTimerService();

  // Sound player
  final AudioPlayer _audioPlayer = AudioPlayer();

  TextEditingController missionNameController = TextEditingController();
  int selectedMinutes = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Listen to changes in the timer service
    _timerService.addListener(_onTimerServiceUpdate);

    // Restore timer state if it's already running
    if (_timerService.isRunning) {
      missionNameController.text = _timerService.missionName;
      selectedMinutes = _timerService.goalDuration.inMinutes;

      // Start animation if timer is running
      _animationController.forward();
    }
  }

  void _onTimerServiceUpdate() {
    // This is called whenever the timer service has an update
    if (mounted) {
      setState(() {
        // Update UI based on timer service state
        if (!_timerService.isRunning && _animationController.value > 0) {
          _animationController.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    missionNameController.dispose();
    _animationController.dispose();
    _audioPlayer.dispose();

    // Remove listener when disposing
    _timerService.removeListener(_onTimerServiceUpdate);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Forward lifecycle events to the timer service
    _timerService.onAppLifecycleChange(state);
  }

  Future<void> _playTimerStartSound(String soundAsset) async {
    if (!_timerService.hasPlayedSound) {
      await _audioPlayer.setAsset(soundAsset);
      await _audioPlayer.play();
      _timerService.hasPlayedSound = true;
    }
  }

  void _startTimer(BuildContext context) {
    if (!_timerService.isRunning) {
      // Start animation
      _animationController.forward();

      // Get theme-specific sound
      final timerTheme = Theme.of(context).extension<TimerThemeExtension>();
      if (timerTheme != null) {
        _playTimerStartSound(timerTheme.soundAsset);
      }

      // Start the timer using the service
      _timerService.startTimer(
        minutes: selectedMinutes,
        name: missionNameController.text,
      );
    }
  }

  Future<void> _saveMission(BuildContext context) async {
    if (!_timerService.isRunning && _timerService.missionStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Start the timer first")),
      );
      return;
    }

    if (missionNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a mission name")),
      );
      return;
    }

    try {
      final missionName = missionNameController.text;
      final accuracy = _timerService.calculateAccuracy();
      final goal = _timerService.goalDuration;
      final spent = _timerService.elapsedTime;
      final distraction = _timerService.distractionTime;

      final missionId = await saveMission(
        userId: widget.userId,
        missionName: missionName,
        accuracy: accuracy,
        goalTime: goal,
        spentTime: spent,
        distractionTime: distraction,
      );

      // Reset the timer service
      _timerService.resetTimer();

      setState(() {
        missionNameController.clear();
      });

      // Fetch the saved mission to get all fields including date
      final missions = await fetchPastMissions(widget.userId);
      final savedMission = missions.firstWhere((m) => m['id'] == missionId);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MissionDetailsScreen(mission: savedMission),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mission saved successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save mission: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingTime =
        _timerService.goalDuration - _timerService.elapsedTime;
    final progress = _timerService.goalDuration.inSeconds == 0
        ? 0.0
        : _timerService.elapsedTime.inSeconds /
            _timerService.goalDuration.inSeconds;

    // Get theme extension with timer styling
    final timerTheme = Theme.of(context).extension<TimerThemeExtension>();

    // Fallback values if theme extension is not available
    final progressColor = timerTheme?.progressColor ?? Colors.blue;
    final backgroundColor = timerTheme?.backgroundColor ?? Colors.grey[300]!;
    final timerTextStyle = timerTheme?.timerTextStyle ??
        const TextStyle(fontSize: 24, fontWeight: FontWeight.bold);
    final timerDecoration =
        timerTheme?.timerDecoration ?? const BoxDecoration(color: Colors.transparent);
    final backgroundAsset =
        timerTheme?.backgroundAsset ?? 'assets/deadpool/mission_wallpaper.jpg';
    final timerBackgroundAsset = timerTheme?.timerBackgroundAsset ??
        'assets/deadpool/deadpool_timer_bg.png';

    return WillPopScope(
      // Monitor attempts to leave the page
      onWillPop: () async {
        // Timer will continue running when navigating away
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Start a Mission'),
          // Add a timer indicator in the app bar if timer is running
          actions: [
            if (_timerService.isRunning)
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Text(
                    _timerService.formatDuration(remainingTime),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // Background Image
            Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),

            // Dark overlay for readability
            Container(
              color: Colors.black.withOpacity(0.3),
            ),

            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mission name input
                    TextField(
                      controller: missionNameController,
                      decoration: const InputDecoration(
                        labelText: "Enter Mission Name",
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      // Always enabled so user can edit the mission name
                      onChanged: (value) {
                        // If timer is running, update the mission name in the service
                        if (_timerService.isRunning) {
                          _timerService.missionName = value;
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Goal setting
                    Text(
                      "Set Goal (mins):",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Slider(
                      value: selectedMinutes.toDouble(),
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: "$selectedMinutes min",
                      onChanged: _timerService.isRunning
                          ? null
                          : (val) {
                              setState(() {
                                selectedMinutes = val.toInt();
                              });
                            },
                    ),
                    const SizedBox(height: 24),

                    // Themed timer
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Custom timer decoration from theme
                          Container(
                            width: 260,
                            height: 260,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(timerBackgroundAsset),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),

                          // Custom timer decoration from theme (borders, etc)
                          Container(
                            width: 260,
                            height: 260,
                            decoration: timerDecoration.copyWith(
                              // Make sure the decoration doesn't have a background color that would hide the image
                              color: Colors.transparent,
                            ),
                          ),

                          // Theme-specific overlay widget (e.g., Deadpool eyes)
                          if (timerTheme?.overlayWidget != null)
                            timerTheme!.overlayWidget!,

                          // Progress indicator
                          SizedBox(
                            width: 240,
                            height: 240,
                            child: CircularPercentIndicator(
                              radius: 120.0,
                              lineWidth: 12.0,
                              percent: progress.clamp(0.0, 1.0),
                              backgroundColor: backgroundColor,
                              progressColor: progressColor,
                              circularStrokeCap: CircularStrokeCap.round,
                              center: Text(
                                _timerService.formatDuration(remainingTime),
                                style: timerTextStyle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Distraction time
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Distraction Time: ${_timerService.formatDuration(_timerService.distractionTime)}",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start mission button
                    ElevatedButton(
                      onPressed: _timerService.isRunning
                          ? null
                          : () => _startTimer(context),
                      child: Text(_timerService.isRunning
                          ? "Running..."
                          : "Start Mission"),
                    ),
                    const SizedBox(height: 16),

                    // Save mission button
                    ElevatedButton(
                      onPressed: () => _saveMission(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondary,
                      ),
                      child: const Text("Save Mission"),
                    ),

                    // If current theme is Deadpool, add the quote
                    if (timerTheme?.backgroundAsset.contains('deadpool') ??
                        false)
                      const Padding(
                        padding: EdgeInsets.only(top: 24),
                        child: Center(
                          child: Text(
                            '"Maximum Effort!"',
                            style: TextStyle(
                              fontFamily: 'Bangers',
                              color: Colors.white,
                              fontSize: 20,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PastMissionsScreen extends StatefulWidget {
  final String userId;
  const PastMissionsScreen({super.key, required this.userId});

  @override
  _PastMissionsScreenState createState() => _PastMissionsScreenState();
}

class _PastMissionsScreenState extends State<PastMissionsScreen> {
  List<Map<String, dynamic>> pastMissions = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  /*Future<void> _loadMissions() async {
    try {
      List<Map<String, dynamic>> missions =
          await fetchPastMissions(widget.userId);
      setState(() {
        pastMissions = missions;
      });
    } catch (error) {
      print("Error loading missions: $error");
    }
  }

  void _deleteMission(int missionId) async {
    await deleteMission(widget.userId, missionId);
    _loadMissions(); // Refresh list
  }*/

  Future<void> _loadMissions() async {
    setState(() {
      isLoading = true;
    });

    try {
      List<Map<String, dynamic>> missions =
          await fetchPastMissions(widget.userId);
      setState(() {
        pastMissions = missions;
        isLoading = false;
      });
    } catch (error) {
      print("Error loading missions: $error");
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text("Failed to load missions: $error")),
      );
    }
  }

  void _deleteMission(int missionId) async {
    try {
      await deleteMission(missionId);
      _loadMissions(); // Refresh list
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(content: Text("Mission deleted successfully")),
      );
    } catch (error) {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text("Failed to delete mission: $error")),
      );
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    // Get the current wallpaper from ThemeNotifier
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.missionWallpaper;
    return Scaffold(
      appBar: AppBar(title: const Text("Past Missions")),
      body: Stack(
        children: [
          // 🌄 Background Image
          Image.asset(
            wallpaperAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // 🌫️ Optional overlay for readability
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          Column(
            children: [
              ElevatedButton(
                onPressed: _loadMissions,
                child: const Text("Refresh Missions"),
              ),
              Expanded(
                child: pastMissions.isEmpty
                    ? const Center(child: Text("No missions found. Start one!"))
                    : ListView.builder(
                        itemCount: pastMissions.length,
                        itemBuilder: (context, index) {
                          final mission = pastMissions[index];
                          return ListTile(
                            title: Text(
                                mission["mission_name"] ?? "Unnamed Mission"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Accuracy: ${mission["accuracy"]}%"),
                                Text(
                                    "Date: ${mission["date"]?.toString().split('T')[0] ?? "Unknown"}"),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      MissionDetailsScreen(mission: mission),
                                ),
                              );
                            },
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                if (mission["id"] != null) {
                                  _deleteMission(mission["id"]);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Cannot delete: Missing ID")),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MissionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> mission;

  const MissionDetailsScreen({super.key, required this.mission});

  String formatDuration(dynamic duration) {
    if (duration is String) {
      final parts =
          duration.split(':').map((e) => int.parse(e.split('.')[0])).toList();
      final hours = parts[0];
      final minutes = parts[1];
      final seconds = parts[2];
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }
    return duration.toString();
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    // Get the current wallpaper from ThemeNotifier
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.expenseWallpaper;

    return Scaffold(
      appBar: AppBar(title: Text(mission["mission_name"] ?? "Mission Details")),
      body: Stack(
        children: [
          // 🌄 Background Image
          Image.asset(
            wallpaperAsset, // make sure this is defined based on theme
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // 🌫️ Optional dark overlay for readability
          Container(
            color: Colors.black.withOpacity(0.3), // Optional
          ),

          // 📦 Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    _buildDetail("Mission Name", mission["mission_name"]),
                    _buildDetail("Success Rate", "${mission["accuracy"]}%"),
                    _buildDetail(
                        "Goal Time", formatDuration(mission["goal_time"])),
                    _buildDetail(
                        "Spent Time", formatDuration(mission["spent_time"])),
                    _buildDetail("Distraction Time",
                        formatDuration(mission["distraction_time"])),
                    _buildDetail("Date",
                        mission["date"]?.toString().split('T')[0] ?? "Unknown"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
