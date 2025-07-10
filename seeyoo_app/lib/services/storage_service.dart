import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seeyoo_app/models/auth_response.dart';
import 'package:seeyoo_app/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Secure Storage für sensible Daten
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Keys für Secure Storage
  static const String _billingAuthKey = 'billing_auth';
  
  // Keys für SharedPreferences
  static const String _tokenKey = 'auth_token_data';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  static const String _userIdKey = 'user_id'; // Wird für Auth-API ID verwendet
  static const String _billingUserIdKey = 'billing_user_id'; // Separate ID für Billing-API
  static const String _userDataKey = 'user_data';
  static const String _userSettingsKey = 'user_settings';
  static const String _userEmailKey = 'user_email'; // E-Mail-Adresse des Benutzers

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

  // Auth-API User-ID abrufen
  Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }
  
  // Auth-API User-ID direkt setzen
  Future<void> setUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }
  
  // Billing-API User-ID abrufen
  Future<int?> getBillingUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_billingUserIdKey);
  }
  
  // Billing-API User-ID direkt setzen
  Future<void> setBillingUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_billingUserIdKey, userId);
  }
  
  // Benutzer-E-Mail speichern
  Future<void> setUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
  }
  
  // Benutzer-E-Mail abrufen
  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
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
  
  // Speichern der Favoriten-Reihenfolge (als Liste von Kanal-IDs)
  Future<void> saveFavoritesOrder(List<int> channelIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('favorites_order', jsonEncode(channelIds));
  }
  
  // Abrufen der Favoriten-Reihenfolge
  Future<List<int>?> getFavoritesOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final orderString = prefs.getString('favorites_order');
    
    if (orderString == null || orderString.isEmpty) {
      return null;
    }
    
    try {
      final List<dynamic> orderList = jsonDecode(orderString);
      return orderList.cast<int>();
    } catch (e) {
      print('Error parsing favorites order: $e');
      return null;
    }
  }
  
  // Speichern des zuletzt gesehenen Kanals im TV-Screen
  Future<void> saveLastTvChannel(int channelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_tv_channel', channelId);
  }
  
  // Abrufen des zuletzt gesehenen Kanals im TV-Screen
  Future<int?> getLastTvChannel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_tv_channel');
  }
  
  // Speichern des zuletzt gesehenen Kanals im Favoriten-Screen
  Future<void> saveLastFavoriteChannel(int channelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_favorite_channel', channelId);
  }
  
  // Abrufen des zuletzt gesehenen Kanals im Favoriten-Screen
  Future<int?> getLastFavoriteChannel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('last_favorite_channel');
  }
  
  // Speichert die Billing-API-Zugangsdaten sicher
  Future<void> saveBillingAuth(String username, String password) async {
    try {
      // Erstelle einen Base64-kodierten Basic Auth Header
      final credentials = base64Encode(utf8.encode('$username:$password'));
      await _secureStorage.write(key: _billingAuthKey, value: credentials);
      
      // Als Backup auch in SharedPreferences speichern
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('billing_auth_backup', credentials);
    } catch (e) {
      print('Fehler beim Speichern der Billing-Auth-Daten: $e');
      // Sicherstellen, dass zumindest SharedPreferences funktioniert
      final prefs = await SharedPreferences.getInstance();
      final credentials = base64Encode(utf8.encode('$username:$password'));
      await prefs.setString('billing_auth_backup', credentials);
    }
  }

  // Holt die Billing-API-Zugangsdaten
  Future<String?> getBillingAuth() async {
    try {
      // Versuche zuerst aus Secure Storage zu lesen
      final secureAuth = await _secureStorage.read(key: _billingAuthKey);
      if (secureAuth != null) {
        return secureAuth;
      }
    } catch (e) {
      print('Fehler beim Lesen der Billing-Auth-Daten aus Secure Storage: $e');
    }
    
    // Fallback auf SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('billing_auth_backup');
    } catch (e) {
      print('Fehler beim Lesen der Billing-Auth-Backup-Daten: $e');
      return null;
    }
  }

  /// Alle Benutzerdaten löschen (zusätzlich zu Auth-Daten)
  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_tokenExpiryKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_billingUserIdKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_userSettingsKey);
    
    // Auch sensible Daten aus Secure Storage löschen
    try {
      await _secureStorage.delete(key: _billingAuthKey);
    } catch (e) {
      print('Fehler beim Löschen von Secure Storage Daten: $e');
      // Fehler ignorieren, da dies den Logout nicht blockieren sollte
    }
    await prefs.remove('favorites_order'); // Lösche auch die gespeicherte Favoriten-Reihenfolge
    await prefs.remove('last_tv_channel'); // Lösche den gespeicherten letzten TV-Kanal
    await prefs.remove('last_favorite_channel'); // Lösche den gespeicherten letzten Favoriten-Kanal
  }
}
