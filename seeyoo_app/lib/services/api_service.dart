import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:seeyoo_app/models/auth_response.dart';
import 'package:seeyoo_app/models/epg_program.dart';
import 'package:seeyoo_app/models/tv_channel.dart';
import 'package:seeyoo_app/models/tv_genre.dart';
import 'package:seeyoo_app/models/user.dart';
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
    // String deviceMac = '00:00:00:00:00:00'; // Auskommentiert - MAC-Adresse wird nicht mehr verwendet
    String platformType = 'Mobile-App'; // Standardwert
    String serialNumber = '';
    
    try {
      if (Platform.isAndroid) {
        platformType = 'Mobile-App-Android';
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
        serialNumber = androidInfo.serialNumber;
        // MAC-Adresse auf Android auskommentiert
        // deviceMac = androidInfo.id.substring(0, 12).replaceAllMapped(
        //     RegExp(r'(.{2})'), (match) => '${match.group(0)}:').substring(0, 17);
      } else if (Platform.isIOS) {
        platformType = 'Mobile-App-iOS';
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor ?? _uuid.v4();
        serialNumber = iosInfo.utsname.machine;
        // iOS MAC-Adresse auskommentiert
        // deviceMac = deviceId.substring(0, 12).replaceAllMapped(
        //     RegExp(r'(.{2})'), (match) => '${match.group(0)}:').substring(0, 17);
      } else if (kIsWeb) {
        platformType = 'Mobile-App-Web';
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceId = webInfo.userAgent ?? 'web-browser';
        serialNumber = webInfo.browserName?.toString() ?? 'unknown';
        // Pseudo-MAC für Web auskommentiert
        // deviceMac = _uuid.v4().substring(0, 12).replaceAllMapped(
        //     RegExp(r'(.{2})'), (match) => '${match.group(0)}:').substring(0, 17);
      }
    } catch (e) {
      print('Error getting device info: $e');
      // Fallback auf UUID für die Geräteidentifikation
      final uuid = _uuid.v4();
      deviceId = 'seeyoo-app-$uuid';
      serialNumber = uuid;
      // Fallback MAC-Adresse auskommentiert
      // deviceMac = uuid.substring(0, 12).replaceAllMapped(
      //     RegExp(r'(.{2})'), (match) => '${match.group(0)}:').substring(0, 17);
    }
    
    return {
      'device_id': deviceId,
      'mac': platformType, // Statt MAC-Adresse geben wir nun die Plattform-Identifikation zurück
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
        'mac': deviceInfo['mac'] ?? 'Mobile-App', // Nutze die Plattform-Identifikation statt einer MAC-Adresse
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
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
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
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
            'Expires': '0',
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
  

  // Holt die Benutzerinformationen von der API
  // Erstellt einen neuen Benutzer im Billing-System
  // Basierend auf dem Beispiel: POST http://bill.seeyoo.tv/api/users
  Future<Map<String, dynamic>?> createUser({
    required String name,
    String? secondName,
    required String email,
    required String tariff,
    required String password,
    String? phone,
    String? address,
    String? city,
    String? country,
    bool isTest = false,
  }) async {
    try {
      // Billing-API URL und Endpunkt
      const String billingBaseUrl = 'http://bill.seeyoo.tv';
      final endpoint = '/api/users';
      final url = Uri.parse('$billingBaseUrl$endpoint');
      
      print('### createUser: Calling API URL: $url');
      
      // Basic Auth für die Billing-API
      const String authHeader = 'Basic YmlsbGluZzpMam5iR0NGdHlyZCY2dDk4IyQ5XzBpMFk4N3RlNXJ0ODY3dDd5';
      
      // Erstellen der Form-Daten für die POST-Anfrage
      final Map<String, String> formData = {
        'name': name,
        'email': email,
        'tariff': tariff,       // Pflichtparameter direkt einfügen
        'password': password,   // Pflichtparameter direkt einfügen
        'test': isTest ? '1' : '0',
      };
      
      
      // Optionale Parameter hinzufügen
      if (secondName != null) formData['second_name'] = secondName;
      
      print('### createUser: Form data: $formData');
      
      // POST-Anfrage durchführen
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Authorization': authHeader,
        },
        body: formData,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        print('### createUser: Request timed out after 15 seconds');
        throw TimeoutException('Request timed out');
      });
      
      print('### createUser: Response status code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('### createUser: Failed to create user: ${response.statusCode}');
        print('### createUser: Response body: ${response.body}');
        return null;
      }
      
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] != null) {
        print('### createUser: User created successfully');
        print('### createUser: User ID: ${data['results']['id']}');
        return data['results'];
      } else {
        print('### createUser: API error: ${data["error"] ?? "Unknown error"}');
        return null;
      }
    } catch (e, stackTrace) {
      print('### createUser: Error creating user: $e');
      print('### createUser: Stack trace: $stackTrace');
      return null;
    }
  }

  // Aktualisiert die Benutzerinformationen im Billing-System
  // Basierend auf dem Beispiel: PUT http://bill.seeyoo.tv/api/users/{email}
  Future<bool> updateUserInfo({
    required String email,
    String? name,
    String? secondName,
    String? password,
    String? country,
    String? city,
    String? address,
    String? phone,
  }) async {
    try {
      // Billing-API URL und Endpunkt mit E-Mail als Identifikator
      const String billingBaseUrl = 'http://bill.seeyoo.tv';
      final endpoint = '/api/users/$email';
      final url = Uri.parse('$billingBaseUrl$endpoint');
      
      print('### updateUserInfo: Calling API URL: $url');
      
      // Basic Auth für die Billing-API
      const String authHeader = 'Basic YmlsbGluZzpMam5iR0NGdHlyZCY2dDk4IyQ5XzBpMFk4N3RlNXJ0ODY3dDd5';
      
      // Erstellen der Form-Daten für die PUT-Anfrage
      final Map<String, String> formData = {};
      
      // Nur Parameter hinzufügen, die nicht null sind
      if (name != null) formData['name'] = name;
      if (secondName != null) formData['second_name'] = secondName;
      if (password != null) formData['password'] = password;
      if (country != null) formData['country'] = country;
      if (city != null) formData['city'] = city;
      if (address != null) formData['address'] = address;
      if (phone != null) formData['phone'] = phone;
      
      
      // E-Mail ist sowohl Teil der URL als auch der Formulardaten
      formData['email'] = email;
      
      print('### updateUserInfo: Form data: $formData');
      
      // PUT-Anfrage durchführen
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Authorization': authHeader,
        },
        body: formData,
      ).timeout(const Duration(seconds: 15), onTimeout: () {
        print('### updateUserInfo: Request timed out after 15 seconds');
        throw TimeoutException('Request timed out');
      });
      
      print('### updateUserInfo: Response status code: ${response.statusCode}');
      
      if (response.statusCode != 200) {
        print('### updateUserInfo: Failed to update user info: ${response.statusCode}');
        print('### updateUserInfo: Response body: ${response.body}');
        return false;
      }
      
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] == true) {
        print('### updateUserInfo: User data updated successfully');
        
        // Nach erfolgreicher Aktualisierung frische Benutzerdaten abrufen
        final updatedUser = await getUserInfo();
        if (updatedUser != null) {
          print('### updateUserInfo: Retrieved updated user data');
        }
        
        return true;
      } else {
        print('### updateUserInfo: API error: ${data["error"] ?? "Unknown error"}');
        return false;
      }
    } catch (e, stackTrace) {
      print('### updateUserInfo: Error updating user info: $e');
      print('### updateUserInfo: Stack trace: $stackTrace');
      return false;
    }
  }

  // Suche nach Benutzern in der Billing-API anhand der E-Mail-Adresse
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      print('### findUserByEmail: Searching for user with email: $email');
      
      // Billing-API URL und Endpunkt - wir probieren verschiedene Ansätze
      const String billingBaseUrl = 'http://bill.seeyoo.tv';
      
      // Versuch 1: Direkte Abfrage nach E-Mail als Parameter
      final endpoint = '/api/users';
      final uri = Uri.parse('$billingBaseUrl$endpoint')
          .replace(queryParameters: {'email': email});
      
      print('### findUserByEmail: Calling API URL: $uri');
      
      // Basic Auth für die Billing-API
      const String authHeader = 'Basic YmlsbGluZzpMam5iR0NGdHlyZCY2dDk4IyQ5XzBpMFk4N3RlNXJ0ODY3dDd5';
      
      // GET-Anfrage für die Suche
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': authHeader,
        },
      ).timeout(const Duration(seconds: 15));
      
      print('### findUserByEmail: Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('### findUserByEmail: Response data: $data');
        
        if (data['status'] == 'OK' && data['results'] != null) {
          if (data['results'] is List && data['results'].isNotEmpty) {
            // Ersten gefundenen Benutzer zurückgeben
            final userData = data['results'][0];
            print('### findUserByEmail: Found user with ID: ${userData['id']}');
            return userData;
          } else {
            print('### findUserByEmail: No users found with email: $email');
          }
        } else {
          print('### findUserByEmail: API error: ${data["error"] ?? "Unknown error"}');
        }
      } else {
        print('### findUserByEmail: Failed to search: ${response.statusCode}');
        print('### findUserByEmail: Response body: ${response.body}');
      }
    } catch (e, stackTrace) {
      print('### findUserByEmail: Error searching user: $e');
      print('### findUserByEmail: Stack trace: $stackTrace');
    }
    
    return null;
  }

  Future<User?> getUserInfo() async {
    try {
      int? accountNumber;
      String? macAddress;
      int? userStatus;
      
      // 1. Versuchen, das Benutzerprofil vom Stalker Portal zu bekommen
      final profileData = await getUserProfileFromStalker();
      
      if (profileData != null) {
        // Kontonummer aus dem Profil extrahieren
        if (profileData['account'] != null) {
          accountNumber = int.tryParse(profileData['account'].toString());
          print("### getUserInfo: Found account number in profile: $accountNumber");
        }
        
        // MAC-Adresse aus dem Profil extrahieren, falls vorhanden
        if (profileData['mac'] != null) {
          macAddress = profileData['mac'].toString();
          print("### getUserInfo: Found MAC address in profile: $macAddress");
        }
        
        // Status aus dem Profil extrahieren, falls vorhanden
        if (profileData['status'] != null) {
          userStatus = int.tryParse(profileData['status'].toString());
          print("### getUserInfo: Found user status in profile: $userStatus");
        }
      } else {
        // 2. Wenn kein Profil verfügbar, versuchen, die gespeicherten Daten zu verwenden
        final authUser = await _storageService.getUser();
        accountNumber = authUser?.account;
        print("### getUserInfo: Using stored account number: $accountNumber");
      }
      
      // Wenn wir eine Kontonummer haben, verwenden wir diese für die Billing-API
      if (accountNumber != null) {
        print("### getUserInfo: Querying billing API with account number: $accountNumber");
        // Direkte Abfrage des Benutzers mit seiner Kontonummer (= Billing-ID)
        final userData = await _getBillingUserById(accountNumber);
        
        if (userData != null) {
          // Mapping der Daten auf unser User-Modell
          final user = User(
            id: int.tryParse(userData['id']?.toString() ?? '') ?? 0,
            fname: userData['name']?.toString() ?? '',
            email: userData['email']?.toString() ?? '',
            phone: userData['phone']?.toString() ?? '',
            tariffPlan: userData['tariff']?.toString() ?? '',
            endDate: userData['end_time']?.toString() ?? '',
            accountBalance: double.tryParse(userData['account_balance']?.toString() ?? '0'),
            status: userStatus ?? 1, // Status aus Stalker Portal, Standard: aktiv
            account: int.tryParse(userData['account_number']?.toString() ?? '0'),
            mac: macAddress ?? userData['mac']?.toString() ?? '' // MAC aus Stalker Portal
          );
          
          print("### getUserInfo: User found, saving to storage");
          // Speichern wir den Benutzer lokal
          await _storageService.saveUser(user);
          return user;
        } else {
          print("### getUserInfo: No user found with account number: $accountNumber");
        }
      } else {
        print("### getUserInfo: No user ID found in storage");
      }
      
      // Wenn wir hier ankommen, konnten wir keinen Benutzer finden oder laden
      // Versuchen wir, gespeicherte Benutzerdaten zurückzugeben
      print("### getUserInfo: Falling back to stored user data");
      final storedUser = await _storageService.getUser();
      
      // Wenn es keine gespeicherten Benutzerdaten gibt, erstellen wir einen minimalen Benutzer
      if (storedUser == null) {
        print("### getUserInfo: No stored user data, creating minimal user");
        final email = await _storageService.getUserEmail();
        if (email != null && email.isNotEmpty) {
          final username = email.split('@').first;
          final user = User(
            id: await _storageService.getUserId() ?? 0,
            email: email,
            fname: username,
            status: userStatus ?? 1, // Status aus Stalker Portal verwenden, falls vorhanden
            phone: '',
            tariffPlan: 'Standard',
            endDate: DateTime.now().add(const Duration(days: 30)).toString(),
            accountBalance: null,
            account: null,
            mac: macAddress ?? '', // MAC aus Stalker Portal verwenden, falls vorhanden
          );
          
          // Speichern des minimalen Benutzers
          print("### getUserInfo: Saving minimal user data");
          await _storageService.saveUser(user);
          return user;
        }
      }
      
      return storedUser;
      
    } catch (e, stackTrace) {
      print('### getUserInfo: Error fetching user info from billing API: $e');
      print('### getUserInfo: Stack trace: $stackTrace');
      
      // Bei Ausnahmen versuchen, gespeicherte Daten zu verwenden
      try {
        final storedUser = await _storageService.getUser();
        if (storedUser != null) {
          print('### getUserInfo: Returning stored user data after exception');
          return storedUser;
        }
      } catch (e) {
        print('### getUserInfo: Error retrieving stored user data: $e');
      }
      
      return null;
    }
  }
  
  /// Holt Benutzerinformationen direkt aus dem Billing-System anhand der Benutzer-ID
  Future<Map<String, dynamic>?> _getBillingUserById(int userId) async {
    try {
      final uri = Uri.parse('http://bill.seeyoo.tv/api/users/$userId');
      print("### _getBillingUserById: Calling API URL: ${uri.toString()}");
      
      // Direkte Verwendung der harkodierten Credentials, um den ursprünglichen Zustand wiederherzustellen
      final String basicAuth = 'Basic YmlsbGluZzpMam5iR0NGdHlyZCY2dDk4IyQ5XzBpMFk4N3RlNXJ0ODY3dDd5';
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Authorization': basicAuth,
        },
      );
      
      print("### _getBillingUserById: Response status code: ${response.statusCode}");
      
      // Log den gesamten Antwort-Body
      print("### _getBillingUserById: Response body: ${response.body}");
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          print("### _getBillingUserById: User data found");
          return data['results'];
        } else {
          print("### _getBillingUserById: No user data in results. Status: ${data['status']}");
        }
      } else {
        print("### _getBillingUserById: Failed to get user: ${response.statusCode}");
        print("### _getBillingUserById: Response body: ${response.body}");
      }
      return null;
    } catch (e) {
      print('### _getBillingUserById: Error getting user: $e');
      return null;
    }
  }
  
  // Holt das Benutzerprofil vom Stalker Portal
  Future<Map<String, dynamic>?> getUserProfileFromStalker() async {
    try {
      // Benutzer-ID und Token abrufen
      final userId = await _storageService.getUserId();
      final token = await _storageService.getAccessToken();
      
      if (userId == null || token == null) {
        print('### getUserProfileFromStalker: Missing userId or token');
        return null;
      }
      
      // Anfrage an den Stalker Portal API-Endpunkt für Benutzerinformationen
      final uri = Uri.parse('$baseUrl/api/v2/users/$userId');
      print('### getUserProfileFromStalker: Request to $uri');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      print('### getUserProfileFromStalker: Status ${response.statusCode}');
      print('### getUserProfileFromStalker: Body ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['results'] != null) {
          print('### getUserProfileFromStalker: Account number: ${data['results']['account']}');
          return data['results'];
        }
      }
      
      return null;
    } catch (e) {
      print('### getUserProfileFromStalker: Error $e');
      return null;
    }
  }
  
  // Holt die Benutzereinstellungen von der API
  Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final userId = await _storageService.getUserId();
      
      if (userId == null) {
        print('No user ID available');
        return null;
      }
      
      final endpoint = '/api/v2/users/$userId/settings';
      
      final response = await get(endpoint);
      
      if (response == null) {
        print('Failed to get user settings - null response');
        return null;
      }
      
      if (response.statusCode != 200) {
        print('Failed to get user settings: ${response.statusCode}');
        print('Response body: ${response.body}');
        return null;
      }
      
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] != null) {
        final settingsData = data['results'];
        
        // Lokale Einstellungen abrufen, um sie zu bewahren
        final localSettings = await _storageService.getUserSettings();
        
        // Lokale Sandbox-Einstellungen beibehalten
        if (localSettings != null) {
          // Bitrate-Einstellungen aus lokalen Daten beibehalten
          if (localSettings.containsKey('mobile_quality')) {
            settingsData['mobile_quality'] = localSettings['mobile_quality'];
          }
          if (localSettings.containsKey('wifi_quality')) {
            settingsData['wifi_quality'] = localSettings['wifi_quality'];
          }
          
          // Starteinstellung TV-Favoriten bewahren
          if (localSettings.containsKey('start_with_favorites')) {
            settingsData['start_with_favorites'] = localSettings['start_with_favorites'];
          }
          
          // Kindersicherung beibehalten
          if (localSettings.containsKey('parental_control_enabled')) {
            settingsData['parental_control_enabled'] = localSettings['parental_control_enabled'];
          }
          if (localSettings.containsKey('parent_password')) {
            settingsData['parent_password'] = localSettings['parent_password'];
          }
        }
        
        // Aktualisierte Einstellungen im Speicher aktualisieren
        await _storageService.saveUserSettings(settingsData);
        
        return settingsData;
      } else {
        print('API error: ${data["error"] ?? "Unknown error"}');
        return null;
      }
    } catch (e) {
      print('Error fetching user settings: $e');
      return null;
    }
  }
  
  // Aktualisiert die Benutzereinstellungen
  Future<bool> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final userId = await _storageService.getUserId();
      
      if (userId == null) {
        print('No user ID available');
        return false;
      }
      
      final endpoint = '/api/v2/users/$userId/settings';
      
      final uri = Uri.parse('$baseUrl$endpoint');
      final token = await _storageService.getAccessToken();
      
      if (token == null) {
        print('No access token available');
        return false;
      }
      
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(settings),
      );
      
      if (response.statusCode != 200) {
        print('Failed to update user settings: ${response.statusCode}');
        print('Response body: ${response.body}');
        return false;
      }
      
      // Aktualisierte Einstellungen im Speicher aktualisieren
      final updatedSettings = await getUserSettings();
      if (updatedSettings != null) {
        await _storageService.saveUserSettings(updatedSettings);
      }
      
      return true;
    } catch (e) {
      print('Error updating user settings: $e');
      return false;
    }
  }

  // Ruft den Ping-Endpunkt auf, um das Gerät als online zu markieren
  Future<bool> pingServer() async {
    try {
      final userId = await _storageService.getUserId();
      
      if (userId == null) {
        print('No user ID available for ping');
        return false;
      }
      
      final endpoint = '/api/v2/users/$userId/ping';
      
      final response = await get(endpoint);
      
      return response?.statusCode == 200;
    } catch (e) {
      print('Error pinging server: $e');
      return false;
    }
  }
  
  // Aktualisiert die Media-Info für aktuell abgespielten Content
  Future<bool> updateMediaInfo({required String type, required int mediaId}) async {
    try {
      final userId = await _storageService.getUserId();
      
      if (userId == null) {
        print('No user ID available');
        return false;
      }
      
      // Endpunkt /users/<user_id>/media-info
      final endpoint = '/api/v2/users/$userId/media-info';
      print('Sende Media-Info Update zu: $baseUrl$endpoint');
      print('Params: type=$type, media_id=$mediaId');
      
      final uri = Uri.parse('$baseUrl$endpoint');
      final token = await _storageService.getAccessToken();
      
      if (token == null) {
        print('No access token available');
        return false;
      }
      
      final body = {
        'type': type, // z.B. 'tv-channel', 'video', etc.
        'media_id': mediaId,
      };
      
      // Formatieren wie im erfolgreichen curl-Befehl
      // Hier als Map mit separaten Key-Value-Paaren
      final Map<String, String> formData = {
        'type': type,
        'media_id': mediaId.toString(),
      };
      
      print('Exakte Form-Daten: $formData');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',  // Wichtig: Accept-Header hinzugefügt
        },
        body: formData, // Dart http wandelt Map automatisch in Form-Daten um
      );
      
      // Debug: Server-Antwort ausgeben
      print('Media-Info Update Antwort Status: ${response.statusCode}');
      print('Media-Info Update Antwort Body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating media info: $e');
      return false;
    }
  }
  
  // Entfernt die Media-Info (beim Stoppen der Wiedergabe)
  Future<bool> removeMediaInfo() async {
    try {
      final userId = await _storageService.getUserId();
      
      if (userId == null) {
        print('No user ID available');
        return false;
      }
      
      final endpoint = '/api/v2/users/$userId/media-info';
      print('Entferne Media-Info: $baseUrl$endpoint');
      
      final uri = Uri.parse('$baseUrl$endpoint');
      final token = await _storageService.getAccessToken();
      
      if (token == null) {
        print('No access token available');
        return false;
      }
      
      final response = await http.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json', // Wichtig: Accept-Header hinzugefügt wie bei updateMediaInfo
        },
      );
      
      // Debug: Server-Antwort ausgeben
      print('Media-Info Entfernen Antwort Status: ${response.statusCode}');
      print('Media-Info Entfernen Antwort Body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error removing media info: $e');
      return false;
    }
  }

  // Speichert den zuletzt gesehenen Kanal auf dem Server
  Future<bool> saveLastWatchedChannel(int channelId) async {
    try {
      final userId = await _storageService.getUserId();
      final token = await _storageService.getAccessToken();
      
      if (userId == null || token == null) {
        print('No user ID or access token available');
        return false;
      }
      
      final endpoint = '/api/v2/users/$userId/tv-channels/last';
      final uri = Uri.parse('$baseUrl$endpoint');
      
      print('Speichere letzten Kanal: $channelId');
      
      final response = await http.put(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'ch_id': channelId.toString(),
        },
      );
      
      print('Speichern des letzten Kanals - Status: ${response.statusCode}, Body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      print('Fehler beim Speichern des letzten Kanals: $e');
      return false;
    }
  }
  
  // Ruft den zuletzt gesehenen Kanal vom Server ab
  Future<int?> getLastWatchedChannel() async {
    try {
      final userId = await _storageService.getUserId();
      final token = await _storageService.getAccessToken();
      
      if (userId == null || token == null) {
        print('No user ID or access token available');
        return null;
      }
      
      final endpoint = '/api/v2/users/$userId/tv-channels/last';
      final uri = Uri.parse('$baseUrl$endpoint');
      
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      
      print('Abrufen des letzten Kanals - Status: ${response.statusCode}, Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' && data['results'] != null) {
          return int.tryParse(data['results'].toString());
        }
      }
      
      return null;
    } catch (e) {
      print('Fehler beim Abrufen des letzten Kanals: $e');
      return null;
    }
  }

  // Abrufen der verfügbaren Module
  Future<List<String>> getAvailableModules() async {
    try {
      final userId = await _storageService.getUserId();
      
      if (userId == null) {
        print('No user ID available');
        return [];
      }
      
      final endpoint = '/api/v2/users/$userId/modules';
      
      final response = await get(endpoint);
      
      if (response == null) {
        print('Failed to get available modules - null response');
        return [];
      }
      
      if (response.statusCode != 200) {
        print('Failed to get available modules: ${response.statusCode}');
        print('Response body: ${response.body}');
        return [];
      }
      
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK' && data['results'] != null) {
        final List<dynamic> modulesList = data['results'];
        return modulesList.map((module) => module.toString()).toList();
      } else {
        print('API error: ${data["error"] ?? "Unknown error"}');
        return [];
      }
    } catch (e) {
      print('Error fetching available modules: $e');
      return [];
    }
  }

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
  
  // Aktualisiert die Reihenfolge der Favoriten-Kanäle
  // PUT /users/<user_id>/tv-favorites mit ch_id=1,2,3,...
  Future<bool> updateFavoritesOrder(List<int> channelIds) async {
    try {
      final userId = await _storageService.getUserId();
      final token = await _storageService.getAccessToken();
      
      if (userId == null || token == null) {
        print('No user ID or token available');
        return false;
      }

      // Erstelle kommagetrennte Liste der Kanal-IDs
      final String channelIdsParam = channelIds.join(',');
      
      // Verwende den gleichen Endpunkt wie bei addChannelToFavorites
      final endpoint = '/api/v2/users/$userId/tv-favorites';
      
      // PUT-Anfrage mit den gleichen Headern wie bei addChannelToFavorites
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: 'ch_id=$channelIdsParam',  // Korrekt formatierter URL-encoded String
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Successfully updated favorites order');
        print('Request sent with ch_id=$channelIdsParam');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
        return true;
      } else {
        print('Failed to update favorites order: ${response.statusCode}');
        print('Request sent with ch_id=$channelIdsParam');
        print('Response headers: ${response.headers}');
        print('Response body: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error updating favorites order: $e');
      return false;
    }
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
