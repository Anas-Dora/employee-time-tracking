import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'employee_time_tracking.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabelle für Tageseinträge (DayOverview / WorkDay)
    await db.execute('''
      CREATE TABLE day_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL DEFAULT 'none',
        start_time TEXT,
        end_time TEXT,
        break_minutes INTEGER DEFAULT 0
      )
    ''');

    // Tabelle für das Profil
    await db.execute('''
      CREATE TABLE profile (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        name TEXT NOT NULL DEFAULT '',
        job_title TEXT NOT NULL DEFAULT '',
        company TEXT NOT NULL DEFAULT '',
        employee_id TEXT NOT NULL DEFAULT '',
        department TEXT NOT NULL DEFAULT '',
        reminders_enabled INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // ────────────── DAY ENTRIES ──────────────

  /// Eintrag speichern oder aktualisieren (UPSERT nach Datum)
  Future<void> upsertDayEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert(
      'day_entries',
      entry,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Alle Einträge eines Monats laden
  Future<List<Map<String, dynamic>>> getDayEntriesForMonth(
      int year, int month) async {
    final db = await database;
    final from = DateTime(year, month, 1).toIso8601String();
    final to = DateTime(year, month + 1, 0, 23, 59, 59).toIso8601String();
    return await db.query(
      'day_entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [from, to],
    );
  }

  /// Alle Einträge einer Woche laden (Montag bis Sonntag)
  Future<List<Map<String, dynamic>>> getDayEntriesForWeek(
      DateTime monday) async {
    final db = await database;
    final from = DateTime(monday.year, monday.month, monday.day)
        .toIso8601String();
    final sunday = monday.add(const Duration(days: 6));
    final to = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59)
        .toIso8601String();
    return await db.query(
      'day_entries',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [from, to],
    );
  }

  /// Einzelnen Eintrag per Datum laden
  Future<Map<String, dynamic>?> getDayEntry(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    final results = await db.query(
      'day_entries',
      where: 'date = ?',
      whereArgs: [dateStr],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Eintrag löschen
  Future<void> deleteDayEntry(DateTime date) async {
    final db = await database;
    final dateStr = DateTime(date.year, date.month, date.day).toIso8601String();
    await db.delete('day_entries', where: 'date = ?', whereArgs: [dateStr]);
  }

  // ────────────── PROFILE ──────────────

  /// Profil laden
  Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    final results = await db.query('profile', where: 'id = 1');
    return results.isNotEmpty ? results.first : null;
  }

  /// Profil speichern oder aktualisieren
  Future<void> upsertProfile(Map<String, dynamic> profile) async {
    final db = await database;
    profile['id'] = 1;
    await db.insert(
      'profile',
      profile,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

