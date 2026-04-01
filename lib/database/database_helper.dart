import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;
  static const int _dbVersion = 2;

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
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
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

    await _createHolidaysTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createHolidaysTable(db);
    }
  }

  Future<void> _createHolidaysTable(Database db) async {
    // IF NOT EXISTS macht die Migration idempotent und sicher bei Mehrfachaufrufen.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS holidays (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        name TEXT NOT NULL,
        bundesland TEXT NOT NULL,
        cached_at TEXT NOT NULL,
        UNIQUE(date, bundesland)
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

  // ────────────── HOLIDAYS (CACHING) ──────────────

  /// Feiertag speichern (Caching)
  Future<void> saveHoliday({
    required String date,
    required String name,
    required String bundesland,
  }) async {
    final db = await database;
    await db.insert(
      'holidays',
      {
        'date': date,
        'name': name,
        'bundesland': bundesland,
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Mehrere Feiertage auf einmal speichern
  Future<void> saveHolidays({
    required List<Map<String, dynamic>> holidays,
    required String bundesland,
  }) async {
    final db = await database;
    final batch = db.batch();

    for (final holiday in holidays) {
      batch.insert(
        'holidays',
        {
          'date': holiday['date'],
          'name': holiday['name'],
          'bundesland': bundesland,
          'cached_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  /// Prüfen, ob ein Feiertag bereits gecacht ist
  Future<bool> isHolidayInCache({
    required String date,
    required String bundesland,
  }) async {
    final db = await database;
    final results = await db.query(
      'holidays',
      where: 'date = ? AND bundesland = ?',
      whereArgs: [date, bundesland],
    );
    return results.isNotEmpty;
  }

  /// Feiertag aus dem Cache abrufen
  Future<Map<String, dynamic>?> getHolidayFromCache({
    required String date,
    required String bundesland,
  }) async {
    final db = await database;
    final results = await db.query(
      'holidays',
      where: 'date = ? AND bundesland = ?',
      whereArgs: [date, bundesland],
    );
    return results.isNotEmpty ? results.first : null;
  }

  /// Alle Feiertage für ein Jahr und Bundesland abrufen
  Future<List<Map<String, dynamic>>> getHolidaysForYear({
    required int year,
    required String bundesland,
  }) async {
    final db = await database;
    final from = DateTime(year, 1, 1).toIso8601String();
    final to = DateTime(year, 12, 31, 23, 59, 59).toIso8601String();
    return await db.query(
      'holidays',
      where: 'date BETWEEN ? AND ? AND bundesland = ?',
      whereArgs: [from, to, bundesland],
    );
  }

  /// Cache leeren
  Future<void> clearHolidayCache() async {
    final db = await database;
    await db.delete('holidays');
  }
}

