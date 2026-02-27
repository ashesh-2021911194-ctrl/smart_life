import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';
import 'package:flutter/widgets.dart' show BuildContext;

// Database helper class
class DatabaseHelperNotes {
  static final DatabaseHelperNotes instance = DatabaseHelperNotes._init();
  static Database? _database;

  DatabaseHelperNotes._init();

  // Get database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('notes.db');
    return _database!;
  }

  // Initialize database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  // Create database tables
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // CRUD Operations

  // Create a new note
  Future<String> createNote(String userId, String title, String content) async {
    final db = await database;
    final id = const Uuid().v4(); // Generate a unique ID
    final now = DateTime.now().toIso8601String();

    final note = Note(
      id: id,
      userId: userId,
      title: title,
      content: content,
      createdAt: now,
    );

    await db.insert('notes', {
      'id': note.id,
      'user_id': note.userId,
      'title': note.title,
      'content': note.content,
      'created_at': note.createdAt,
    });

    return id;
  }

  // Read all notes for a user
  Future<List<Note>> getNotes(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Note(
        id: maps[i]['id'],
        userId: maps[i]['user_id'],
        title: maps[i]['title'],
        content: maps[i]['content'],
        createdAt: maps[i]['created_at'],
      );
    });
  }

  // Update a note
  Future<int> updateNote(String id, String title, String content) async {
    final db = await database;

    return await db.update(
      'notes',
      {'title': title, 'content': content},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete a note
  Future<int> deleteNote(String id) async {
    final db = await database;

    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Close database
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

// Note model - remains mostly unchanged
class Note {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String createdAt;

  Note({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  // Convert a Note into a Map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'content': content,
      'created_at': createdAt,
    };
  }

  // Create a Note from a Map or Json
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      content: map['content'],
      createdAt: map['created_at'],
    );
  }

  // For backward compatibility
  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class NotesPage extends StatefulWidget {
  final String userId;

  const NotesPage({super.key, required this.userId});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Note> notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotes();
  }

  /*Future<void> _fetchNotesWithoutContext() async {
    setState(() => _isLoading = true);
    try {
      final loadedNotes =
          await DatabaseHelperNotes.instance.getNotes(widget.userId);
      setState(() {
        notes = loadedNotes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Handle error without showing SnackBar (since we have no context)
      debugPrint('Error loading notes: $e');
    }
  }*/

  Future<void> fetchNotes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Fetching notes for user: ${widget.userId}');
      final loadedNotes =
          await DatabaseHelperNotes.instance.getNotes(widget.userId);

      setState(() {
        notes = loadedNotes;
        _isLoading = false;
      });

      print('Notes count after update: ${notes.length}');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading notes: $e');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error loading notes: $e')),
      );
    }
  }

  Future<void> deleteNote(Note note, BuildContext context) async {
    try {
      final rowsDeleted =
          await DatabaseHelperNotes.instance.deleteNote(note.id);

      if (rowsDeleted > 0) {
        setState(() {
          notes.removeWhere((item) => item.id == note.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note deleted successfully')),
        );
      } else {
        print('Failed to delete note. No rows affected.');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete note')),
        );
      }
    } catch (e) {
      print('Error deleting note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _confirmDeleteNote(Note note, BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Note'),
          content: Text('Are you sure you want to delete "${note.title}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                deleteNote(note, context);
              },
            ),
          ],
        );
      },
    );
  }

  void _navigateToAddNote(BuildContext context) {
    try {
      print(
          'Attempting to navigate to AddNotePage with userId: ${widget.userId}');

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddNotePage(userId: widget.userId),
        ),
      ).then((result) {
        print('Navigation completed with result: $result');
        if (result == true) {
          fetchNotes();
        }
      }).catchError((error) {
        print('Navigation error: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening add note page: $error')),
        );
      });
    } catch (e) {
      print('Error initiating navigation: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _navigateToNoteDetail(Note note, BuildContext context) async {
    bool? updated = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NoteDetailPage(note: note)),
    );

    if (updated == true) {
      fetchNotes();
    }
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.notesWallpaper;

    return Scaffold(
      appBar: AppBar(title: const Text("My Notes")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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

                // 📜 Notes Content
                notes.isEmpty
                    ? Center(
                        child: Text(
                          "No notes available",
                          style: bodyStyle.copyWith(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          final firstLine = note.content.split('\n').first;

                          return Card(
                            color: Colors.black.withOpacity(0.85),
                            child: Dismissible(
                              key: Key(note.id),
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                bool delete = false;
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text('Delete Note'),
                                      content: Text(
                                          'Are you sure you want to delete "${note.title}"?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: const Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: const Text('Delete',
                                              style:
                                                  TextStyle(color: Colors.red)),
                                          onPressed: () {
                                            delete = true;
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                                return delete;
                              },
                              onDismissed: (direction) {
                                deleteNote(note, context);
                              },
                              child: ListTile(
                                title: Text(note.title, style: headlineStyle),
                                subtitle: Text(
                                  firstLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: bodyStyle,
                                ),
                                onTap: () =>
                                    _navigateToNoteDetail(note, context),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () =>
                                      _confirmDeleteNote(note, context),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddNote(context), // Wrap in function
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddNotePage extends StatefulWidget {
  final String userId;

  const AddNotePage({super.key, required this.userId});

  @override
  _AddNotePageState createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSaving = false;

  Future<void> saveNote(BuildContext context) async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a title")),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await DatabaseHelperNotes.instance.createNote(
        widget.userId,
        titleController.text,
        contentController.text,
      );

      setState(() {
        _isSaving = false;
      });

      Navigator.pop(
          context, true); // Return true to trigger refresh
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      print('Error saving note: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save note: $e")),
      );
    }
  }

  void startListening() async {
    bool available = await _speech.initialize();
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          contentController.text = result.recognizedWords;
        });
      });
    }
  }

  void stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final headlineStyle = Theme.of(context).textTheme.headlineMedium!;
    final bodyStyle = Theme.of(context).textTheme.bodyLarge!;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    final wallpaperAsset = themeNotifier.expenseWallpaper;

    return Scaffold(
      appBar: AppBar(title: const Text("Add Note")),
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    filled: true,
                    fillColor: Colors.white70,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: TextField(
                    controller: contentController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      labelText: "Content",
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isListening ? stopListening : startListening,
                      icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                      label: Text(_isListening ? "Stop" : "Speak"),
                    ),
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : () async {
                              // Wrap in async function
                              await saveNote(context);
                            },
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text("Save"),
                    )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class NoteDetailPage extends StatefulWidget {
  final Note note;

  const NoteDetailPage({super.key, required this.note});

  @override
  _NoteDetailPageState createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final rowsUpdated = await DatabaseHelperNotes.instance.updateNote(
        widget.note.id,
        _titleController.text,
        _contentController.text,
      );

      setState(() {
        _isSaving = false;
      });

      if (rowsUpdated > 0) {
        print('Note updated successfully');
        Navigator.pop(context as BuildContext, true); // Return to refresh notes
      } else {
        print('Failed to update note. No rows affected.');
        ScaffoldMessenger.of(context as BuildContext).showSnackBar(
          const SnackBar(content: Text('Failed to update note')),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      print('Error updating note: $e');
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Note"),
        actions: [
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveNote,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: null,
                expands: true,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}






