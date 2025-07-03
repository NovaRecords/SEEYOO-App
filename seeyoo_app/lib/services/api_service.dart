import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:seeyoo_app/models/auth_response.dart';
import 'package:seeyoo_app/models/epg_program.dart';
import 'package:seeyoo_app/models/tv_channel.dart';
import 'package:seeyoo_app/models/tv_genre.dart';
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
    // Initialwerte nur deklarieren, werden dynamisch basierend auf der Plattform gesetzt
    late String deviceId;
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
      // Fallback auf UUID für die Geräteidentifikation
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
        'device_id': deviceInfo['device_id'] ?? _uuid.v4(),
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
  
  // Holt die Liste der TV-Kanäle
  // Basierend auf API-Doku: /users/<user_id>/tv-channels
  Future<List<TvChannel>> getTvChannels({int limit = 100, int offset = 0}) async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) {
        print('No user ID available');
        return [];
      }

      final endpoint = '/api/v2/users/$userId/tv-channels?limit=$limit&offset=$offset';
      final response = await get(endpoint);
      
      if (response == null) {
        print('Failed to get TV channels - null response');
        return [];
      }
      
      if (response.statusCode != 200) {
        print('Failed to get TV channels: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }

      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] != null) {
        final List<dynamic> channelsData = data['results'];
        return channelsData.map((json) => TvChannel.fromJson(json)).toList();
      } else {
        print('API error: ${data['error'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      print('Error fetching TV channels: $e');
      return [];
    }
  }

  // Holt die Favoriten TV-Kanäle
  // Basierend auf API-Doku: /users/<user_id>/tv-channels?mark=favorite
  Future<List<TvChannel>> getFavoriteTvChannels({int limit = 100, int offset = 0}) async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) {
        print('No user ID available');
        return [];
      }

      final endpoint = '/api/v2/users/$userId/tv-channels?mark=favorite&limit=$limit&offset=$offset';
      final response = await get(endpoint);
      
      if (response == null || response.statusCode != 200) {
        print('Failed to get favorite TV channels: ${response?.statusCode}');
        return [];
      }

      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] != null) {
        final List<dynamic> channelsData = data['results'];
        return channelsData.map((json) => TvChannel.fromJson(json)).toList();
      } else {
        print('API error: ${data['error'] ?? 'Unknown error'}');
        return [];
      }
    } catch (e) {
      print('Error fetching favorite TV channels: $e');
      return [];
    }
  }

  // Holt den TV-Kanal-Stream-Link
  // Basierend auf API-Doku: /users/<user_id>/tv-channels/<ch_id>/link
  Future<String?> getTvChannelLink(int channelId) async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) {
        print('No user ID available');
        return null;
      }

      final endpoint = '/api/v2/users/$userId/tv-channels/$channelId/link';
      final response = await get(endpoint);
      
      if (response == null) {
        print('Failed to get TV channel link - null response');
        return null;
      }
      
      if (response.statusCode != 200) {
        print('Failed to get TV channel link: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }

      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] != null) {
        return data['results'];
      } else {
        print('API error: ${data["error"] ?? "Unknown error"}');
        return null;
      }
    } catch (e) {
      print('Error fetching TV channel link: $e');
      return null;
    }
  }

  // Fügt einen Kanal zur Favoritenliste hinzu
  // Basierend auf API-Doku: POST /users/<user_id>/tv-favorites mit ch_id=<channel_id>
  Future<bool> addChannelToFavorites(int channelId) async {
    try {
      final userId = await _storageService.getUserId();
      final token = await _storageService.getAccessToken();
      
      if (userId == null || token == null) {
        print('No user ID or token available');
        return false;
      }

      final endpoint = '/api/v2/users/$userId/tv-favorites';
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'ch_id': channelId.toString(),
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['status'] == 'OK';
      } else {
        print('Failed to add channel to favorites: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error adding channel to favorites: $e');
      return false;
    }
  }

  // Entfernt einen Kanal von der Favoritenliste
  // Basierend auf API-Doku: DELETE /users/<user_id>/tv-favorites/<channel_id>
  Future<bool> removeChannelFromFavorites(int channelId) async {
    try {
      final userId = await _storageService.getUserId();
      final token = await _storageService.getAccessToken();
      
      if (userId == null || token == null) {
        print('No user ID or token available');
        return false;
      }

      final endpoint = '/api/v2/users/$userId/tv-favorites/$channelId';
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        print('Failed to remove channel from favorites: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error removing channel from favorites: $e');
      return false;
    }
  }
  
  // Weitere HTTP-Methoden (POST, PUT, DELETE) können nach Bedarf hinzugefügt werden

  // Holt alle verfügbaren TV-Kategorien/Genres
  Future<List<TvGenre>> getTvGenres() async {
    try {
      // In der API-Dokumentation ist kein spezifischer Endpunkt für Genres dokumentiert,
      // daher verwenden wir einen allgemeinen Endpunkt und extrahieren die Genres aus den Kanälen
      final channels = await getTvChannels();
      
      // Sammle alle eindeutigen genre_ids
      final Map<String, String> genreMap = {};
      for (var channel in channels) {
        if (channel.genreId != null && channel.genreId!.isNotEmpty) {
          // Hier übersetzen wir die Genre-IDs in deutsche Bezeichnungen
          genreMap[channel.genreId!] = _translateGenreName(channel.genreId!);
        }
      }
      
      // Erstelle TvGenre-Objekte
      final genres = genreMap.entries.map((entry) => 
        TvGenre(id: entry.key, title: entry.value)
      ).toList();
      
      // Füge "Alle" als erste Option hinzu
      genres.insert(0, const TvGenre(id: 'all', title: 'Alle Kanäle'));
      
      return genres;
    } catch (e) {
      print('Fehler beim Laden der TV-Kategorien: $e');
      return [const TvGenre(id: 'all', title: 'Alle Kanäle')];
    }
  }

  // Übersetzt Genre-IDs in deutsche Namen
  String _translateGenreName(String genreId) {
    // Mapping von Genre-IDs zu deutschen Namen
    final Map<String, String> genreTranslations = {
      'news': 'Nachrichten',
      'sport': 'Sport',
      'sports': 'Sport',
      'movie': 'Filme',
      'series': 'Serien',
      'children': 'Kinder',
      'childrens': 'Kinder',
      'music': 'Musik',
      'documentary': 'Dokumentation',
      'comedy': 'Komödie',
      'entertainment': 'Unterhaltung',
      'entertainments': 'Unterhaltung',
      'info': 'Information',
      'information': 'Information',
      'cinema': 'Filme',
      'science': 'Wissenschaft',
      'education': 'Bildung',
      'business': 'Wirtschaft',
      'fashion': 'Mode',
      'travel': 'Reisen',
      'culture': 'Kultur',
      'adult': 'Erwachsene',
      'shopping': 'Shopping',
      'politics': 'Politik',
      'religion': 'Religion',
      'nature': 'Natur',
      'technology': 'Technologie',
      'hobby': 'Hobby',
      'lifestyle': 'Lifestyle',
      'auto': 'Auto & Motor',
      'health': 'Gesundheit',
      'cooking': 'Kochen',
      'general': 'Allgemein',
    };
    
    // Wenn eine Übersetzung existiert, verwende sie, ansonsten verwende die ID
    return genreTranslations[genreId.toLowerCase()] ?? genreId;
  }
  
  // Holt EPG-Daten (TV-Programm) für einen Kanal
  // Basierend auf API-Doku: /tv-channels/<ch_id>/epg?next=<count>
  Future<List<EpgProgram>> getEpgForChannel(int channelId, {int next = 10}) async {
    try {
      final userId = await _storageService.getUserId();
      if (userId == null) {
        print('No user ID available');
        return [];
      }

      // Laut API-Dokumentation, Abschnitt 3.12 "Ресурс EPG"
      // GET /tv-channels/<ch_id>/epg?next=<count>
      final endpoint = '/api/v2/tv-channels/$channelId/epg?next=$next';
      
      final response = await get(endpoint);
      
      if (response == null) {
        print('Failed to get EPG data - null response');
        return [];
      }
      
      if (response.statusCode != 200) {
        print('Failed to get EPG data: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }

      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] != null) {
        final List<dynamic> programData = data['results'];
        final epgList = programData.map((json) => EpgProgram.fromJson(json)).toList();
        return epgList;
      } else {
        print('API error: ${data["error"] ?? "Unknown error"}');
        return [];
      }
    } catch (e) {
      print('Error fetching EPG data: $e');
      return [];
    }
  }
}
