import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
// Add this to your existing models/services file

/*class Budget {
  final String userId;
  final double budgetAmount;
  final String budgetType; // 'daily', 'weekly', 'monthly'
  final DateTime updatedAt;

  Budget({
    required this.userId,
    required this.budgetAmount,
    required this.budgetType,
    required this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      userId: json['user_id'],
      budgetAmount: double.parse(json['budget_amount'].toString()),
      budgetType: json['budget_type'] ?? 'monthly',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}*/

class DatabaseHelperExpense {
  static const _databaseName = "expense_tracker.db";
  static const _databaseVersion = 1;

  // Expense table (unchanged from previous implementation)
  static const expenseTable = 'expenses';
  static const expenseId = 'id';
  static const expenseUserId = 'user_id';
  static const expenseAmount = 'amount';
  static const expenseCategory = 'category';
  static const expenseDescription = 'description';
  static const expenseCreatedAt = 'created_at';

  // Budget table
  static const budgetTable = 'budgets';
  static const budgetId = 'id';
  static const budgetUserId = 'user_id';
  static const budgetAmount = 'budget_amount';
  static const budgetType = 'budget_type';
  static const budgetName = 'name';
  static const budgetIsActive = 'is_active';
  static const budgetUpdatedAt = 'updated_at';

  // Singleton instance
  static DatabaseHelperExpense? _instance;
  static Database? _database;

  DatabaseHelperExpense._privateConstructor();

  factory DatabaseHelperExpense() {
    _instance ??= DatabaseHelperExpense._privateConstructor();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create expenses table (unchanged)
    await db.execute('''
      CREATE TABLE $expenseTable (
        $expenseId TEXT PRIMARY KEY,
        $expenseUserId TEXT NOT NULL,
        $expenseAmount REAL NOT NULL,
        $expenseCategory TEXT NOT NULL,
        $expenseDescription TEXT,
        $expenseCreatedAt TEXT NOT NULL
      )
    ''');

    // Create budgets table (updated)
    await db.execute('''
      CREATE TABLE $budgetTable (
        $budgetId TEXT PRIMARY KEY,
        $budgetUserId TEXT NOT NULL,
        $budgetAmount REAL NOT NULL,
        $budgetType TEXT NOT NULL,
        $budgetName TEXT,
        $budgetIsActive INTEGER DEFAULT 0,
        $budgetUpdatedAt TEXT NOT NULL
      )
    ''');
  }

  String _generateId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}

class ExpenseService {
  static final DatabaseHelperExpense _dbHelper = DatabaseHelperExpense();

  // Fetch expenses
  static Future<List<Expense>> getExpenses(String userId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelperExpense.expenseTable,
        where: '${DatabaseHelperExpense.expenseUserId} = ?',
        whereArgs: [userId],
        orderBy: '${DatabaseHelperExpense.expenseCreatedAt} DESC',
      );

