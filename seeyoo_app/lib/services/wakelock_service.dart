import 'package:wakelock_plus/wakelock_plus.dart';

/// Service zur Verwaltung des Wakelock-Status
/// Verhindert dass der Bildschirm ausgeht während die App läuft
class WakelockService {
  static final WakelockService _instance = WakelockService._internal();
  factory WakelockService() => _instance;
  WakelockService._internal();

  bool _isWakelockEnabled = false;

  /// Aktiviert das Wakelock - Bildschirm geht nicht aus
  Future<void> enableWakelock() async {
    try {
      if (!_isWakelockEnabled) {
        await WakelockPlus.enable();
        _isWakelockEnabled = true;
        print('WakelockService: Wakelock aktiviert - Bildschirm bleibt an');
      }
    } catch (e) {
      print('WakelockService: Fehler beim Aktivieren des Wakelock: $e');
    }
  }

  /// Deaktiviert das Wakelock - Bildschirm kann wieder ausgehen
  Future<void> disableWakelock() async {
    try {
      if (_isWakelockEnabled) {
        await WakelockPlus.disable();
        _isWakelockEnabled = false;
        print('WakelockService: Wakelock deaktiviert - Bildschirm kann ausgehen');
      }
    } catch (e) {
      print('WakelockService: Fehler beim Deaktivieren des Wakelock: $e');
    }
  }

  /// Prüft ob das Wakelock aktuell aktiv ist
  Future<bool> isWakelockEnabled() async {
    try {
      final isEnabled = await WakelockPlus.enabled;
      _isWakelockEnabled = isEnabled;
      return isEnabled;
    } catch (e) {
      print('WakelockService: Fehler beim Prüfen des Wakelock-Status: $e');
      return false;
    }
  }

  /// Getter für lokalen Status (ohne async)
  bool get isEnabled => _isWakelockEnabled;

  /// Initialisiert den Service und aktiviert das Wakelock
  Future<void> initialize() async {
    await enableWakelock();
  }

  /// Cleanup beim Beenden der App
  Future<void> dispose() async {
    await disableWakelock();
  }
}
