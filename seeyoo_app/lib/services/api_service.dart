import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:seeyoo_app/models/auth_response.dart';
import 'package:seeyoo_app/services/storage_service.dart';
import 'package:uuid/uuid.dart';

class ApiService {
  static const String baseUrl = 'http://app.seeyoo.tv/stalker_portal';
  static const String authEndpoint = '/auth/token';
  
  // DeviceInfo Plugin und UUID für Geräteidentifikation
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = Uuid();

  final StorageService _storageService = StorageService();
  
  // Singleton-Pattern
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal();
  
  // Geräteidentifikation abrufen
  Future<Map<String, String>> _getDeviceInfo() async {
    String deviceId = 'seeyoo-app-flutter';
    String deviceMac = '00:00:00:00:00:00';
    String serialNumber = '';
    
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        serialNumber = androidInfo.serialNumber;
        // MAC-Adresse auf Android erfordert möglicherweise zusätzliche Berechtigungen
        deviceMac = androidInfo.id.substring(0, 12).replaceAllMapped(
            RegExp(r'(.{2})'), (match) => '${match.group(0)}:').substring(0, 17);
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? _uuid.v4();
        serialNumber = iosInfo.utsname.machine;
        // iOS bietet keinen direkten Zugriff auf die MAC-Adresse
        deviceMac = deviceId.substring(0, 12).replaceAllMapped(
            RegExp(r'(.{2})'), (match) => '${match.group(0)}:').substring(0, 17);
      } else if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceId = webInfo.userAgent ?? 'web-browser';
        serialNumber = webInfo.browserName?.toString() ?? 'unknown';
        // Generiere eine pseudo-MAC für Web
        deviceMac = _uuid.v4().substring(0, 12).replaceAllMapped(
            RegExp(r'(.{2})'), (match) => '${match.group(0)}:').substring(0, 17);
      }
    } catch (e) {
      print('Error getting device info: $e');
      // Fallback auf UUID
      final uuid = _uuid.v4();
      deviceId = 'seeyoo-app-$uuid';
      serialNumber = uuid;
      deviceMac = uuid.substring(0, 12).replaceAllMapped(
          RegExp(r'(.{2})'), (match) => '${match.group(0)}:').substring(0, 17);
    }
    
    return {
      'device_id': deviceId,
      'mac': deviceMac,
      'serial_number': serialNumber,
    };
  }

  // Authentifizierung mit Resource Owner Password Credentials
  Future<AuthResponse> authenticate(String username, String password) async {
    try {
      // Debug-Ausgabe
      print('Authenticating with username: $username');
      
      // Geräteinformationen dynamisch abrufen
      final deviceInfo = await _getDeviceInfo();
      
      // Anfrage mit den erforderlichen Parametern gemäß Beispiel
      final Map<String, String> requestBody = {
        'grant_type': 'password',
        'username': username,
        'password': password,
        'mac': deviceInfo['mac'] ?? '00:00:00:00:00:00',
        'device_id': deviceInfo['device_id'] ?? 'seeyoo-app-flutter',
        'serial_number': deviceInfo['serial_number'] ?? '',
      };
      
      // Debug: Zeige die Request-Daten (ohne Passwort im Log)
      final debugBody = Map<String, String>.from(requestBody);
      debugBody['password'] = '*****'; // Passwort im Log verbergen
      print('Auth request to: $baseUrl$authEndpoint');
      print('Auth request body: $debugBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl$authEndpoint'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: requestBody,
      );
      
      // Debug-Ausgabe der Antwort
      print('Auth response status: ${response.statusCode}');
      print('Auth response body: ${response.body}');
      
      // Verschiedene Statuscode-Behandlung
      if (response.statusCode == 200) {
        final Map<String, dynamic> data;
        
        try {
          data = json.decode(response.body);
        } catch (e) {
          print('JSON decode error: $e');
          return AuthResponse(
            isSuccess: false,
            errorMessage: 'Unerwartetes Antwortformat: ${response.body}',
          );
        }
        
        // Prüfen, ob ein Fehler zurückgegeben wurde
        if (data.containsKey('error')) {
          final errorMsg = data['error'] ?? 'Authentication failed';
          print('Auth error from server: $errorMsg');
          
          // Spezieller Fall für invalid_client
          if (errorMsg == 'invalid_client') {
            return AuthResponse(
              isSuccess: false, 
              errorMessage: 'Ungültige Client-ID oder Anmeldeinformationen. Bitte überprüfen Sie Ihre Zugangsdaten.',
            );
          }
          
          return AuthResponse(
            isSuccess: false, 
            errorMessage: errorMsg,
          );
        }
        
        print('Auth successful: ${data['access_token'] != null}');
        
        // Token speichern
        final authResponse = AuthResponse.fromJson(data);
        await _storageService.saveToken(authResponse);
        
        return authResponse;
      } else {
        return AuthResponse(
          isSuccess: false, 
          errorMessage: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AuthResponse(
        isSuccess: false, 
        errorMessage: 'Network error: $e',
      );
    }
  }
  
  // Token-Erneuerung
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$authEndpoint'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          ...(await _getDeviceInfo()),
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        // Prüfen, ob ein Fehler zurückgegeben wurde
        if (data.containsKey('error')) {
          return AuthResponse(
            isSuccess: false, 
            errorMessage: data['error'] ?? 'Token refresh failed',
          );
        }
        
        // Token speichern
        final authResponse = AuthResponse.fromJson(data);
        await _storageService.saveToken(authResponse);
        
        return authResponse;
      } else {
        return AuthResponse(
          isSuccess: false, 
          errorMessage: 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return AuthResponse(
        isSuccess: false, 
        errorMessage: 'Network error: $e',
      );
    }
  }
  
  // HTTP GET mit Bearer-Token
  Future<http.Response?> get(String endpoint) async {
    try {
      final token = await _storageService.getAccessToken();
      
      if (token == null) {
        // Token nicht vorhanden, Benutzer muss sich erneut authentifizieren
        return null;
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      // 401 bedeutet, dass der Token abgelaufen ist
      if (response.statusCode == 401) {
        final refreshTokenValue = await _storageService.getRefreshToken();
        
        if (refreshTokenValue == null) {
          // Refresh-Token nicht vorhanden, Benutzer muss sich erneut authentifizieren
          return null;
        }
        
        // Token erneuern
        final refreshResponse = await refreshToken(refreshTokenValue);
        
        if (!refreshResponse.isSuccess) {
          // Token-Erneuerung fehlgeschlagen, Benutzer muss sich erneut authentifizieren
          return null;
        }
        
        // Anfrage mit neuem Token wiederholen
        return await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: {
            'Authorization': 'Bearer ${refreshResponse.accessToken}',
            'Accept': 'application/json',
          },
        );
      }
      
      return response;
    } catch (e) {
      print('API error: $e');
      return null;
    }
  }
  
  // Weitere HTTP-Methoden (POST, PUT, DELETE) können nach Bedarf hinzugefügt werden
}
