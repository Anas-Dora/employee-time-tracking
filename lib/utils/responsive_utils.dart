import 'package:flutter/material.dart';

/// Utility-Klasse für responsives Design
/// Alle Größen können hier zentral angepasst werden!
class ResponsiveUtils {
  // ====== KONFIGURIERBARE KONSTANTEN ======

  /// Skalierungsfaktor für kleine Geräte (multipliziert mit der Basisgröße)
  static const double SMALL_DEVICE_SCALE = 1.0;  // 1.0 = 100%, 0.8 = 80%, 1.2 = 120%
  
  /// Skalierungsfaktor für mittlere Geräte
  static const double MEDIUM_DEVICE_SCALE = 1.0;  // Standard
  
  /// Skalierungsfaktor für große Geräte (Tablets)
  static const double LARGE_DEVICE_SCALE = 1.0;  // Standard
  
  /// Standard Padding für kleine Geräte
  static const double SMALL_PADDING = 8.0;
  
  /// Standard Padding für mittlere Geräte
  static const double MEDIUM_PADDING = 12.0;
  
  /// Standard Padding für große Geräte
  static const double LARGE_PADDING = 16.0;
  
  /// Standard Button Breite für kleine Geräte
  static const double SMALL_BUTTON_WIDTH = 150.0;
  
  /// Standard Button Breite für mittlere/große Geräte
  static const double NORMAL_BUTTON_WIDTH = 290.0;
  
  /// Breite für Container
  static const double CONTAINER_WIDTH = 0.0;  // 0 = double.infinity
  
  // ====== END KONFIGURATION ======

  /// Bestimmt die Bildschirmbreite
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Bestimmt die Bildschirmhöhe
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Berechnet eine responsive Größe basierend auf der Bildschirmbreite
  static double getResponsiveSize(BuildContext context, double baseSize) {
    double width = getScreenWidth(context);
    
    if (width < 360) {
      return baseSize * SMALL_DEVICE_SCALE;
    } else if (width < 600) {
      return baseSize * MEDIUM_DEVICE_SCALE;
    } else if (width < 900) {
      return baseSize * MEDIUM_DEVICE_SCALE;
    } else {
      return baseSize * LARGE_DEVICE_SCALE;
    }
  }

  /// Gibt an, ob das Gerät klein ist (< 360dp)
  static bool isSmallDevice(BuildContext context) {
    return getScreenWidth(context) < 360;
  }

  /// Gibt an, ob das Gerät mittelgroß ist (360dp - 600dp)
  static bool isMediumDevice(BuildContext context) {
    return getScreenWidth(context) >= 360 && getScreenWidth(context) < 600;
  }

  /// Gibt an, ob das Gerät groß ist (>= 600dp)
  static bool isLargeDevice(BuildContext context) {
    return getScreenWidth(context) >= 600;
  }

  /// Gibt Padding basierend auf Gerätegröße zurück
  static EdgeInsets getResponsivePadding(BuildContext context) {
    double width = getScreenWidth(context);
    
    if (width < 360) {
      return EdgeInsets.all(SMALL_PADDING);
    } else if (width < 600) {
      return EdgeInsets.all(MEDIUM_PADDING);
    } else {
      return EdgeInsets.all(LARGE_PADDING);
    }
  }

  /// Gibt responsive Schriftgröße zurück
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    return getResponsiveSize(context, baseSize);
  }
  
  /// Gibt responsive Button Breite zurück
  static double getResponsiveButtonWidth(BuildContext context) {
    if (isMediumDevice(context)) {
      return SMALL_BUTTON_WIDTH;
    }
    return NORMAL_BUTTON_WIDTH;
  }
  
  /// Berechnet responsive Höhe basierend auf Prozentsatz der Bildschirmhöhe
  /// z.B. getResponsiveHeight(context, 0.3) = 30% der Bildschirmhöhe
  static double getResponsiveHeight(BuildContext context, double percentage) {
    return getScreenHeight(context) * percentage;
  }
  
  /// Berechnet responsive Breite basierend auf Prozentsatz der Bildschirmbreite
  /// z.B. getResponsiveWidth(context, 0.5) = 50% der Bildschirmbreite
  static double getResponsiveWidth(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }
}

