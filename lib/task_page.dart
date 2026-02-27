import 'package:flutter/material.dart';
import 'main.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class TaskPage extends StatefulWidget {
  final String userId; // Add userId parameter

  const TaskPage({super.key, required this.userId});

  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> allTasks = [];
  List<Map<String, dynamic>> todaysTasks = [];
  List<Map<String, dynamic>> inProgressTasks = [];
  List<Map<String, dynamic>> completedTasks = [];
  List<Map<String, dynamic>> upcomingTasks = [];

  final TextEditingController taskController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController dueDateController = TextEditingController();
  final TextEditingController timeController = TextEditingController();
  String reminderOption = "On Due Date";
  TimeOfDay? selectedTime;
  DateTime? selectedDate;
  late TabController _tabController;

  final List<String> reminderOptions = [
    "On Due Date",
    "1 Day Before",
    "2 Days Before",
    "3 Days Before"
  ];

  @override
  void initState() {
    super.initState();
    // Initialize TabController with length 4 for the 4 tabs
    _tabController = TabController(length: 4, vsync: this);
    fetchTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Organize tasks into categories
  void _categorizeTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    todaysTasks = [];
    inProgressTasks = [];
    completedTasks = [];
    upcomingTasks = [];

    for (var task in allTasks) {
      // Add to completed tasks if completed
      if (task["isCompleted"] == true) {
        completedTasks.add(task);
        continue;
      }

      // Check if task has a due date
      if (task["due_date"] != null && task["due_date"].isNotEmpty) {
        try {
          final dueDate = DateTime.parse(task["due_date"]);
          final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

          // Add to today's tasks
          if (taskDate.isAtSameMomentAs(today)) {
            todaysTasks.add(task);
          }
          // Add to upcoming tasks if due date is in the future
          else if (taskDate.isAfter(today)) {
            upcomingTasks.add(task);
          }
        } catch (e) {
          // If date parsing fails, add to in-progress
          print("Error parsing date: $e");
        }
      }

      // Add to in-progress tasks if not completed
      if (task["isCompleted"] == false) {
        inProgressTasks.add(task);
      }
    }

    // Sort tasks by due date
    todaysTasks.sort((a, b) => _compareDueDates(a, b));
    inProgressTasks.sort((a, b) => _compareDueDates(a, b));
    upcomingTasks.sort((a, b) => _compareDueDates(a, b));
  }

  // Helper function to compare due dates for sorting
  int _compareDueDates(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a["due_date"] == null || a["due_date"].isEmpty) return 1;
    if (b["due_date"] == null || b["due_date"].isEmpty) return -1;

    try {
      final dateA = DateTime.parse(a["due_date"]);
      final dateB = DateTime.parse(b["due_date"]);
      return dateA.compareTo(dateB);
    } catch (e) {
      return 0;
    }
  }

  /*Future<void> fetchTasks() async {
    try {
      final fetchedTasks = await TaskService.fetchTasks(widget.userId);
      setState(() {
        allTasks = fetchedTasks;
        _categorizeTasks();
      });
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }*/
  Future<void> fetchTasks() async {
    try {
      final fetchedTasks = await TaskService.fetchTasks(widget.userId);
      setState(() {
        allTasks = fetchedTasks;
        _categorizeTasks();
      });
    } catch (e) {
      print("Error fetching tasks: $e");
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
        dueDateController.text =
            "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime != null && pickedTime != selectedTime) {
      setState(() {
        selectedTime = pickedTime;
        timeController.text =
            "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
      });
    }
  }

  /*Future<void> addTask() async {
    if (taskController.text.isNotEmpty) {
      final newTask = {
        "user_id": widget.userId,
        "title": taskController.text,
        "description": descriptionController.text,
        "due_date": dueDateController.text,
        "reminder_option": reminderOption,
        "reminder_time": timeController.text,
        "isCompleted": false,
      };
      try {
        await TaskService.addTask(newTask);
        taskController.clear();
        descriptionController.clear();
        dueDateController.clear();
        timeController.clear();
        setState(() {
          selectedDate = null;
          selectedTime = null;
        });
        fetchTasks();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Task added successfully!")));
      } catch (e) {
        print("Error adding task: $e");
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Failed to add task. Please try again.")));
      }
    }
  }

  Future<void> updateTask(Map<String, dynamic> task) async {
    final updatedTask = {
      "title": task["title"],
      "description": task["description"],
      "due_date": task["due_date"],
      "reminder_option": task["reminder_option"],
      "reminder_time": task["reminder_time"],
      "isCompleted": !task["isCompleted"]
    };
    try {
      await TaskService.updateTask(task["id"], updatedTask);
      fetchTasks();
    } catch (e) {
      print("Error updating task: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await TaskService.deleteTask(taskId);
      fetchTasks();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task deleted successfully!")));
    } catch (e) {
      print("Error deleting task: $e");
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to delete task. Please try again.")));
    }
  }*/
  Future<void> addTask() async {
    if (taskController.text.isNotEmpty) {
      final newTask = {
        "user_id": widget.userId,
        "title": taskController.text,
        "description": descriptionController.text,
        "due_date": dueDateController.text,
        "reminder_option": reminderOption,
        "reminder_time": timeController.text,
        "isCompleted": false,
      };
      try {
        await TaskService.addTask(newTask);
        taskController.clear();
        descriptionController.clear();
        dueDateController.clear();
        timeController.clear();
        setState(() {
          selectedDate = null;
          selectedTime = null;
        });
        fetchTasks();

        // Show success message
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            const SnackBar(content: Text("Task added successfully!")));
      } catch (e) {
        print("Error adding task: $e");
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
            const SnackBar(
                content: Text("Failed to add task. Please try again.")));
      }
    }
  }

  Future<void> updateTask(Map<String, dynamic> task) async {
    final updatedTask = {
      "title": task["title"],
      "description": task["description"],
      "due_date": task["due_date"],
      "reminder_option": task["reminder_option"],
      "reminder_time": task["reminder_time"],
      "isCompleted": !task["isCompleted"]
    };
    try {
      await TaskService.updateTask(task["id"], updatedTask);
      fetchTasks();
    } catch (e) {
      print("Error updating task: $e");
    }
  }

  Future<void> deleteTask(String taskId) async {
    try {
      await TaskService.deleteTask(taskId);
      fetchTasks();

      // Show success message
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(content: Text("Task deleted successfully!")));
    } catch (e) {
      print("Error deleting task: $e");
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(const SnackBar(
          content: Text("Failed to delete task. Please try again.")));
    }
  }

  Widget _buildTaskForm(
    BuildContext context,
  ) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.homeWallpaper;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(wallpaperAsset),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add New Task",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: taskController,
            decoration: const InputDecoration(
              hintText: "Enter task title...",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.task),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              hintText: "Enter task description...",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(this.context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: dueDateController,
                      decoration: const InputDecoration(
                        hintText: "Due date...",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(this.context),
                  child: AbsorbPointer(
                    child: TextField(
                      controller: timeController,
                      decoration: const InputDecoration(
                        hintText: "Time...",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.access_time),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: reminderOption,
            onChanged: (newValue) {
              setState(() {
                reminderOption = newValue!;
              });
            },
            items: reminderOptions.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(option),
              );
            }).toList(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Set Reminder",
              prefixIcon: Icon(Icons.notifications),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: addTask,
            icon: const Icon(Icons.add),
            label: const Text("Add Task"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskListPreview(List<Map<String, dynamic>> taskList,
      String title, String emptyMessage, BuildContext context) {
    final displayedTasks = taskList.take(2).toList();
    final hasMore = taskList.length > 2;
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            "$title (${taskList.length})",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (taskList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              emptyMessage,
              style: const TextStyle(color: Colors.grey),
            ),
          )
        else
          Column(
            children: [
              ...displayedTasks.map((task) => _buildTaskItem(context, task)),
              if (hasMore)
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: Text(title)),
                          body: _buildFullTaskList(
                              context, taskList, emptyMessage),
                        ),
                      ),
                    );
                  },
                  child: Text('See More (${taskList.length - 2})'),
                ),
            ],
          ),
        const Divider(),
      ],
    );
  }

  /*Widget _buildTaskItem(BuildContext context, Map<String, dynamic> task) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          task["title"],
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: task["isCompleted"]
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(task["description"] ?? "No description",
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 4),
                Text(task["due_date"] ?? "No date"),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: task["isCompleted"],
              onChanged: (value) {
                updateTask(task);
              },
            ),
          ],
        ),
      ),
    );
  }*/
  Widget _buildTaskItem(BuildContext context, Map<String, dynamic> task) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          _showTaskDetails(context, task);
        },
        child: ListTile(
          title: Text(
            task["title"],
            style: TextStyle(
              fontWeight: FontWeight.bold,
              decoration: task["isCompleted"]
                  ? TextDecoration.lineThrough
                  : TextDecoration.none,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(task["description"] ?? "No description",
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 4),
                  Text(task["due_date"] ?? "No date"),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: task["isCompleted"],
                onChanged: (value) {
                  updateTask(task);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    final wallpaperAsset = themeNotifier.homeWallpaper;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(wallpaperAsset),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.9),
                    BlendMode.lighten,
                  ),
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          task["title"],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Checkbox(
                        value: task["isCompleted"],
                        onChanged: (value) {
                          Navigator.of(context).pop();
                          task["isCompleted"] = value;
                          updateTask(task);
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    "Description:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task["description"] ?? "No description provided",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Due Date: ${task["due_date"] ?? "Not set"}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Time: ${task["reminder_time"] ?? "Not set"}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.notifications, size: 20),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          "Reminder: ${task["reminder_option"] ?? "On Due Date"}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _editTask(context, task);
                        },
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit"),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Task"),
                              content: const Text(
                                  "Are you sure you want to delete this task?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteTask(task["id"]);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text("Delete",
                            style: TextStyle(color: Colors.red)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("Close"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Method stub for editing task - you'll need to implement this
  void _editTask(BuildContext context, Map<String, dynamic> task) {
    // Implement your edit logic here
    // You could pre-fill your form controllers and show the task form
    taskController.text = task["title"];
    descriptionController.text = task["description"] ?? "";
    dueDateController.text = task["due_date"] ?? "";
    timeController.text = task["reminder_time"] ?? "";
    reminderOption = task["reminder_option"] ?? reminderOptions[0];

    // You would need to adapt this to your navigation and state management approach
    // For example, you might want to show a bottom sheet or navigate to an edit page
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text("Edit Task"),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              _buildTaskForm(context),
              ElevatedButton.icon(
                onPressed: () {
                  // Update task instead of adding
                  task["title"] = taskController.text;
                  task["description"] = descriptionController.text;
                  task["due_date"] = dueDateController.text;
                  task["reminder_time"] = timeController.text;
                  task["reminder_option"] = reminderOption;

                  updateTask(task);
                  Navigator.pop(context);

                  // Clear form
                  taskController.clear();
                  descriptionController.clear();
                  dueDateController.clear();
                  timeController.clear();
                  reminderOption = reminderOptions[0];
                },
                icon: const Icon(Icons.save),
                label: const Text("Update Task"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullTaskList(BuildContext context,
      List<Map<String, dynamic>> taskList, String emptyMessage) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;
    return taskList.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.task_alt, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: taskList.length,
            itemBuilder: (context, index) {
              final task = taskList[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: InkWell(
                  onTap: () {
                    _showTaskDetails(context, task);
                  },
                  child: ListTile(
                    title: Text(
                      task["title"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: task["isCompleted"]
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(task["description"] ?? "No description"),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(task["due_date"] ?? "No date"),
                            const SizedBox(width: 16),
                            const Icon(Icons.access_time, size: 16),
                            const SizedBox(width: 4),
                            Text(task["reminder_time"] ?? "No time"),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                            "Reminder: ${task["reminder_option"] ?? "On Due Date"}"),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Checkbox(
                          value: task["isCompleted"],
                          onChanged: (value) {
                            updateTask(task);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Delete Task"),
                                content: const Text(
                                    "Are you sure you want to delete this task?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      deleteTask(task["id"]);
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Delete"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                ),
              );
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    // Get the current wallpaper from ThemeNotifier
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.tasksWallpaper;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tasks & Reminders"),
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

          // 🌫️ Semi-transparent overlay for readability (optional)
          Container(
            color: Colors.black.withOpacity(0.3), // adjust as needed
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Task lists previews
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Today's Tasks
                        _buildTaskListPreview(
                          todaysTasks,
                          "Today's Tasks",
                          "No tasks for today. Add a task with today's date to see it here.",
                          context,
                        ),

                        // In Progress Tasks
                        _buildTaskListPreview(
                          inProgressTasks,
                          "In Progress",
                          "No tasks in progress. All caught up!",
                          context,
                        ),

                        // Upcoming Tasks
                        _buildTaskListPreview(
                          upcomingTasks,
                          "Upcoming Tasks",
                          "No upcoming tasks. Add a task with a future due date to see it here.",
                          context,
                        ),

                        // Completed Tasks
                        _buildTaskListPreview(
                          completedTasks,
                          "Completed Tasks",
                          "No completed tasks yet. Start checking off tasks to see them here.",
                          context,
                        ),
                      ],
                    ),
                  ),
                ),

                // Task form at the bottom
                _buildTaskForm(context),
              ],
            ),
          ),
        ],
      ),
    );
  }
  /*Widget _buildTaskListPreview(List<Map<String, dynamic>> taskList,
    String title, String emptyMessage, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          "$title (${taskList.length})",
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      if (taskList.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            emptyMessage,
            style: const TextStyle(color: Colors.grey),
          ),
        )
      else
        Column(
          children: [
            SizedBox(
              height: 150, // Set a fixed height for the horizontal list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: taskList.length,
                itemBuilder: (context, index) {
                  final task = taskList[index];
                  return Container(
                    width: 280, // Set a fixed width for each task card
                    margin: const EdgeInsets.only(right: 12),
                    child: _buildHorizontalTaskItem(task),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            if (taskList.length > 3) // Show "See All" if there are many tasks
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: Text(title)),
                          body: _buildFullTaskList(taskList, emptyMessage),
                        ),
                      ),
                    );
                  },
                  child: Text('See All (${taskList.length})'),
                ),
              ),
          ],
        ),
      const Divider(),
    ],
  );
}

Widget _buildFullTaskList(
      List<Map<String, dynamic>> taskList, String emptyMessage) {
    return taskList.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.task_alt, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: taskList.length,
            itemBuilder: (context, index) {
              final task = taskList[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  title: Text(
                    task["title"],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: task["isCompleted"]
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(task["description"] ?? "No description"),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 4),
                          Text(task["due_date"] ?? "No date"),
                          const SizedBox(width: 16),
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 4),
                          Text(task["reminder_time"] ?? "No time"),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          "Reminder: ${task["reminder_option"] ?? "On Due Date"}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: task["isCompleted"],
                        onChanged: (value) {
                          updateTask(task);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Delete Task"),
                              content: const Text(
                                  "Are you sure you want to delete this task?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () {
                                    deleteTask(task["id"]);
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Delete"),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
  }

Widget _buildHorizontalTaskItem(Map<String, dynamic> task) {
  return Card(
    elevation: 3,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task["title"],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: task["isCompleted"]
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Checkbox(
                value: task["isCompleted"],
                onChanged: (value) {
                  // Call updateTask here
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            task["description"] ?? "No description",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14),
              const SizedBox(width: 4),
              Text(
                task["due_date"] ?? "No date",
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.access_time, size: 14),
              const SizedBox(width: 4),
              Text(
                task["reminder_time"] ?? "No time",
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

@override
Widget build(BuildContext context) {
  final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
  final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

  // Get the current wallpaper from ThemeNotifier
  final themeNotifier = Provider.of<ThemeNotifier>(context);
  final wallpaperAsset = themeNotifier.tasksWallpaper;
  return Scaffold(
    appBar: AppBar(
      title: const Text("Tasks & Reminders"),
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

        // 🌫️ Semi-transparent overlay for readability (optional)
        Container(
          color: Colors.black.withOpacity(0.3), // adjust as needed
        ),
        
        // Main content
        Column(
          children: [
            // Task lists previews - now in a scrollable area
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Today's Tasks
                  _buildTaskListPreview(
                    todaysTasks,
                    "Today's Tasks",
                    "No tasks for today. Add a task with today's date to see it here.",
                    context,
                  ),

                  // In Progress Tasks
                  _buildTaskListPreview(
                    inProgressTasks,
                    "In Progress",
                    "No tasks in progress. All caught up!",
                    context,
                  ),

                  // Upcoming Tasks
                  _buildTaskListPreview(
                    upcomingTasks,
                    "Upcoming Tasks",
                    "No upcoming tasks. Add a task with a future due date to see it here.",
                    context,
                  ),

                  // Completed Tasks
                  _buildTaskListPreview(
                    completedTasks,
                    "Completed Tasks",
                    "No completed tasks yet. Start checking off tasks to see them here.",
                    context,
                  ),
                ],
              ),
            ),

            // Task form at the bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildTaskForm(),
            ),
          ],
        ),
      ],
    ),
  );
}*/
}

/*class TaskService {
  static const String baseUrl = "http://192.168.0.114:5000/tasks";

  // ✅ Fetch Tasks
  static Future<List<Map<String, dynamic>>> fetchTasks(String userId) async {
    final response = await http.get(Uri.parse("$baseUrl/$userId"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((task) {
        // Ensure is_completed is properly converted to boolean
        bool isCompleted;
        if (task['is_completed'] is bool) {
          isCompleted = task['is_completed'];
        } else if (task['is_completed'] is String) {
          isCompleted = task['is_completed'].toLowerCase() == 'true';
        } else {
          isCompleted =
              task['is_completed'] == 1 || task['is_completed'] == true;
        }

        return {
          'id': task['id'],
          'title': task['title'],
          'description': task['description'] ?? '',
          'due_date': task['due_date']?.toString() ?? '',
          'reminder_option': task['reminder_option'] ?? 'On Due Date',
          'reminder_time': task['reminder_time']?.toString() ?? '',
          'isCompleted': isCompleted, // Now guaranteed to be boolean
        };
      }).toList();
    } else {
      throw Exception("Failed to fetch tasks: ${response.statusCode}");
    }
  }

  // ✅ Insert New Task
  static Future<void> addTask(Map<String, dynamic> taskData) async {
    // Convert isCompleted to is_completed for API consistency
    Map<String, dynamic> apiTaskData = {
      'user_id': taskData['user_id'],
      'title': taskData['title'],
      'description': taskData['description'],
      'due_date': taskData['due_date'],
      'reminder_option': taskData['reminder_option'],
      'reminder_time': taskData['reminder_time'],
      'is_completed': taskData['isCompleted'],
    };

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {"Content-Type": "application/json"},
      body: json.encode(apiTaskData),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to add task: ${response.statusCode}");
    }
  }

  // ✅ Update Task
  static Future<void> updateTask(
      String taskId, Map<String, dynamic> taskData) async {
    // Convert isCompleted to is_completed for API consistency
    Map<String, dynamic> apiTaskData = {
      'title': taskData['title'],
      'description': taskData['description'],
      'due_date': taskData['due_date'],
      'reminder_option': taskData['reminder_option'],
      'reminder_time': taskData['reminder_time'],
      'is_completed': taskData['isCompleted'],
    };

    final response = await http.put(
      Uri.parse("$baseUrl/$taskId"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(apiTaskData),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update task: ${response.statusCode}");
    }
  }

  // ✅ Delete Task
  static Future<void> deleteTask(String taskId) async {
    final response = await http.delete(Uri.parse("$baseUrl/$taskId"));
    if (response.statusCode != 200) {
      throw Exception("Failed to delete task");
    }
  }
}*/
class TaskService {
  static Database? _database;

  // Initialize the database
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDB();
    return _database!;
  }

  // Create and open the database
  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'tasks_database.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            description TEXT,
            due_date TEXT,
            reminder_option TEXT DEFAULT 'On Due Date',
            reminder_time TEXT,
            is_completed INTEGER DEFAULT 0
          )
          ''');
      },
    );
  }

  // ✅ Fetch Tasks
  static Future<List<Map<String, dynamic>>> fetchTasks(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> tasks = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return tasks.map((task) {
      // Ensure is_completed is properly converted to boolean
      bool isCompleted = task['is_completed'] == 1;

      return {
        'id': task['id']
            .toString(), // Convert to string to match your current format
        'title': task['title'],
        'description': task['description'] ?? '',
        'due_date': task['due_date'] ?? '',
        'reminder_option': task['reminder_option'] ?? 'On Due Date',
        'reminder_time': task['reminder_time'] ?? '',
        'isCompleted': isCompleted,
      };
    }).toList();
  }

  // ✅ Insert New Task
  static Future<int> addTask(Map<String, dynamic> taskData) async {
    final db = await database;

    // Convert isCompleted to is_completed integer for SQLite
    Map<String, dynamic> dbTaskData = {
      'user_id': taskData['user_id'],
      'title': taskData['title'],
      'description': taskData['description'],
      'due_date': taskData['due_date'],
      'reminder_option': taskData['reminder_option'],
      'reminder_time': taskData['reminder_time'],
      'is_completed': taskData['isCompleted'] ? 1 : 0,
    };

    return await db.insert('tasks', dbTaskData);
  }

  // ✅ Update Task
  static Future<int> updateTask(
      String taskId, Map<String, dynamic> taskData) async {
    final db = await database;

    // Convert isCompleted to is_completed integer for SQLite
    Map<String, dynamic> dbTaskData = {
      'title': taskData['title'],
      'description': taskData['description'],
      'due_date': taskData['due_date'],
      'reminder_option': taskData['reminder_option'],
      'reminder_time': taskData['reminder_time'],
      'is_completed': taskData['isCompleted'] ? 1 : 0,
    };

    return await db.update(
      'tasks',
      dbTaskData,
      where: 'id = ?',
      whereArgs: [int.parse(taskId)],
    );
  }

  // ✅ Delete Task
  static Future<int> deleteTask(String taskId) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [int.parse(taskId)],
    );
  }

  // New method: Toggle task completion status
  static Future<int> toggleTaskCompletion(
      String taskId, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'tasks',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [int.parse(taskId)],
    );
  }

  // New method: Delete all completed tasks
  static Future<int> deleteCompletedTasks(String userId) async {
    final db = await database;
    return await db.delete(
      'tasks',
      where: 'user_id = ? AND is_completed = ?',
      whereArgs: [userId, 1],
    );
  }

  static Future<Map<String, dynamic>?> getUpcomingTask(String userId) async {
    final db = await database;
    final now = DateTime.now();

    // Get tasks that are due in the future and not completed
    final List<Map<String, dynamic>> upcomingTasks = await db.query(
      'tasks',
      where:
          'user_id = ? AND is_completed = 0 AND due_date IS NOT NULL AND due_date != ""',
      whereArgs: [userId],
      orderBy: 'due_date ASC',
      limit: 1,
    );

    if (upcomingTasks.isEmpty) {
      return null;
    }

    final task = upcomingTasks.first;

    // Ensure is_completed is properly converted to boolean
    bool isCompleted = task['is_completed'] == 1;

    return {
      'id': task['id'].toString(),
      'title': task['title'],
      'description': task['description'] ?? '',
      'due_date': task['due_date'] ?? '',
      'reminder_option': task['reminder_option'] ?? 'On Due Date',
      'reminder_time': task['reminder_time'] ?? '',
      'isCompleted': isCompleted,
    };
  }
}
