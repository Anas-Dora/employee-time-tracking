import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:employee_time_tracking/database/database_helper.dart';


class Holiday {
  final String name;
  final String date;

  Holiday({
    required this.name,
    required this.date,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      name: json['name'],
      date: json['date'],
    );
  }
}

class HolidayService {
  static const String _baseUrl = 'https://ist-feiertag.de/api/v1/feiertage';
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// Prüft, ob ein bestimmtes Datum ein Feiertag ist
  /// Verwendet zunächst den Cache, bevor die API abgefragt wird
  Future<bool> isHoliday({
    required DateTime date,
    required String bundesland,
  }) async {
    final formattedDate =
        "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    // Erst im Cache prüfen
    final cachedHoliday = await _db.getHolidayFromCache(
      date: formattedDate,
      bundesland: bundesland,
    );

    if (cachedHoliday != null) {
      return true;
    }

    // Wenn nicht im Cache, API abfragen
    final url = Uri.parse(
      '$_baseUrl?date=$formattedDate&bundesland=$bundesland',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Fehler beim Laden der Feiertage ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final isHolidayResult = data['count'] > 0;

      // Wenn es ein Feiertag ist, im Cache speichern
      if (isHolidayResult && data['holidays'] != null && data['holidays'].length > 0) {
        final holiday = data['holidays'][0];
        await _db.saveHoliday(
          date: formattedDate,
          name: holiday['name'] ?? 'Feiertag',
          bundesland: bundesland,
        );
      }

      return isHolidayResult;
    } catch (e) {
      print('Fehler beim Abrufen des Feiertags: $e');
      rethrow;
    }
  }

  /// Lädt alle Feiertage für ein Jahr und Bundesland
  /// und speichert sie in der Datenbank
  Future<List<Holiday>> fetchAndCacheHolidaysForYear({
    required int year,
    required String bundesland,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl?jahr=$year&bundesland=$bundesland',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        throw Exception('Fehler beim Laden der Feiertage: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      final holidaysData = data['holidays'] ?? [];

      // Alle Feiertage in der Datenbank speichern
      if (holidaysData.isNotEmpty) {
        await _db.saveHolidays(
          holidays: List<Map<String, dynamic>>.from(holidaysData),
          bundesland: bundesland,
        );
      }

      // Als Holiday-Objekte zurückgeben
      return (holidaysData as List)
          .map((h) => Holiday.fromJson(h as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Fehler beim Laden der Feiertage: $e');
      rethrow;
    }
  }

  /// Lädt Feiertage aus dem Cache für ein Jahr
  Future<List<Holiday>> getCachedHolidaysForYear({
    required int year,
    required String bundesland,
  }) async {
    final cached = await _db.getHolidaysForYear(
      year: year,
      bundesland: bundesland,
    );

    return cached
        .map((h) => Holiday(name: h['name'], date: h['date']))
        .toList();
  }

  /// Leert den Feiertag-Cache
  Future<void> clearCache() async {
    await _db.clearHolidayCache();
  }
}