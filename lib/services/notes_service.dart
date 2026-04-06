import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/stock_note.dart';

// Backend code for note database logic
class NotesService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stock_notes.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ticker TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_ticker ON notes(ticker)
        ''');
      },
    );
  }

  Future<int> createNote(StockNote note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<StockNote>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) => StockNote.fromMap(map)).toList();
  }

  Future<List<StockNote>> getNotesByTicker(String ticker) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'ticker = ?',
      whereArgs: [ticker.toUpperCase()],
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) => StockNote.fromMap(map)).toList();
  }

  Future<int> getNotesCountByTicker(String ticker) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE ticker = ?',
      [ticker.toUpperCase()],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<StockNote?> getNote(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return StockNote.fromMap(maps.first);
  }

  Future<int> updateNote(StockNote note) async {
    final db = await database;
    return await db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StockNote>> searchNotes(String query, {String? ticker}) async {
    final db = await database;

    String whereClause = 'title LIKE ? OR content LIKE ? OR ticker LIKE ?';
    List<Object?> whereArgs = ['%$query%', '%$query%', '%$query%'];

    if (ticker != null && ticker.isNotEmpty) {
      whereClause += ' AND ticker = ?';
      whereArgs.add(ticker.toUpperCase());
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) => StockNote.fromMap(map)).toList();
  }
}