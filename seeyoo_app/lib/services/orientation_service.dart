import 'package:flutter/services.dart';

/// Ein zentraler Service für die Verwaltung der Bildschirmausrichtung
/// Ermöglicht das einheitliche Aktivieren und Deaktivieren der Rotation
class OrientationService {
  static final OrientationService _instance = OrientationService._internal();
  
  factory OrientationService() {
    return _instance;
  }
  
  OrientationService._internal();
  
  /// Aktiviert die Rotation (z.B. für TV und TV-Favoriten Screens)
  void enableRotation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  
  /// Deaktiviert die Rotation (nur Portrait-Modus)
  void disableRotation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
