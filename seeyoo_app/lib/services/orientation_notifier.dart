import 'package:flutter/foundation.dart';

/// Ein einfacher Notifier für Bildschirmorientierungsänderungen
class OrientationNotifier extends ChangeNotifier {
  static final OrientationNotifier _instance = OrientationNotifier._internal();
  
  factory OrientationNotifier() {
    return _instance;
  }
  
  OrientationNotifier._internal();
  
  bool _isLandscape = false;
  
  bool get isLandscape => _isLandscape;
  
  void setLandscape(bool value) {
    if (_isLandscape != value) {
      _isLandscape = value;
      notifyListeners();
    }
  }
}
