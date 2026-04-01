import 'package:employee_time_tracking/services/holiday_service.dart';

/// Holiday Cache Initializer
/// Ruft beim App-Start die Feiertage herunter und cached sie
class HolidayCacheInitializer {
  static const List<String> germanStates = [
    'BW', // Baden-Württemberg
    'BY', // Bayern
    'BE', // Berlin
    'BB', // Brandenburg
    'HB', // Bremen
    'HH', // Hamburg
    'HE', // Hessen
    'MV', // Mecklenburg-Vorpommern
    'NI', // Niedersachsen
    'NW', // Nordrhein-Westfalen
    'RP', // Rheinland-Pfalz
    'SL', // Saarland
    'SN', // Sachsen
    'ST', // Sachsen-Anhalt
    'SH', // Schleswig-Holstein
    'TH', // Thüringen
  ];

  /// Initialisiere den Feiertag-Cache beim App-Start
  /// Lade alle Feiertage für das aktuelle und nächste Jahr
  static Future<void> initializeHolidayCache({
    String? specificState,
  }) async {
    final holidayService = HolidayService();
    final now = DateTime.now();
    final years = [now.year, now.year + 1];
    final states = specificState != null ? [specificState] : germanStates;
    await holidayService.fetchAndCacheHolidaysForYear(
      year: DateTime.now().year,
      bundesland: specificState ?? 'BW',
    );


    try {
      print('Initialisiere Feiertag-Cache...');

      for (final year in years) {
        for (final state in states) {
          try {
            print('Lade Feiertage für $state ($year)...');
            await holidayService.getCachedHolidaysForYear(
              year: year,
              bundesland: state,
            );
          } catch (e) {
            print('Fehler beim Laden von $state ($year): $e');
            // Nicht kritisch - fahre mit nächstem Bundesland fort
          }
        }
      }

      print('Feiertag-Cache erfolgreich initialisiert!');
    } catch (e) {
      print('Fehler beim Initialisieren des Feiertag-Caches: $e');
    }
  }

  /// Initialisiere Cache nur für ein spezifisches Bundesland
  static Future<void> initializeForState(String bundesland) async {
    await initializeHolidayCache(
      specificState: bundesland,
    );
  }
}


