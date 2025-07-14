/// Service zur Steuerung der AppBar-Sichtbarkeit
class AppBarVisibilityService {
  static final AppBarVisibilityService _instance = AppBarVisibilityService._internal();
  
  factory AppBarVisibilityService() {
    return _instance;
  }
  
  AppBarVisibilityService._internal();
  
  /// Die aktuelle AppBar-Sichtbarkeit
  bool _showAppBar = true;
  
  /// Getter für die AppBar-Sichtbarkeit
  bool get showAppBar => _showAppBar;
  
  /// Setzt die AppBar-Sichtbarkeit
  void setAppBarVisibility(bool visible) {
    _showAppBar = visible;
  }
}