      return List.generate(maps.length, (i) {
        return Expense(
          id: maps[i][DatabaseHelperExpense.expenseId],
          userId: maps[i][DatabaseHelperExpense.expenseUserId],
          amount: maps[i][DatabaseHelperExpense.expenseAmount],
          category: maps[i][DatabaseHelperExpense.expenseCategory],
          description: maps[i][DatabaseHelperExpense.expenseDescription] ?? '',
          createdAt:
              DateTime.parse(maps[i][DatabaseHelperExpense.expenseCreatedAt]),
        );
      });
    } catch (e) {
      print('Error fetching expenses: $e');
      throw Exception('Database error: $e');
    }
  }

  // Add an expense
  static Future<bool> addExpense(
    String userId,
    double amount,
    String category,
    String description,
  ) async {
    try {
      final db = await _dbHelper.database;
      final id = _dbHelper._generateId();

      await db.insert(
        DatabaseHelperExpense.expenseTable,
        {
          DatabaseHelperExpense.expenseId: id,
          DatabaseHelperExpense.expenseUserId: userId,
          DatabaseHelperExpense.expenseAmount: amount,
          DatabaseHelperExpense.expenseCategory: category,
          DatabaseHelperExpense.expenseDescription: description,
          DatabaseHelperExpense.expenseCreatedAt:
              DateTime.now().toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      print('Error adding expense: $e');
      throw Exception('Database error: $e');
    }
  }

  // Delete an expense
  static Future<bool> deleteExpense(String id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        DatabaseHelperExpense.expenseTable,
        where: '${DatabaseHelperExpense.expenseId} = ?',
        whereArgs: [id],
      );
      return count > 0;
    } catch (e) {
      print('Error deleting expense: $e');
      throw Exception('Database error: $e');
    }
  }

  // Budget Methods
  static Future<List<Budget>> getUserBudgets(String userId) async {
    try {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelperExpense.budgetTable,
        where: '${DatabaseHelperExpense.budgetUserId} = ?',
        whereArgs: [userId],
        orderBy: '${DatabaseHelperExpense.budgetUpdatedAt} DESC',
      );

      return List.generate(maps.length, (i) => Budget.fromMap(maps[i]));
    } catch (e) {
      print('Error fetching budgets: $e');
      throw Exception('Database error: $e');
    }
  }

  static Future<Budget> createBudget(
    String userId,
    double amount,
    String budgetType,
    String name,
  ) async {
    try {
      final db = await _dbHelper.database;
      final id = _dbHelper._generateId();
      final now = DateTime.now();

      final budget = Budget(
        id: id,
        userId: userId,
        name: name,
        budgetAmount: amount,
        budgetType: budgetType,
        updatedAt: now,
        isActive: false,
      );

      await db.insert(DatabaseHelperExpense.budgetTable, budget.toMap());
      return budget;
    } catch (e) {
      print('Error creating budget: $e');
      throw Exception('Database error: $e');
    }
  }

  static Future<Budget> updateBudget(
    String budgetId,
    String userId,
    double amount,
    String budgetType,
    String name,
  ) async {
    try {
      final db = await _dbHelper.database;
      final now = DateTime.now();

      final budget = Budget(
        id: budgetId,
        userId: userId,
        name: name,
        budgetAmount: amount,
        budgetType: budgetType,
        updatedAt: now,
        isActive: false, // Preserve existing active status
      );

      await db.update(
        DatabaseHelperExpense.budgetTable,
        budget.toMap(),
        where: '${DatabaseHelperExpense.budgetId} = ?',
        whereArgs: [budgetId],
      );
      return budget;
    } catch (e) {
      print('Error updating budget: $e');
      throw Exception('Database error: $e');
    }
  }

  static Future<void> activateBudget(String budgetId, String userId) async {
    try {
      final db = await _dbHelper.database;

      // First deactivate all budgets for this user
      await db.update(
        DatabaseHelperExpense.budgetTable,
        {DatabaseHelperExpense.budgetIsActive: 0},
        where: '${DatabaseHelperExpense.budgetUserId} = ?',
        whereArgs: [userId],
      );

      // Then activate the selected budget
      await db.update(
        DatabaseHelperExpense.budgetTable,
        {
          DatabaseHelperExpense.budgetIsActive: 1,
          DatabaseHelperExpense.budgetUpdatedAt:
              DateTime.now().toIso8601String(),
        },
        where: '${DatabaseHelperExpense.budgetId} = ?',
        whereArgs: [budgetId],
      );
    } catch (e) {
      print('Error activating budget: $e');
      throw Exception('Database error: $e');
    }
  }

  static Future<bool> deleteBudget(String budgetId) async {
    try {
      final db = await _dbHelper.database;

      // Start a transaction to ensure data consistency
      await db.transaction((txn) async {
        // If you have budget categories or related tables, delete them first
        // For example, if you add budget categories in the future:
        // await txn.delete(
        //   'budget_categories',
        //   where: '${DatabaseHelperExpense.budgetCategoryBudgetId} = ?',
        //   whereArgs: [budgetId],
        // );

        // Delete the budget itself
        final count = await txn.delete(
          DatabaseHelperExpense.budgetTable,
          where: '${DatabaseHelperExpense.budgetId} = ?',
          whereArgs: [budgetId],
        );

        return count > 0;
      });

      return true;
    } catch (e) {
      print('Error deleting budget: $e');
      throw Exception('Database error: $e');
    }
  }

  static Future<BudgetStatus> getBudgetStatus(String userId) async {
    try {
      final db = await _dbHelper.database;

      // Get active budget
      final activeBudget = await db.query(
        DatabaseHelperExpense.budgetTable,
        where:
            '${DatabaseHelperExpense.budgetUserId} = ? AND ${DatabaseHelperExpense.budgetIsActive} = 1',
        whereArgs: [userId],
        limit: 1,
      );

      if (activeBudget.isEmpty) {
        throw Exception('No active budget found');
      }

      final budget = Budget.fromMap(activeBudget.first);

      // Calculate expenses for current period (example for monthly budget)
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

      final expenses = await db.rawQuery('''
        SELECT SUM(${DatabaseHelperExpense.expenseAmount}) as total 
        FROM ${DatabaseHelperExpense.expenseTable} 
        WHERE ${DatabaseHelperExpense.expenseUserId} = ? 
        AND ${DatabaseHelperExpense.expenseCreatedAt} BETWEEN ? AND ?
      ''', [
        userId,
        firstDayOfMonth.toIso8601String(),
        lastDayOfMonth.toIso8601String()
      ]);

      final double spent = expenses.first['total'] as double? ?? 0.0;
      final double percentage = (spent / budget.budgetAmount) * 100;
      final double remaining = budget.budgetAmount - spent;

      // Simple alert logic (customize as needed)
      final alert = {
        'isOverBudget': spent > budget.budgetAmount,
        'isCloseToLimit': percentage > 80,
      };

      return BudgetStatus(
        id: budget.id,
        name: budget.name,
        budgetAmount: budget.budgetAmount,
        budgetType: budget.budgetType,
        spent: spent,
        percentage: percentage,
        alert: alert,
        remaining: remaining,
        periodStart: firstDayOfMonth,
        periodEnd: lastDayOfMonth,
      );
    } catch (e) {
      print('Error getting budget status: $e');
      throw Exception('Database error: $e');
    }
  }
}

/*class Budget {
  final String id;
  final String userId;
  final String name;
  final double budgetAmount;
  final String budgetType;
  final DateTime updatedAt;
  final bool isActive;

  Budget({
    required this.id,
    required this.userId,
    required this.name,
    required this.budgetAmount,
    required this.budgetType,
    required this.updatedAt,
    required this.isActive,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    try {
      return Budget(
        id: json['id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        name: json['name'] ?? 'My Budget',
        budgetAmount: json['monthly_budget'] != null 
            ? double.parse(json['monthly_budget'].toString()) 
            : 0.0,
        budgetType: json['budget_type'] ?? 'monthly',
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at']) 
            : DateTime.now(),
        isActive: json['is_active'] ?? false,
      );
    } catch (e) {
      print('Error parsing Budget: $e');
      print('JSON: $json');
      rethrow;
    }
  }
}*/
class Budget {
  final String id;
  final String userId;
  final String name;
  final double budgetAmount;
  final String budgetType;
  final DateTime updatedAt;
  final bool isActive;

  Budget({
    required this.id,
    required this.userId,
    required this.name,
    required this.budgetAmount,
    required this.budgetType,
    required this.updatedAt,
    required this.isActive,
  });

