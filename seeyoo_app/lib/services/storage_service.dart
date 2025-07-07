import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seeyoo_app/models/auth_response.dart';
import 'package:seeyoo_app/models/user.dart';

class StorageService {
  // Keys für SharedPreferences
  static const String _tokenKey = 'auth_token_data';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _userSettingsKey = 'user_settings';

  // Token speichern
  Future<void> saveToken(AuthResponse authResponse) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Komplettes Auth-Response-Objekt als JSON speichern
    await prefs.setString(_tokenKey, jsonEncode(authResponse.toJson()));
    
    // Wichtige Werte separat für schnellen Zugriff speichern
    await prefs.setString(_accessTokenKey, authResponse.accessToken ?? '');
    await prefs.setString(_refreshTokenKey, authResponse.refreshToken ?? '');
    await prefs.setInt(_userIdKey, authResponse.userId ?? 0);
    
    // Ablaufzeit berechnen und speichern
    if (authResponse.expiresIn != null) {
      final expiryDate = DateTime.now()
          .add(Duration(seconds: authResponse.expiresIn!))
          .millisecondsSinceEpoch;
      await prefs.setInt(_tokenExpiryKey, expiryDate);
    }
  }

  // Access-Token abrufen
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Prüfen, ob der Token abgelaufen ist
    if (await isTokenExpired()) {
      return null;
    }
    
    return prefs.getString(_accessTokenKey);
  }

  // Refresh-Token abrufen
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // User-ID abrufen
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  // Prüfen, ob der Token abgelaufen ist
  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiryDate = prefs.getInt(_tokenExpiryKey);
    
    if (expiryDate == null) {
      return true;
    }
    
    return DateTime.now().millisecondsSinceEpoch > expiryDate;
  }

  

  // Prüfen, ob ein Benutzer eingeloggt ist
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }
  
  // Benutzerdaten speichern
  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
  }
  
  // Benutzerdaten abrufen
  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString == null || userDataString.isEmpty) {
      return null;
    }
    
    try {
      final userData = jsonDecode(userDataString);
      return User.fromJson(userData);
    } catch (e) {
      print('Error parsing user data: $e');
      return null;
    }
  }
  
  // Benutzereinstellungen speichern
  Future<void> saveUserSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userSettingsKey, jsonEncode(settings));
  }
  
  // Benutzereinstellungen abrufen
  Future<Map<String, dynamic>?> getUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsString = prefs.getString(_userSettingsKey);
    
    if (settingsString == null || settingsString.isEmpty) {
      return null;
    }
    
    try {
      return jsonDecode(settingsString) as Map<String, dynamic>;
    } catch (e) {
      print('Error parsing user settings: $e');
      return null;
    }
  }
  
  // Alle Benutzerdaten löschen (zusätzlich zu Auth-Daten)
  @override
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_userSettingsKey);
  }
}