  Map<String, dynamic> toMap() {
    return {
      DatabaseHelperExpense.budgetId: id,
      DatabaseHelperExpense.budgetUserId: userId,
      DatabaseHelperExpense.budgetAmount: budgetAmount,
      DatabaseHelperExpense.budgetType: budgetType,
      DatabaseHelperExpense.budgetName: name,
      DatabaseHelperExpense.budgetIsActive: isActive ? 1 : 0,
      DatabaseHelperExpense.budgetUpdatedAt: updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, dynamic> map) {
    return Budget(
      id: map[DatabaseHelperExpense.budgetId],
      userId: map[DatabaseHelperExpense.budgetUserId],
      name: map[DatabaseHelperExpense.budgetName] ?? '',
      budgetAmount: map[DatabaseHelperExpense.budgetAmount],
      budgetType: map[DatabaseHelperExpense.budgetType],
      updatedAt: DateTime.parse(map[DatabaseHelperExpense.budgetUpdatedAt]),
      isActive: map[DatabaseHelperExpense.budgetIsActive] == 1,
    );
  }
}

/*class BudgetStatus {
  final double budgetAmount;
  final String budgetType;
  final double spent;
  final double percentage;
  final Map<String, dynamic> alert;
  final double remaining;
  final DateTime periodStart;
  final DateTime periodEnd;

  BudgetStatus({
    required this.budgetAmount,
    required this.budgetType,
    required this.spent,
    required this.percentage,
    required this.alert,
    required this.remaining,
    required this.periodStart,
    required this.periodEnd,
  });*/
/*class BudgetStatus {
  final String id;
  final String name;
  final double budgetAmount;
  final String budgetType;
  final double spent;
  final double percentage;
  final Map<String, dynamic> alert;
  final double remaining;
  final DateTime periodStart;
  final DateTime periodEnd;

  BudgetStatus({
    required this.id,
    required this.name,
    required this.budgetAmount,
    required this.budgetType,
    required this.spent,
    required this.percentage,
    required this.alert,
    required this.remaining,
    required this.periodStart,
    required this.periodEnd,
  });

  factory BudgetStatus.fromJson(Map<String, dynamic> json) {
    try {
      return BudgetStatus(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        budgetAmount: json['budget_amount'] != null 
            ? double.parse(json['budget_amount'].toString()) 
            : 0.0,
        budgetType: json['budget_type'] ?? 'monthly',
        spent: json['spent'] != null 
            ? double.parse(json['spent'].toString()) 
            : 0.0,
        percentage: json['percentage'] != null 
            ? double.parse(json['percentage'].toString()) 
            : 0.0,
        alert: json['alert'] ?? {},
        remaining: json['remaining'] != null 
            ? double.parse(json['remaining'].toString()) 
            : 0.0,
        periodStart: json['period_start'] != null 
            ? DateTime.parse(json['period_start']) 
            : DateTime.now(),
        periodEnd: json['period_end'] != null 
            ? DateTime.parse(json['period_end']) 
            : DateTime.now().add(Duration(days: 30)),
      );
    } catch (e) {
      print('Error parsing BudgetStatus: $e');
      print('JSON: $json');
      rethrow;
    }
  }*/
class BudgetStatus {
  final String id;
  final String name;
  final double budgetAmount;
  final String budgetType;
  final double spent;
  final double percentage;
  final Map<String, dynamic> alert;
  final double remaining;
  final DateTime periodStart;
  final DateTime periodEnd;

  BudgetStatus({
    required this.id,
    required this.name,
    required this.budgetAmount,
    required this.budgetType,
    required this.spent,
    required this.percentage,
    required this.alert,
    required this.remaining,
    required this.periodStart,
    required this.periodEnd,
  });

  factory BudgetStatus.fromMap(Map<String, dynamic> map) {
    return BudgetStatus(
      id: map['id'],
      name: map['name'],
      budgetAmount: map['budget_amount'],
      budgetType: map['budget_type'],
      spent: map['spent'],
      percentage: map['percentage'],
      alert: map['alert'] ?? {},
      remaining: map['remaining'],
      periodStart: DateTime.parse(map['period_start']),
      periodEnd: DateTime.parse(map['period_end']),
    );
  }

  String get periodLabel {
    switch (budgetType) {
      case 'daily':
        return 'Today\'s Budget';
      case 'weekly':
        return 'This Week\'s Budget';
      case 'monthly':
        return 'This Month\'s Budget';
      default:
        return 'Budget';
    }
  }

  Color get alertColor {
    switch (alert['level']) {
      case 'danger':
        return Colors.red;
      case 'warning':
        return Colors.orange;
      case 'caution':
        return Colors.amber;
      case 'info':
        return Colors.blue;
      case 'success':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

// Add these methods to your ExpenseService class

// Get budget status
/*static Future<BudgetStatus> getBudgetStatus(String userId) async {
  try {
    print('Fetching budget status for user: $userId');
    final response = await http.get(
      Uri.parse('$baseUrl/budgets/$userId'),
      headers: {"Content-Type": "application/json"},
    );

    _logResponse(response);

    if (response.statusCode == 200) {
      return BudgetStatus.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load budget status: ${response.statusCode} ${response.body}');
    }
  } catch (e) {
    print('Error fetching budget status: $e');
    throw Exception('Network error: $e');
  }
}

// Set budget
static Future<bool> setBudget(String userId, double budgetAmount, String budgetType) async {
  try {
    print('Setting budget: $userId, $budgetAmount, $budgetType');
    final response = await http.post(
      Uri.parse('$baseUrl/budgets'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": userId,
        "budget_amount": budgetAmount,
        "budget_type": budgetType,
      }),
    );

    _logResponse(response);

    return response.statusCode == 200 || response.statusCode == 201;
  } catch (e) {
    print('Error setting budget: $e');
    throw Exception('Network error: $e');
  }
}*/

class DashboardScreen extends StatefulWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  BudgetStatus? budgetStatus;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    loadBudgetStatus();
  }

  /*Future<void> loadBudgetStatus() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final status = await ExpenseService.getBudgetStatus(widget.userId);
      setState(() {
        budgetStatus = status;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }*/
  Future<void> loadBudgetStatus() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final status = await ExpenseService.getBudgetStatus(widget.userId);
      if (mounted) {
        // Check if widget is still in the tree
        setState(() {
          budgetStatus = status;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Check if widget is still in the tree
        setState(() {
          isLoading = false;
          hasError = true;
          errorMessage = e.toString();
        });

        // Only show snackbar if context is mounted
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void navigateToExpenseList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExpenseListScreen(userId: widget.userId),
      ),
    ).then((_) => loadBudgetStatus()); // Refresh data when returning
  }

  void navigateToSetBudget(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetBudgetScreen(
          userId: widget.userId,
          currentBudget: budgetStatus?.budgetAmount,
          currentBudgetType: budgetStatus?.budgetType ?? 'monthly',
        ),
      ),
    ).then((_) => loadBudgetStatus()); // Refresh data when returning
  }

  void navigateToAddExpense(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseScreen(userId: widget.userId),
      ),
    ).then((_) => loadBudgetStatus()); // Refresh data when returning
  }

  // Add this method
  void navigateToBudgetList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetListScreen(userId: widget.userId),
      ),
    ).then((_) => loadBudgetStatus()); // Refresh data when returning
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.expenseWallpaper;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Budget Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () => navigateToBudgetList(context),
            tooltip: 'My Budgets',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => navigateToSetBudget(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Image.asset(
            wallpaperAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          RefreshIndicator(
            onRefresh: () => loadBudgetStatus(),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text('Failed to load budget information'),
                            TextButton(
                              onPressed: () => navigateToSetBudget(context),
                              child: const Text('Set Up Budget'),
                            ),
                          ],
                        ),
                      )
                    : _buildDashboard(context),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6.0,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {}, // Already on dashboard
            ),
            IconButton(
              icon: const Icon(Icons.list),
              onPressed: () => navigateToExpenseList(context),
            ),
            const SizedBox(width: 48), // Space for FAB
            IconButton(
              icon: const Icon(Icons.pie_chart),
              onPressed: () {
                // Navigate to analytics screen (could be added later)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Analytics coming soon!')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => navigateToSetBudget(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToAddExpense(context),
        tooltip: 'Add Expense',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  /*Widget _buildDashboard(BuildContext context) {
    if (budgetStatus == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No budget set'),
            ElevatedButton(
              onPressed: () => navigateToSetBudget(context),
              child: const Text('Set Budget'),
            ),
          ],
        ),
      );
    }

    final formatter = NumberFormat.currency(symbol: '\$');
    final percentValue = budgetStatus!.percentage / 100;
    final cappedPercentValue = percentValue > 1.0 ? 1.0 : percentValue;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          budgetStatus!.periodLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          formatter.format(budgetStatus!.budgetAmount),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: CircularPercentIndicator(
                        radius: 80.0,
                        lineWidth: 12.0,
                        percent: cappedPercentValue,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${budgetStatus!.percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text('Used',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        progressColor: budgetStatus!.alertColor,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LinearPercentIndicator(
                      percent: cappedPercentValue,
                      lineHeight: 20,
                      progressColor: budgetStatus!.alertColor,
                      backgroundColor: Colors.grey.shade200,
                      barRadius: const Radius.circular(10),
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Spent',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              formatter.format(budgetStatus!.spent),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Remaining',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              formatter.format(budgetStatus!.remaining),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: budgetStatus!.remaining < 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (budgetStatus!.alert['message'] != null)
              Card(
                elevation: 4,
                color: budgetStatus!.alertColor.withOpacity(0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        budgetStatus!.alert['level'] == 'danger' ||
                                budgetStatus!.alert['level'] == 'warning'
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline,
                        color: budgetStatus!.alertColor,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          budgetStatus!.alert['message'],
                          style: TextStyle(
                            fontSize: 16,
                            color: budgetStatus!.alertColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => navigateToAddExpense(context),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Add Expense'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => navigateToExpenseList(context),
                    icon: const Icon(Icons.list_alt),
                    label: const Text('View Expenses'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Expenses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // This would ideally show the last 3-5 expenses
            // You'll need to modify your service to fetch limited expenses
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Tap "View Expenses" to see your expense history',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }*/
  // Add this method to your _DashboardScreenState class
  Map<String, dynamic> _getBudgetAlert(double percentage) {
    IconData alertIcon;
    String alertMessage;
    Color alertColor;
    String alertLevel;

    // Define alert types based on percentage thresholds
    if (percentage >= 100) {
      alertIcon = Icons.dangerous;
      alertMessage = "Budget exceeded! Time to tighten those purse strings! 💸";
      alertColor = Colors.red;
      alertLevel = 'danger';
    } else if (percentage >= 90) {
      alertIcon = Icons.warning_rounded;
      alertMessage =
          "Almost there! Just 10% of your budget left. Choose wisely! 🧐";
      alertColor = Colors.deepOrange;
      alertLevel = 'warning';
    } else if (percentage >= 75) {
      alertIcon = Icons.trending_up;
      alertMessage =
          "You've spent 75% of your budget. Starting to feel the heat! 🔥";
      alertColor = Colors.orange;
      alertLevel = 'caution';
    } else if (percentage >= 50) {
      alertIcon = Icons.equalizer;
      alertMessage =
          "Halfway through your budget! Maintaining balance is key. ⚖️";
      alertColor = Colors.amber;
      alertLevel = 'moderate';
    } else if (percentage >= 25) {
      alertIcon = Icons.thumb_up;
      alertMessage = "25% spent! Your budget journey has begun. 🌱";
      alertColor = Colors.green;
      alertLevel = 'good';
    } else {
      alertIcon = Icons.check_circle;
      alertMessage = "Budget looking good! Spending minimal so far. 👍";
      alertColor = Colors.green;
      alertLevel = 'good';
    }

    return {
      'icon': alertIcon,
      'message': alertMessage,
      'color': alertColor,
      'level': alertLevel,
    };
  }

// The enhanced budget alert widget
  Widget _buildEnhancedBudgetAlert(BuildContext context, double percentage,
      Color alertColor, String alertLevel, String alertMessage) {
    IconData alertIcon;

    // Determine icon based on alert level
    switch (alertLevel) {
      case 'danger':
        alertIcon = Icons.dangerous;
        break;
      case 'warning':
        alertIcon = Icons.warning_rounded;
        break;
      case 'caution':
        alertIcon = Icons.trending_up;
        break;
      case 'moderate':
        alertIcon = Icons.equalizer;
        break;
      case 'good':
        alertIcon = Icons.thumb_up;
        break;
      default:
        alertIcon = Icons.check_circle;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: alertColor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: alertColor.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(alertIcon, color: alertColor, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alertLevel == 'danger'
                            ? 'BUDGET ALERT'
                            : alertLevel == 'warning'
                                ? 'BUDGET WARNING'
                                : alertLevel == 'caution'
                                    ? 'BUDGET NOTICE'
                                    : 'BUDGET UPDATE',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alertMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (alertLevel == 'danger' || alertLevel == 'warning')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.lightbulb_outline),
                        label: const Text('Budget Tips',
                            style: TextStyle(color: Colors.white)),
                        onPressed: () {
                          // Show budget tips
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Budget Saving Tips'),
                              content: const SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                        '• Try to prioritize essential expenses'),
                                    Text(
                                        '• Look for areas where you can cut back'),
                                    Text(
                                        '• Consider postponing non-essential purchases'),
                                    Text(
                                        '• Review your recurring subscriptions'),
                                    Text(
                                        '• Look for free alternatives to paid services'),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: alertColor),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

// Modified _buildDashboard method to integrate enhanced alerts
  Widget _buildDashboard(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;
    if (budgetStatus == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No budget set'),
            ElevatedButton(
              onPressed: () => navigateToSetBudget(context),
              child: const Text('Set Budget'),
            ),
          ],
        ),
      );
    }

    // Use Indian Rupee symbol and format for Indian locale
    final formatter = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits:
          0, // Typically currency amounts don't show decimals in India
    );

    final percentValue = budgetStatus!.percentage / 100;
    final cappedPercentValue = percentValue > 1.0 ? 1.0 : percentValue;

    // Get the alert information based on percentage
    final alertInfo = _getBudgetAlert(budgetStatus!.percentage);
    final alertColor = alertInfo['color'] as Color;
    final alertLevel = alertInfo['level'] as String;
    final alertMessage = alertInfo['message'] as String;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1), // Semi-transparent background
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                color: Colors.black.withOpacity(0.5), // Semi-transparent card
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            budgetStatus!.periodLabel,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            formatter.format(budgetStatus!.budgetAmount),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: CircularPercentIndicator(
                          radius: 80.0,
                          lineWidth: 12.0,
                          percent: cappedPercentValue,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${budgetStatus!.percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                              Text('Used',
                                  style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                          progressColor: alertColor,
                          backgroundColor:
                              Colors.grey.shade200.withOpacity(0.5),
                          animation: true,
                          animationDuration: 1000,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LinearPercentIndicator(
                        percent: cappedPercentValue,
                        lineHeight: 20,
                        progressColor: alertColor,
                        backgroundColor: Colors.grey.shade200.withOpacity(0.5),
                        barRadius: const Radius.circular(10),
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        animation: true,
                        animationDuration: 1000,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Spent',
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                formatter.format(budgetStatus!.spent),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Remaining',
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text(
                                formatter.format(budgetStatus!.remaining),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: budgetStatus!.remaining < 0
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              /*Widget _buildDashboard(BuildContext context) {
    if (budgetStatus == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No budget set'),
            ElevatedButton(
              onPressed: () => navigateToSetBudget(context),
              child: const Text('Set Budget'),
            ),
          ],
        ),
      );
    }

    final formatter = NumberFormat.currency(symbol: '\$');
    final percentValue = budgetStatus!.percentage / 100;
    final cappedPercentValue = percentValue > 1.0 ? 1.0 : percentValue;

    // Get the alert information based on percentage
    final alertInfo = _getBudgetAlert(budgetStatus!.percentage);
    final alertColor = alertInfo['color'] as Color;
    final alertLevel = alertInfo['level'] as String;
    final alertMessage = alertInfo['message'] as String;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          budgetStatus!.periodLabel,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          formatter.format(budgetStatus!.budgetAmount),
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: CircularPercentIndicator(
                        radius: 80.0,
                        lineWidth: 12.0,
                        percent: cappedPercentValue,
                        center: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${budgetStatus!.percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text('Used',
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        progressColor:
                            alertColor, // Use the dynamic color from alertInfo
                        backgroundColor: Colors.grey.shade200,
                        animation: true,
                        animationDuration: 1000,
                      ),
                    ),
                    const SizedBox(height: 24),
                    LinearPercentIndicator(
                      percent: cappedPercentValue,
                      lineHeight: 20,
                      progressColor:
                          alertColor, // Use the dynamic color from alertInfo
                      backgroundColor: Colors.grey.shade200,
                      barRadius: const Radius.circular(10),
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      animation: true,
                      animationDuration: 1000,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Spent',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              formatter.format(budgetStatus!.spent),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Remaining',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              formatter.format(budgetStatus!.remaining),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: budgetStatus!.remaining < 0
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),*/
              const SizedBox(height: 16),

              // Enhanced budget alert - this replaces the simple alert card
              _buildEnhancedBudgetAlert(context, budgetStatus!.percentage,
                  alertColor, alertLevel, alertMessage),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => navigateToAddExpense(context),
                      icon: const Icon(Icons.add_circle_outline),
                      label: const Text('Add Expense'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => navigateToExpenseList(context),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('View Expenses'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // This would ideally show the last 3-5 expenses
              // You'll need to modify your service to fetch limited expenses
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Tap "View Expenses" to see your expense history',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*class SetBudgetScreen extends StatefulWidget {
  final String userId;
  final double? currentBudget;
  final String currentBudgetType;

  const SetBudgetScreen({
    super.key,
    required this.userId,
    this.currentBudget,
    required this.currentBudgetType,
  });

  @override
  _SetBudgetScreenState createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  String _selectedBudgetType = 'monthly';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentBudget != null) {
      _budgetController.text = widget.currentBudget!.toString();
    }
    _selectedBudgetType = widget.currentBudgetType;
  }

  Future<void> saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      double budgetAmount = double.parse(_budgetController.text);

      bool success = await ExpenseService.setBudget(
        widget.userId,
        budgetAmount,
        _selectedBudgetType,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget saved successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save budget')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String getBudgetTypeDescription(String type) {
    switch (type) {
      case 'daily':
        return 'Reset budget tracking at the start of each day';
      case 'weekly':
        return 'Reset budget tracking at the start of each week (Sunday)';
      case 'monthly':
        return 'Reset budget tracking at the start of each month';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set Budget")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set your spending limit",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _budgetController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "Budget Amount",
                  prefixIcon: Icon(Icons.attach_money),
                  hintText: "Enter your budget amount",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a budget amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Budget amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              const Text(
                "Budget Period",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildBudgetTypeOption('daily', 'Daily', Icons.today),
              _buildBudgetTypeOption('weekly', 'Weekly', Icons.view_week),
              _buildBudgetTypeOption(
                  'monthly', 'Monthly', Icons.calendar_month),
              const SizedBox(height: 8),
              Text(
                getBudgetTypeDescription(_selectedBudgetType),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : saveBudget,
                  child: _isSubmitting
                      ? const CircularProgressIndicator()
                      : const Text("Save Budget",
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBudgetTypeOption(String value, String label, IconData icon) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBudgetType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedBudgetType == value
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _selectedBudgetType == value
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _selectedBudgetType == value
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: _selectedBudgetType == value
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _selectedBudgetType == value
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            const Spacer(),
            if (_selectedBudgetType == value)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }
}*/
class SetBudgetScreen extends StatefulWidget {
  final String userId;
  final bool isNewBudget;
  final String? budgetId;
  final double? currentBudget;
  final String? budgetName;
  final String currentBudgetType;

  const SetBudgetScreen({
    super.key,
    required this.userId,
    this.isNewBudget = true,
    this.budgetId,
    this.currentBudget,
    this.budgetName,
    this.currentBudgetType = 'monthly',
  });

  @override
  _SetBudgetScreenState createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends State<SetBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _budgetController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedBudgetType = 'monthly';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentBudget != null) {
      _budgetController.text = widget.currentBudget!.toString();
    }
    if (widget.budgetName != null) {
      _nameController.text = widget.budgetName!;
    } else {
      _nameController.text = 'My Budget';
    }
    _selectedBudgetType = widget.currentBudgetType;
  }

  /*Future<void> saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      double budgetAmount = double.parse(_budgetController.text);
      String budgetName = _nameController.text;

      Budget? budget;

      if (widget.isNewBudget) {
        // Create new budget
        budget = await ExpenseService.createBudget(
          widget.userId,
          budgetAmount,
          _selectedBudgetType,
          budgetName,
        );
        if (budget != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget created successfully')),
          );
        }
      } else {
        // Update existing budget
        budget = await ExpenseService.updateBudget(
          widget.budgetId!,
          widget.userId,
          budgetAmount,
          _selectedBudgetType,
          budgetName,
        );
        if (budget != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Budget updated successfully')),
          );
        }
      }

      if (budget != null) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save budget')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }*/
  Future<void> saveBudget(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      double budgetAmount = double.parse(_budgetController.text);
      String budgetName = _nameController.text;

      Budget budget;

      if (widget.isNewBudget) {
        budget = await ExpenseService.createBudget(
          widget.userId,
          budgetAmount,
          _selectedBudgetType,
          budgetName,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget created successfully')),
        );
      } else {
        budget = await ExpenseService.updateBudget(
          widget.budgetId!,
          widget.userId,
          budgetAmount,
          _selectedBudgetType,
          budgetName,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget updated successfully')),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  String getBudgetTypeDescription(String type) {
    switch (type) {
      case 'daily':
        return 'Reset budget tracking at the start of each day';
      case 'weekly':
        return 'Reset budget tracking at the start of each week (Sunday)';
      case 'monthly':
        return 'Reset budget tracking at the start of each month';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.addbudgetWallpaper;
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.isNewBudget ? "Create Budget" : "Edit Budget")),
      body: Stack(
        children: [
          // Background image
          Image.asset(
            wallpaperAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Name your budget",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Budget Name",
                      prefixIcon: Icon(Icons.label),
                      hintText: "e.g., Monthly Expenses, Vacation Fund",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a name for this budget';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Set your spending limit",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _budgetController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Budget Amount",
                      prefixIcon: Icon(Icons.currency_rupee),
                      hintText: "Enter your budget amount",
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a budget amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Budget amount must be greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Budget Period",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBudgetTypeOption(
                      'daily', 'Daily', Icons.today, context),
                  _buildBudgetTypeOption(
                      'weekly', 'Weekly', Icons.view_week, context),
                  _buildBudgetTypeOption(
                      'monthly', 'Monthly', Icons.calendar_month, context),
                  const SizedBox(height: 8),
                  Text(
                    getBudgetTypeDescription(_selectedBudgetType),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () =>
                          _isSubmitting ? null : saveBudget(context),
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : Text(
                              widget.isNewBudget
                                  ? "Create Budget"
                                  : "Update Budget",
                              style: const TextStyle(fontSize: 16)),
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

  Widget _buildBudgetTypeOption(
      String value, String label, IconData icon, BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBudgetType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedBudgetType == value
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _selectedBudgetType == value
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: _selectedBudgetType == value
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: _selectedBudgetType == value
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: _selectedBudgetType == value
                    ? Theme.of(context).primaryColor
                    : null,
              ),
            ),
            const Spacer(),
            if (_selectedBudgetType == value)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

class BudgetListScreen extends StatefulWidget {
  final String userId;

  const BudgetListScreen({super.key, required this.userId});

  @override
  _BudgetListScreenState createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends State<BudgetListScreen> {
  List<Budget> budgets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  /*Future<void> loadBudgets() async {
    setState(() {
      isLoading = true;
    });

    try {
      final budgetList = await ExpenseService.getUserBudgets(widget.userId);
      setState(() {
        budgets = budgetList;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budgets: $e')),
      );
    }
  }

  Future<void> activateBudget(String budgetId) async {
    try {
      await ExpenseService.activateBudget(budgetId, widget.userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget activated successfully')),
      );
      // Refresh the list to show updated active status
      loadBudgets();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error activating budget: $e')),
      );
    }
  }*/
  Future<void> _loadBudgets() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final budgetList = await ExpenseService.getUserBudgets(widget.userId);
      if (!mounted) return;

      setState(() {
        budgets = budgetList;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error loading budgets: $e')),
      );
    }
  }

  Future<void> loadBudgets(BuildContext context) async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final budgetList = await ExpenseService.getUserBudgets(widget.userId);
      if (!mounted) return;

      setState(() {
        budgets = budgetList;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budgets: $e')),
      );
    }
  }

  Future<void> _activateBudget(String budgetId, BuildContext context) async {
    try {
      await ExpenseService.activateBudget(budgetId, widget.userId);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget activated successfully')),
      );
      await loadBudgets(context); // Refresh the list
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error activating budget: $e')),
      );
    }
  }

  Future<void> _deleteBudget(String budgetId, BuildContext context) async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text(
            'Are you sure you want to delete this budget? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    // If user cancels, do nothing
    if (shouldDelete != true) return;

    try {
      final success = await ExpenseService.deleteBudget(budgetId);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget deleted successfully')),
        );
        await loadBudgets(context); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete budget')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting budget: $e')),
      );
    }
  }

  Future<void> _navigateToAddBudget(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetBudgetScreen(
          userId: widget.userId,
          isNewBudget: true,
        ),
      ),
    );

    if (result == true && mounted) {
      await loadBudgets(context);
    }
  }

  Future<void> _navigateToEditBudget(
      Budget budget, BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetBudgetScreen(
          userId: widget.userId,
          isNewBudget: false,
          budgetId: budget.id,
          currentBudget: budget.budgetAmount,
          currentBudgetType: budget.budgetType,
          budgetName: budget.name,
        ),
      ),
    );

    if (result == true && mounted) {
      await loadBudgets(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.addexpenseWallpaper;
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Budgets'),
      ),
      body: Stack(
        children: [
          // 🌄 Background Image
          Image.asset(
            wallpaperAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : budgets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('You don\'t have any budgets yet'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _navigateToAddBudget(context),
                            child: const Text('Create Budget'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: budgets.length,
                      itemBuilder: (context, index) {
                        final budget = budgets[index];
                        return Opacity(
                          opacity: 0.9, // Reduced opacity (0.9 = 90% opaque)
                          child: Card(
                            margin: const EdgeInsets.all(8.0),
                            color: const Color.fromARGB(255, 13, 2, 2)
                                .withOpacity(0.8), // Semi-transparent card
                            elevation: 2,
                            child: ListTile(
                              title: Text(budget.name),
                              subtitle: Text(
                                '${budget.budgetAmount.toStringAsFixed(2)} (${budget.budgetType})',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  budget.isActive
                                      ? const Chip(
                                          label: Text('Active'),
                                          backgroundColor: Colors.green,
                                          labelStyle:
                                              TextStyle(color: Colors.white),
                                        )
                                      : TextButton(
                                          onPressed: () => _activateBudget(
                                              budget.id, context),
                                          child: const Text(
                                            'Activate',
                                            style: TextStyle(
                                              color:
                                                  Colors.amber, // Golden color
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _navigateToEditBudget(budget, context),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteBudget(budget.id, context),
                                  ),
                                ],
                              ),
                              onTap: () {
                                if (!budget.isActive) {
                                  _activateBudget(budget.id, context);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            _navigateToAddBudget(context),
        tooltip: 'Add Budget', // Pass a function reference
        child: const Icon(Icons.add),
      ),
    );
  }
}

/*class Expense {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String description;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.createdAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['user_id'],
      amount: double.parse(json['amount'].toString()),
      category: json['category'],
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}*/
class Expense {
  final String id;
  final String userId;
  final double amount;
  final String category;
  final String description;
  final DateTime createdAt;

  Expense({
    required this.id,
    required this.userId,
    required this.amount,
    required this.category,
    required this.description,
    required this.createdAt,
  });

  // Convert an Expense into a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'category': category,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'],
      userId: map['user_id'],
      amount: map['amount'],
      category: map['category'],
      description: map['description'] ?? '',
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

class ExpenseListScreen extends StatefulWidget {
  final String userId;
  const ExpenseListScreen({super.key, required this.userId});

  @override
  _ExpenseListScreenState createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<Expense> expenses = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExpenses();
  }

  /*Future<void> fetchExpenses() async {
    try {
      List<Expense> fetchedExpenses =
          await ExpenseService.getExpenses(widget.userId);
      setState(() {
        expenses = fetchedExpenses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching expenses: ${e.toString()}')),
      );
    }
  }

  void deleteExpense(String id) async {
    try {
      bool success = await ExpenseService.deleteExpense(id);
      if (success) {
        setState(() {
          expenses.removeWhere((expense) => expense.id == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense deleted successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting expense: ${e.toString()}')),
      );
    }
  }*/
  Future<void> fetchExpenses() async {
    try {
      List<Expense> fetchedExpenses =
          await ExpenseService.getExpenses(widget.userId);
      setState(() {
        expenses = fetchedExpenses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchExpenses(BuildContext context) async {
    try {
      List<Expense> fetchedExpenses =
          await ExpenseService.getExpenses(widget.userId);
      setState(() {
        expenses = fetchedExpenses;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void deleteExpense(String id, BuildContext context) async {
    try {
      await ExpenseService.deleteExpense(id);
      setState(() {
        expenses.removeWhere((expense) => expense.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void navigateToAddExpense(BuildContext context) async {
    bool? result = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AddExpenseScreen(userId: widget.userId)),
    );

    if (result == true) {
      _fetchExpenses(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.notesWallpaper;
    return Scaffold(
      body: Stack(
        children: [
          // 🌄 Background Image
          Image.asset(
            wallpaperAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Main Content
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : expenses.isEmpty
                  ? const Center(
                      child: Text(
                        "No expenses found. Add some!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 3.0,
                              color: Colors.black54,
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        Expense expense = expenses[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            title: Text(
                              "\$${expense.amount.toStringAsFixed(2)} - ${expense.category}",
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${expense.description}\n${DateFormat('MMM dd, yyyy').format(expense.createdAt)}",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  deleteExpense(expense.id, context),
                            ),
                          ),
                        );
                      },
                    ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => navigateToAddExpense(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ADD EXPENSE SCREEN
class AddExpenseScreen extends StatefulWidget {
  final String userId;
  const AddExpenseScreen({super.key, required this.userId});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = "Food";
  bool _isSubmitting = false;

  final List<String> categories = [
    "Food",
    "Transport",
    "Bills",
    "Shopping",
    "Entertainment"
  ];

  /*void saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      double amount = double.parse(_amountController.text);

      bool success = await ExpenseService.addExpense(
        widget.userId,
        amount,
        _selectedCategory,
        _descriptionController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save expense')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }*/
  void saveExpense(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isSubmitting = true;
      });

      double amount = double.parse(_amountController.text);

      await ExpenseService.addExpense(
        widget.userId,
        amount,
        _selectedCategory,
        _descriptionController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense saved successfully')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.addexpenseWallpaper;
    return Scaffold(
      appBar: AppBar(title: const Text("Add Expense")),
      body: Stack(
        children: [
          // 🌄 Background Image
          Image.asset(
            wallpaperAsset,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField(
                    value: _selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem(
                          value: category, child: Text(category));
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value as String;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: "Category",
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: "Description",
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () =>
                          _isSubmitting ? null : saveExpense(context),
                      child: _isSubmitting
                          ? const CircularProgressIndicator()
                          : const Text("Save Expense",
                              style: TextStyle(fontSize: 16)),
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

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

//currently working
/*class ExpenseService {
  // Base URL
  static const String baseUrl = "http://192.168.0.114:5000";

  // For debugging purposes
  static void _logResponse(http.Response response) {
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
  }

  static Future<List<Budget>> getUserBudgets(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/budgets/list/$userId'));
    _logResponse(response); // Add logging to help debug

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Budget.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load budgets: ${response.body}');
    }
  }

  static Future<Budget> createBudget(
    String userId,
    double amount,
    String budgetType,
    String name,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/budgets'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'budget_amount': amount,
        'budget_type': budgetType,
        'name': name,
      }),
    );
    _logResponse(response); // Add logging to help debug

    if (response.statusCode == 200) {
      return Budget.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create budget: ${response.body}');
    }
  }

  // Update an existing budget
  static Future<Budget> updateBudget(
    String budgetId,
    String userId,
    double amount,
    String budgetType,
    String name,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/budgets/$budgetId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'budget_amount': amount,
        'budget_type': budgetType,
        'name': name,
      }),
    );

    if (response.statusCode == 200) {
      return Budget.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update budget');
    }
  }

  // Activate a specific budget
  static Future<void> activateBudget(String budgetId, String userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/budgets/$budgetId/activate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to activate budget');
    }
  }

  // Fetch expenses
  static Future<List<Expense>> getExpenses(String userId) async {
    try {
      print('Fetching expenses for user: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/expenses/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Expense.fromJson(json)).toList();
      } else {
        throw Exception(
            'Failed to load expenses: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching expenses: $e');
      throw Exception('Network error: $e');
    }
  }

  // Add an expense
  static Future<bool> addExpense(
      String userId, double amount, String category, String description) async {
    try {
      print('Adding expense: $userId, $amount, $category, $description');
      final response = await http.post(
        Uri.parse('$baseUrl/expenses'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "amount": amount,
          "category": category,
          "description": description,
        }),
      );

      _logResponse(response);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding expense: $e');
      throw Exception('Network error: $e');
    }
  }

  // Delete an expense
  static Future<bool> deleteExpense(String id) async {
    try {
      print('Deleting expense: $id');
      final response = await http.delete(
        Uri.parse('$baseUrl/expenses/$id'),
        headers: {"Content-Type": "application/json"},
      );

      _logResponse(response);

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting expense: $e');
      throw Exception('Network error: $e');
    }
  }

  // Get budget status
  static Future<BudgetStatus> getBudgetStatus(String userId) async {
    try {
      print('Fetching budget status for user: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/budgets/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      _logResponse(response);

      if (response.statusCode == 200) {
        return BudgetStatus.fromJson(jsonDecode(response.body));
      } else {
        throw Exception(
            'Failed to load budget status: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching budget status: $e');
      throw Exception('Network error: $e');
    }
  }

  // Set budget
  static Future<bool> setBudget(
      String userId, double budgetAmount, String budgetType) async {
    try {
      print('Setting budget: $userId, $budgetAmount, $budgetType');
      final response = await http.post(
        Uri.parse('$baseUrl/budgets'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": userId,
          "budget_amount": budgetAmount,
          "budget_type": budgetType,
        }),
      );

      _logResponse(response);

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error setting budget: $e');
      throw Exception('Network error: $e');
    }
  }
}*/
